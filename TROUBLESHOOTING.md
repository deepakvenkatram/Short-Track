# Grafana Dashboard Troubleshooting Guide

## Problem: Dashboard Shows "NO DATA"

This guide outlines the systematic process for diagnosing why a Grafana dashboard panel might show "NO DATA", even when the underlying data source is receiving data. The context is the "Short-Track" application, where click events are sent through a pipeline and stored in PostgreSQL for visualization in Grafana.

### Understanding the Data Flow

To debug effectively, it's crucial to understand the path the data takes:

`User Click` -> `API Service` -> `RabbitMQ` -> `Analytics Worker` -> `PostgreSQL` -> `Grafana`

A failure at any point in this chain will result in an empty dashboard. We will test each link in this chain systematically.

---

### Step 1: Check the Analytics Worker Logs

**Purpose:** To verify that the first half of the pipeline is working (API -> RabbitMQ -> Worker). The worker's logs will tell us if it's receiving messages.

**Procedure:**
Run the following command from the project's root directory (`short-track/`) to view the logs of the `analytics-worker` container.

```bash
docker-compose logs analytics-worker
```

**What to Look For:**
You should see lines indicating that messages are being received and processed.

```
# Expected Output Example
...
analytics-worker-1  |  [*] Waiting for messages. To exit press CTRL+C
analytics-worker-1  | Received a message: {"short_url":"NGbKFN","timestamp":"2026-01-15T05:38:25Z"}
analytics-worker-1  | Successfully recorded click for NGbKFN
...
```

**Conclusion:**
*   **If you see these logs:** The problem is *after* the worker (in PostgreSQL or Grafana). Proceed to Step 2.
*   **If you do not see these logs:** The problem is earlier. Check the logs of the `api-service` and the RabbitMQ Management UI (`http://localhost:15672`) to see if messages are being published correctly.

### Step 2: Verify Data in the Database

**Purpose:** To confirm that the worker successfully saved the data to the PostgreSQL database.

**Procedure:**
We will execute the `psql` command-line tool directly inside the running `postgres` container to query the `clicks` table.

```bash
docker exec -it <your_postgres_container_name> psql -U <your_username>
```
*   For this project, the command is: `docker exec -it short-track_postgres_1 psql -U shorttrack`
*   **`<your_postgres_container_name>`:** The name of the running container, typically found via `docker ps`.
*   **`<your_username>`:** The database user, which is `shorttrack`.

Once at the `shorttrack=#` prompt, run the following query:

```sql
SELECT * FROM clicks LIMIT 10;
```

**What to Look For:**
A table of rows containing click data.

**Conclusion:**
*   **If data is present:** The entire data pipeline up to the database is working perfectly. The problem is isolated to Grafana. Proceed to Step 3.
*   **If the table is empty:** The worker's log message "Successfully recorded click" is misleading. There is likely an error in the database insertion logic or configuration.

### Step 3: Test the Grafana Datasource Connection

**Purpose:** To confirm that the Grafana container can network and authenticate with the PostgreSQL container.

**Procedure:**
1.  Open the Grafana UI at `http://localhost:3000`.
2.  Navigate to **Configuration (⚙️ icon) > Data Sources**.
3.  Click on the **`PostgreSQL-ShortTrack`** datasource.
4.  Scroll to the bottom and click the green **Test** button.

**What to Look For:**
A green banner with the message "Connection OK".

**Conclusion:**
*   **If the test is successful:** The problem is not connectivity; it's how Grafana is querying or interpreting the data. Proceed to Step 4.
*   **If the test fails:** The error message will tell you why (e.g., incorrect password, network issue). Check the `datasource.yml` file and the Docker network.

### Step 4: Isolate the Panel with a Simple Query

**Purpose:** To determine if the issue is with all queries or specifically with time-series queries and Grafana's macros.

**Procedure:**
1.  On your dashboard, create a **new panel** ("Add" -> "Visualization").
2.  Select the `PostgreSQL-ShortTrack` datasource.
3.  On the right-hand side, change the visualization type from "Time series" to **"Table"**.
4.  In the query editor, switch to **"Code"** mode and enter the following simple query:
    ```sql
    SELECT * FROM clicks ORDER BY clicked_at DESC LIMIT 10;
    ```

**What to Look For:**
A table of data appearing in the panel.

**Conclusion:**
*   **If the table appears:** This is the key result. It proves Grafana can query and display data, but the issue is specific to the **Time Series** visualization and its query format. Proceed to Step 5.
*   **If the table is also empty:** This indicates a very strange bug within Grafana itself, as all other components have been proven to work.

### Step 5: The Solution - Use a Native SQL Query

**Diagnosis:**
The previous steps lead us to conclude that there is an incompatibility or bug in the installed Grafana version related to its time-series macros (e.g., `$__timeFilter`).

**The Fix:**
We replace the macro-based query with a native PostgreSQL query that does not rely on Grafana's special variables. This query is less dynamic but more reliable in this situation.

Update the time-series panel's query to the following:
```sql
SELECT
  date_trunc('minute', clicked_at) AS time,
  count(*) AS "clicks"
FROM clicks
WHERE
  clicked_at > NOW() - INTERVAL '6 hours'
GROUP BY time
ORDER BY time
```

### Step 6: Apply the Fix Permanently

**Purpose:** To save the working query so the dashboard is fixed permanently.

**Procedure:**
1.  Update the `rawSql` field in the provisioned dashboard file: `short-track/grafana/provisioning/dashboards/main-dashboard.json` with the working query from Step 5.
2.  Restart the Grafana container to force it to reload the updated JSON file.
    ```bash
    docker-compose restart grafana
    ```

After the restart, the dashboard will load correctly every time.
