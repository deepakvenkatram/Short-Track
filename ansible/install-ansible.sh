#!/bin/bash
#
# This script checks if Ansible is installed and installs it if it's not found.
# It is designed for Debian/Ubuntu-based systems.

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if Ansible is installed by trying to find its command path
if command -v ansible >/dev/null 2>&1; then
    echo "✅ Ansible is already installed."
    ansible --version
else
    echo "Ansible not found. Proceeding with installation for Ubuntu/Debian..."

    # 1. Update package index
    echo "Updating apt cache..."
    sudo apt-get update

    # 2. Install prerequisites for adding new repositories
    echo "Installing prerequisite packages..."
    sudo apt-get install -y software-properties-common

    # 3. Add the official Ansible PPA (Personal Package Archive)
    echo "Adding Ansible PPA..."
    sudo add-apt-repository --yes --update ppa:ansible/ansible

    # 4. Install Ansible
    echo "Installing Ansible..."
    sudo apt-get install -y ansible

    echo "✅ Ansible installation complete."
    ansible --version
fi

exit 0
