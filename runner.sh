#!/bin/bash
# GitHub Actions self-hosted runner setup script with Docker 
# Assumes Ubuntu and runner user is 'ubuntu'

set -e

# =======================
# Variables — UPDATE THESE
# =======================
RUNNER_USER=ubuntu
REPO_URL="https://github.com/shopping-microservices-microshop"
RUNNER_TOKEN="A7LMLE5WK5RLGCB5QJUC76LIXE7GE"
RUNNER_VERSION="2.328.0"
RUNNER_DIR="/home/$RUNNER_USER/actions-runner"

# =======================
# 1. Install Docker
# =======================
echo "=== Installing Docker ==="
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add runner user to docker group
sudo usermod -aG docker $RUNNER_USER

# Apply docker group immediately for this session
newgrp docker <<EONG
docker run --rm hello-world
EONG

# =======================
# 2. Download and configure runner
# =======================
echo "=== Setting up GitHub Actions runner ==="

sudo -u $RUNNER_USER mkdir -p $RUNNER_DIR
cd $RUNNER_DIR

sudo -u $RUNNER_USER curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L \
  https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

sudo -u $RUNNER_USER tar xzf actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# Configure runner (unattended, replace if exists)
sudo -u $RUNNER_USER ./config.sh --url $REPO_URL --token $RUNNER_TOKEN --unattended --replace

# =======================
# 3. Setup systemd service
# =======================
echo "=== Creating systemd service for runner ==="
SERVICE_FILE="/etc/systemd/system/github-runner.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
User=$RUNNER_USER
WorkingDirectory=$RUNNER_DIR
ExecStart=$RUNNER_DIR/run.sh
Restart=always
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl start github-runner
# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable github-runner

echo "=== Runner setup complete! ==="
echo "The GitHub Actions runner is now running as a systemd service and will start on boot."



