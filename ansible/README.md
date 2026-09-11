# Ansible Host Setup Playbook for Short-Track

## 1. Purpose & Benefits

This Ansible playbook automates the complete setup of a fresh Ubuntu host, transforming it into a "control node" ready for developing, running, or deploying the "Short-Track" project.

The primary goal is to achieve a consistent, repeatable, and automated environment setup, which is a cornerstone of modern DevOps and CI/CD practices.

### Why is this useful?

*   **Consistency:** Ensures that every developer's machine or CI/CD runner is configured with the exact same set of tools and versions, eliminating "it works on my machine" problems.
*   **Automation:** Reduces manual setup time from hours to minutes. A single command provisions a new machine, minimizing the potential for human error.
*   **Repeatability:** You can destroy and recreate environments with the confidence that they will be identical every time. This is critical for testing and disaster recovery.
*   **Executable Documentation:** The playbook itself serves as living, testable documentation for the project's system-level dependencies.

## 2. What It Installs

This playbook will install and configure the following essential tools on a target Ubuntu host:

*   **Git:** For cloning the project repository.
*   **Docker Engine:** The container runtime needed to build and run Docker images.
*   **Docker Compose:** The tool for running the local multi-container environment.
*   **kubectl:** The official command-line tool for interacting with a Kubernetes cluster.

## 3. Prerequisites

#### On Your Local Machine (the "Control Node")

Your local machine is the computer from which you will run the Ansible commands.

*   **Ansible Installation:** Ansible must be installed on this machine. We have provided a bootstrapping script to simplify this process for Ubuntu/Debian systems.

    To install Ansible, run the following commands from the project's root (`short-track/`) directory:
    ```bash
    # Make the script executable
    chmod +x ansible/install-ansible.sh

    # Run the script
    ./ansible/install-ansible.sh
    ```
    The script will automatically check for Ansible and install it if it's not found.

*   **Project Files:** You have cloned the `short-track` project repository.

#### On the Remote Host (the server you are configuring)
*   An **Ubuntu-based** Linux distribution.
*   **SSH access** from your local machine. Your SSH public key should be in the remote user's `~/.ssh/authorized_keys` file.
*   A user account with `sudo` privileges (the playbook assumes you are connecting with this user).

## 4. Step-by-Step Instructions

### Step 1: Configure the Inventory

The `inventory` file tells Ansible which server(s) to connect to.

1.  Open the `ansible/inventory` file.
2.  You will see the following line:
    ```ini
    [control_node]
    your_server_ip ansible_user=ubuntu
    ```
3.  **Replace `your_server_ip`** with the actual IP address or DNS name of your remote host.
4.  **Replace `ubuntu`** with the username you use to SSH into the remote host (e.g., `root`, `ec2-user`, etc.).

### Step 2: Run the Playbook

Navigate to the root directory of the `short-track` project in your terminal. From there, run the following command:

```bash
ansible-playbook -i ansible/inventory ansible/setup-host.yml
```

*   `ansible-playbook` is the command to execute a playbook.
*   `-i ansible/inventory` specifies your inventory file.
*   `ansible/setup-host.yml` is the main playbook file to be executed.

Ansible will then connect to your remote host via SSH and begin executing the tasks defined in the roles. You will see the output of each task in your terminal.

### Step 3: Verify the Installation

After the playbook finishes successfully, you can SSH into your remote host to verify that the tools are installed:

```bash
ssh <your_ansible_user>@<your_server_ip>

# Once on the remote host, run these commands:
docker --version
git --version
kubectl version --client

# Note: To run docker commands without sudo, you may need to log out and log back in.
# The playbook will print a message if this is required.
```

Your host is now fully configured and ready to be used as a development machine or a CI/CD runner for this project.
