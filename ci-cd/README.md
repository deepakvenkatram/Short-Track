# CI/CD Environment Setup with Jenkins & Docker

## 1. Overview

This directory contains all the necessary files to build and run a local, containerized Jenkins CI/CD environment for the "Short-Track" project.

The setup is designed around modern "as-code" principles to ensure it is automated, repeatable, and version-controlled.

*   **Jenkins as Code:** The Jenkins controller is automatically configured on startup using the `jenkins.casc.yml` file (JCasC - Jenkins Configuration as Code). This defines our connection to the custom build agent.
*   **Custom Docker Agents:** Pipeline jobs do not run on the Jenkins controller. Instead, they run on a custom-defined agent (`Dockerfile`) that comes pre-installed with all the tools needed for our pipeline (Go, Docker, Ansible, Gitleaks). This is much more efficient and scalable than installing tools during a pipeline run.
*   **Docker Compose Orchestration:** The entire environment (controller and agent) is managed by a single `docker-compose.yml` file for easy startup and teardown.

## 2. File Structure

*   `docker-compose.yml`: The master file that defines and links the `jenkins-controller` and `jenkins-agent` services.
*   `Dockerfile`: Defines the custom build agent container image. All pipeline stages will run inside a container created from this image.
*   `Dockerfile-controller`: A simple Dockerfile that customizes the official Jenkins image to install a specific list of plugins.
*   `plugins.txt`: A list of Jenkins plugins that will be automatically installed on the controller at startup.
*   `jenkins.casc.yml`: The JCasC file that automatically configures the Jenkins controller, telling it how to use our custom agent.

## 3. Step-by-Step Setup Instructions

### Prerequisites
*   Docker
*   Docker Compose

### Step 1: Build and Run the Jenkins Environment

Navigate to the `short-track/ci-cd/` directory in your terminal and run the following command:

```bash
docker-compose up --build
```

**Note:** The first time you run this command, it will take several minutes. It needs to:
1.  Build the custom Docker image for the controller.
2.  Build the custom Docker image for the agent (which involves downloading Go, Docker, Ansible, etc.).
3.  Download the Jenkins controller and all the plugins listed in `plugins.txt`.

Subsequent startups will be much faster.

### Step 2: Get the Initial Admin Password

Jenkins secures its initial setup with a generated password that it prints to the logs.

1.  Wait for the logs to show that Jenkins is up and running.
2.  Open a **new terminal window**.
3.  Run the following command from the `short-track/ci-cd/` directory to view the logs:
    ```bash
    docker-compose logs jenkins-controller
    ```
4.  Look for a block of text surrounded by asterisks. Copy the password from inside this block.

    ```
    *************************************************************
    *************************************************************
    *************************************************************

    Jenkins initial setup is required. An admin user has been created and a password generated.
    Please use the following password to proceed to installation:

    THIS_IS_THE_ADMIN_PASSWORD

    *************************************************************
    *************************************************************
    *************************************************************
    ```

### Step 3: Complete the Jenkins Setup Wizard

1.  Open your web browser and navigate to **`http://localhost:8080`**.
2.  Paste the administrator password you copied from the logs and click "Continue".
3.  On the "Customize Jenkins" screen, it will ask you to install plugins. **You can skip this.** We have already installed all the necessary plugins using our `plugins.txt` file. Simply click the 'x' on the "Install suggested plugins" box.
4.  Create your own admin user account and click "Save and Finish".
5.  On the "Instance Configuration" page, confirm the Jenkins URL and click "Save and Finish".
6.  Click "Start using Jenkins".

## 4. Running Your First Pipeline

Your Jenkins environment is now fully configured. The final step is to create a Pipeline job in Jenkins that points to our project's repository. Jenkins will then read the `Jenkinsfile` in the root of the repository and execute the stages we defined.

### Step 1: Create the Pipeline Job

