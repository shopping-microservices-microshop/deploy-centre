
#!/bin/bash
# This script is executed by the EC2 user_data at first boot.

set -e
set -x # Print each command for easier debugging

# --- VARIABLES (injected by Terraform) ---
RUNNER_TOKEN="${runner_token}"
AWS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_KEY="${aws_secret_access_key}"
REPO_URL="https://github.com/shopping-microservices-microshop/deploy-centre.git"
REPO_DIR="/home/ubuntu/deploy-centre"

# 1. Wait for cloud-init and install Git
echo "Waiting for cloud-init to complete..."
cloud-init status --wait
echo "Installing Git..."
sudo apt-get update -y
sudo apt-get install -y git

# 2. Clone your deploy-centre repository
echo "Cloning repository..."
sudo -u ubuntu git clone $REPO_URL $REPO_DIR

# 3. Make all scripts in the cloned repo executable
echo "Setting execution permissions for all .sh files..."
sudo chmod +x $REPO_DIR/*.sh

# 4. Execute the master setup script from within the cloned repo
echo "Executing master setup script..."
cd $REPO_DIR
sudo -u ubuntu ./master-setup.sh "$RUNNER_TOKEN" "$AWS_KEY_ID" "$AWS_SECRET_KEY"

echo "--- EC2 Bootstrap Process Finished ---"

