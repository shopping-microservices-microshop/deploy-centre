#!/bin/bash
set -e

# ================================
# Variables (update if needed)
# ================================
RUNNER_VERSION="2.328.0"
RUNNER_USER="ubuntu"   # change if using another user
RUNNER_DIR="/home/$RUNNER_USER/actions-runner"
ORG_URL="https://github.com/shopping-microservices-microshop"  # org-level URL
RUNNER_TOKEN=$1   # pass token as first argument

if [ -z "$RUNNER_TOKEN" ]; then
  echo "❌ Error: Runner token not provided."
  echo "Usage: ./org-runner-setup.sh <RUNNER_TOKEN>"
  exit 1
fi

# ================================
# 1. Install Docker
# ================================
# Wait if dpkg/apt is locked by unattended-upgrades
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "⏳ Waiting for unattended-upgrades to finish..."
  sleep 10
done

echo "=== Installing Docker ==="
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add runner user to docker group
sudo usermod -aG docker $RUNNER_USER
echo "✅ Docker installed and user '$RUNNER_USER' added to the docker group."

# ================================
# 2. Install dependencies
# ================================
echo "=== Installing dependencies ==="
sudo apt-get install -y curl tar

# ================================
# 3. Download and configure runner
# ================================
echo "=== Setting up GitHub Actions org runner ==="
sudo -u $RUNNER_USER mkdir -p $RUNNER_DIR
cd $RUNNER_DIR

if [ ! -f "actions-runner-linux-x64-$RUNNER_VERSION.tar.gz" ]; then
  sudo -u $RUNNER_USER curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L \
    https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
fi

sudo -u $RUNNER_USER tar xzf actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

echo "=== Configuring runner for organization ==="
sudo -u $RUNNER_USER ./config.sh \
  --url $ORG_URL \
  --token $RUNNER_TOKEN \
  --unattended \
  --replace


# Install yq (v4+)
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

# Verify installation
yq --version



# ================================
# 4. Create systemd service
# ================================
echo "=== Creating systemd service ==="
SERVICE_FILE="/etc/systemd/system/github-org-runner.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=GitHub Actions Organization Runner
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

# ================================
# 5. Enable and start the service
# ================================
echo "=== Enabling and starting runner service ==="
sudo systemctl daemon-reload
sudo systemctl enable github-org-runner
sudo systemctl start github-org-runner

echo "✅ Organization runner setup complete!"
echo "Runner is installed as a systemd service (github-org-runner) and will auto-start on boot."
