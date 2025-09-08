#!/bin/bash
# GitHub Actions self-hosted runner setup script with Docker
# Assumes Ubuntu and runner user is 'ubuntu'

set -e

# =======================
# Variables
# =======================
RUNNER_USER=ubuntu
REPO_URL="https://github.com/shopping-microservices-microshop"
# The token is now passed in as the first argument to this script
RUNNER_TOKEN="$1"
RUNNER_VERSION="2.328.0" # Consider updating this version periodically
RUNNER_DIR="/home/$RUNNER_USER/actions-runner"

# Check if a token was provided
if [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: A runner token must be provided as the first argument."
  exit 1
fi

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
echo "Docker installed and user '$RUNNER_USER' added to the docker group."

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
# The --token variable is now safely passed in from the argument
echo "Configuring the runner..."
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

# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable github-runner
sudo systemctl start github-runner

echo "=== Runner setup complete! ==="
echo "The GitHub Actions runner is now running as a systemd service and will start on boot."

