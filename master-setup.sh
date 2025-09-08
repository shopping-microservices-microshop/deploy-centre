#!/bin/bash
# This is the master orchestrator script. It runs all other setup scripts
# in the correct order. It should be executed by the EC2 user_data script.

set -e

# --- Arguments passed from the bootstrap process ---
RUNNER_TOKEN="$1"
AWS_KEY_ID="$2"
AWS_SECRET_KEY="$3"

# --- Script Execution ---

echo "--- Running Runner Setup ---"
./runner-setup.sh "$RUNNER_TOKEN"

echo "--- Running Kubernetes Setup ---"
./k8s-setup.sh

echo "--- Running Secret Creation Setup ---"
# This new script creates the aws-credentials secret before ArgoCD needs it
./create-secrets.sh "$AWS_KEY_ID" "$AWS_SECRET_KEY"

echo "--- Running Helm Setup ---"
./helm-setup.sh

echo "--- Running Argo CD Setup ---"
./argocd-setup.sh

echo "--- Running Monitoring Setup ---"
# This new script deploys Prometheus and Grafana
./monitoring-setup.sh

echo "🎉🎉🎉 All setup scripts completed successfully! 🎉🎉🎉"

