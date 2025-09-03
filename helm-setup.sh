#!/bin/bash

set -e

echo "🚀 Installing Helm..."

# Download and run official Helm install script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
echo "✅ Helm installed successfully!"
helm version

# Add stable repo (optional but useful)
helm repo add stable https://charts.helm.sh/stable
helm repo update

