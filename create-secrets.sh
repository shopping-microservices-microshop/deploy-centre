#!/bin/bash
set -e

# Arguments are passed in from the master setup script
AWS_ACCESS_KEY_ID="$1"
AWS_SECRET_ACCESS_KEY="$2"

echo "🔑 Creating Kubernetes secret for AWS credentials..."

# Use kubectl as the ubuntu user to create the secret
sudo -u ubuntu kubectl create secret generic aws-credentials \
  --namespace=default \
  --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  --dry-run=client -o yaml | sudo -u ubuntu kubectl apply -f -

echo "✅ Secret 'aws-credentials' created successfully."

