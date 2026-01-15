# Short-Track: A Cloud-Native URL Shortener & Analytics Platform

## Overview

Short-Track is a high-performance, multi-tier URL shortener application built on modern cloud-native principles. It serves as a comprehensive portfolio project demonstrating a wide range of skills in microservice architecture, containerization, asynchronous processing, and data visualization.

At its core, it's a simple tool: give it a long URL, and it gives you a short one back. However, its architecture is designed for scalability, resilience, and observability, making it an excellent showcase of DevOps best practices.

### Key Features & Benefits

*   **Microservice Architecture:** The application is broken down into decoupled, single-responsibility services (API, Analytics Worker), making it easy to develop, scale, and maintain each part independently.
*   **Asynchronous Processing:** By using RabbitMQ as a message queue, click-tracking is handled in the background. This ensures the user redirect is instantaneous and not blocked by analytics processing, enabling high throughput.
*   **Persistent & Fast:** URL data is stored permanently in a PostgreSQL database, while a Redis cache provides a low-latency lookup layer to ensure the fastest possible redirect speeds for frequently accessed links.
*   **Containerized & Portable:** The entire application stack is containerized with Docker and orchestrated via a single Docker Compose file, ensuring it runs consistently in any environment and is ready for cloud deployment.
*   **Configuration as Code:** Key application and infrastructure settings are managed via configuration files, including Docker Compose environment variables and Grafana's provisioning engine, which is a core tenet of GitOps and IaC.
*   **Resilient Builds:** The Go services utilize vendored dependencies, creating a hermetic build process that is immune to network failures and ensures consistency.

## Architecture

The application follows a distributed, multi-tier architecture. The data flows through two primary paths: the user-facing shortening/redirect path and the internal analytics path.

```
                                                              +-----------------+
                                                          +-->|     Redis     |
                                                          |   |    (Cache)    |
                                                          |   +---------------+
                                                          |
+----------+      +----------------+      +---------------+   +-----------------+
|          |      |                |      |               |-->|   PostgreSQL  |
|   User   |----->| Frontend (Nginx)|----->|  API Service  |   |   (Storage)   |
|          |      |                |      |     (Go)      |   +---------------+
+----------+      +----------------+      +---------------+
   ^      |                                       |
   |      |                                       | (Publish Event)
   |      |                                       v
   |      +----------------------------------+    +-----------------+
   |         (Redirect)                      |    |    RabbitMQ     |
   +-----------------------------------------+    | (Message Queue) |
                                                  +-------+---------+
                                                          |
                                                          | (Consume Event)
                                                          v
                                                  +-------+---------+   +-----------------+
                                                  | Analytics Worker|-->|   PostgreSQL  |
                                                  |      (Go)       |   | (Click Events)|
                                                  +-----------------+   +-------+---------+
                                                                                  ^
                                                                                  |
                                                                          +-------+---------+
                                                                          |     Grafana     |
                                                                          |   (Dashboard)   |
                                                                          +-----------------+
```

## Technology Stack

*   **Backend:** Go
*   **Frontend:** HTML, JavaScript
*   **Web Server:** Nginx
*   **Database:** PostgreSQL
*   **Cache:** Redis
*   **Message Queue:** RabbitMQ
*   **Dashboarding:** Grafana
*   **Containerization:** Docker, Docker Compose

## Getting Started

### Prerequisites

*   Docker
*   Docker Compose

### How to Run

1.  Clone this repository to your local machine.
2.  Navigate to the project's root directory (`short-track/`).
3.  Run the following command to build and start all services:
    ```bash
    docker-compose up --build
    ```
4.  The application is now running. You can access the different services:
    *   **Web Frontend:** `http://localhost:8081`
    *   **API Endpoint:** `http://localhost:8088`
    *   **Grafana Dashboard:** `http://localhost:3000` (Login: `admin` / `admin`)
    *   **RabbitMQ Management:** `http://localhost:15672` (Login: `guest` / `guest`)

## Project Deep Dive: Key Concepts

This project was built to demonstrate several important DevOps concepts.

### Go Modules & Vendoring for Resilient Builds

**What is it?**
Go has a built-in dependency management system called Go Modules. Typically, during a build, Go downloads dependencies from the internet (e.g., `proxy.golang.org`, GitHub). The `go mod vendor` command changes this by downloading all dependencies into a `vendor/` directory within the project itself.

**Benefit & How We Used It:**
During this project, we encountered network errors within the Docker build environment. The build container could not reach the internet to download dependencies, causing the build to fail.

By running `go mod vendor` on our host machine and then changing our `Dockerfile` to use the vendored dependencies, we solved this problem entirely.

The `Dockerfile` command was changed from `RUN go mod download` to:
```dockerfile
# Copy the pre-downloaded dependencies
COPY vendor ./vendor
# Build using only the files we have, no network needed
RUN go build -mod=vendor -o /app/main .
```
This creates a **hermetic build**—a build that is self-contained and does not require network access, making it significantly more reliable and reproducible.

### Configuration via Environment Variables

**What is it?**
Hardcoding configuration like database passwords or hostnames into an application is inflexible and insecure. We externalized all such configuration using environment variables, which are passed to the services from the `docker-compose.yml` file.

**Benefit & How We Used It:**
In `docker-compose.yml`, we used a YAML anchor (`&common-env`) to define a common set of environment variables and then reused it for both the `api` and `analytics-worker` services. This keeps our configuration DRY (Don't Repeat Yourself).

```yaml
services:
  api:
    environment: &common-env
      POSTGRES_HOST: postgres
      # ... other vars
  analytics-worker:
    environment:
      <<: *common-env
```

The Go applications then read this configuration at runtime using `os.Getenv("POSTGRES_HOST")`. This practice allows the same container image to be deployed in different environments (dev, staging, production) with different configurations without any code changes.

### Verifying Raw Data with `psql`

**What is it?**
Before building complex dashboards, it's crucial to verify that the data is being correctly saved at the source. We can do this by connecting directly to the database running inside its container.

**Procedure:**
The `docker exec` command allows you to run a command inside a running container. We use it to open the `psql` command-line tool within our `postgres` container.

1.  **Execute the command:** Run the following in your terminal.
    ```bash
    docker exec -it <your_container_name> psql -U <your_username>
    ```
    *   For this project, the command is: `docker exec -it short-track_postgres_1 psql -U shorttrack`
    *   **`<your_container_name>`:** This is the name of the running container. You can find it by running `docker ps`. Docker Compose typically names it `<project>_<service>_1`.
    *   **`<your_username>`:** The user for the database connection, which we defined as `shorttrack`.

2.  **Run a Query:** Once you are at the `shorttrack=#` prompt, you can run any SQL query.
    ```sql
    SELECT * FROM clicks ORDER BY clicked_at DESC;
    ```

3.  **Exit:** Type `\q` and press Enter to exit `psql`.

**External Client Connection String:**
You can also connect using a graphical database client with the following connection string (password will be prompted):
```
postgresql://shorttrack@localhost:5432/shorttrack
```

## Future Work

*   **Infrastructure as Code (IaC):** Use Terraform to provision a Kubernetes cluster and managed database services in a cloud provider (AWS, GCP, Azure).
*   **Kubernetes Deployment:** Convert the Docker Compose services into Kubernetes manifests (Deployments, Services, Ingress) and deploy the application.
*   **CI/CD Pipeline:** Create a GitHub Actions workflow to automatically build, test, and deploy the application to Kubernetes on every `git push`.
