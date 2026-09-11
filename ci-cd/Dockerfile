# /ci-cd/Dockerfile
# This Dockerfile creates a custom Jenkins agent with all the tools needed for our CI/CD pipeline.

# Start from a standard Jenkins inbound agent image
FROM jenkins/inbound-agent:latest

# Switch to the root user to install packages
USER root

# 1. Install basic prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    software-properties-common \
    unzip \
    --no-install-recommends

# 2. Install Go
ENV GO_VERSION=1.22.5
RUN curl -L "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# 3. Install Docker CLI (to communicate with the host's Docker daemon)
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

# 4. Install Ansible
RUN add-apt-repository --yes --update ppa:ansible/ansible
RUN apt-get install -y ansible

# 5. Install Gitleaks
ENV GITLEAKS_VERSION=8.18.2
RUN curl -L "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | tar -C /usr/local/bin -xz gitleaks

# Cleanup apt cache
RUN rm -rf /var/lib/apt/lists/*

# Switch back to the jenkins user
USER jenkins
