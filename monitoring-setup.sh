#!/bin/bash
set -e

echo "🚀 Setting up Prometheus & Grafana monitoring stack..."

# This command uses the values.yaml file from your repository structure
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f ./cluster-addons/monitoring/values.yaml

echo "✅ Monitoring stack deployment initiated."

