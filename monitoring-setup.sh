#!/bin/bash
set -e

echo "🚀 Setting up Prometheus & Grafana monitoring stack..."

# Add/update Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f ./cluster-addons/monitoring/values.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=Ready pods --all --namespace monitoring --timeout=300s

echo "✅ Monitoring stack deployment complete!"
echo "Grafana: http://<EC2_PUBLIC_IP>:32000"
echo "Prometheus: http://<EC2_PUBLIC_IP>:32001"