1.  **Go to Your Jenkins Dashboard:** `http://localhost:8080`
2.  **Create a New Job:**
    *   On the left sidebar, click **New Item**.
    *   Enter an item name (e.g., `short-track-pipeline`).
    *   Select **Pipeline** from the options and click **OK**.
3.  **Configure the Pipeline:**
    *   Scroll down to the **Pipeline** section on the configuration page.
    *   Change the **Definition** dropdown to **Pipeline script from SCM**.
    *   In the **SCM** dropdown that appears, select **Git**.
    *   In the **Repository URL** field, enter the path to your project's Git repository (e.g., `https://github.com/your-username/short-track.git`).
    *   Ensure the **Script Path** field is set to `Jenkinsfile`.
4.  **Save:** Click **Save**.

### Step 2: Showcase the Gitleaks Security Scan (Expected Failure)

This is a key demonstration for your portfolio. We will run the pipeline knowing it will fail, proving our security scan works.

1.  On the job's page, click **Build Now** on the left sidebar.
2.  The pipeline will start. You can watch its progress in the "Build History" or by clicking **Open Blue Ocean**.
3.  The pipeline will execute the initial stages and then **FAIL** at the **"Security: Secret Scanning"** stage. This is the **correct and desired behavior**.
4.  Click into the failed stage's logs. You will see output from Gitleaks indicating it found hardcoded credentials (the `amqp://guest:guest...` string in our Go code).

This demonstrates that your CI pipeline is successfully acting as a security gate, preventing code with leaked secrets from being built.

### Step 3: Make the Build Pass

To demonstrate the rest of the pipeline, we need to temporarily "fix" the security issue.

1.  **Comment out the secret:**
    *   In `services/api-service/main.go`, find the line with `amqp://guest:guest...` and comment it out.
    *   In `services/analytics-worker/main.go`, do the same.
2.  **Commit the change:** Commit this change to your Git repository.
3.  **Re-run the build:** Go back to the Jenkins job page and click **Build Now** again.

This time, the "Security: Secret Scanning" stage will pass, and the pipeline will continue to the subsequent stages for testing, code coverage analysis, and building the Docker images.

## 5. Enabling Continuous Deployment to Kubernetes

The `Jenkinsfile` includes a final stage named **"Deploy to Kubernetes"**. To enable this stage, you must provide Jenkins with the credentials to access your Kubernetes cluster.

This is done by uploading your `kubeconfig` file as a secret in Jenkins.

### Step 1: Add Your `kubeconfig` as a Jenkins Secret

1.  **Locate your `kubeconfig` file.** It is typically found at `~/.kube/config` on your local machine.

2.  **Navigate to Jenkins Credentials:**
    *   Go to your Jenkins dashboard (`http://localhost:8080`).
    *   On the left sidebar, click **Manage Jenkins**.
    *   In the "Security" section, click **Credentials**.

3.  **Add a New Credential:**
    *   Click on the **(global)** domain.
    *   On the left, click **Add Credentials**.

4.  **Create the "Secret file" credential:**
    *   **Kind:** Select **Secret file**.
    *   **File:** Click the "Choose File" button and select your `kubeconfig` file from your computer.
    *   **ID:** Enter `kubeconfig`. This ID is case-sensitive and **must match exactly** what is in the `Jenkinsfile`.
    *   **Description:** (Optional) Add a description, like "Kubernetes cluster access config".
    *   Click **Create**.

### Step 2: Run the Full CI/CD Pipeline

With the `kubeconfig` credential in place, you can now run the full pipeline.

1.  Make sure you have already pushed your custom application images to a container registry and updated the `image:` tags in the `k8s/*.yml` files as described in the `KUBERNETES_DEPLOYMENT.md` guide.
2.  Trigger a new build of your pipeline job in Jenkins.
3.  If all previous stages pass, the final "Deploy to Kubernetes" stage will now execute. It will use your uploaded `kubeconfig` file to authenticate with your cluster and run `kubectl apply -f k8s/`, deploying the entire application.
