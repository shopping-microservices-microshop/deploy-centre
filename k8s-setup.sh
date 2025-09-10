#!/bin/bash
set -euo pipefail

# This script configures a Kubernetes cluster on a machine where
# kubeadm, kubelet, and kubectl are already installed.

echo "🚀 Initializing Kubernetes cluster with kubeadm..."
# The --pod-network-cidr is required for CNI plugins like Weave Net or Calico.
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 \
  --cri-socket unix:///var/run/containerd/containerd.sock

echo "🏠 Configuring kubectl for the 'ubuntu' user..."
# Set up local kubeconfig specifically for the 'ubuntu' user home directory.
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "🔌 Applying Weave Net CNI plugin..."
# We run this as the 'ubuntu' user now that kubectl is configured for them.
sudo -u ubuntu kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Wait for the node to be ready before trying to taint it.
echo "⌛ Waiting for the node to become ready..."
sudo -u ubuntu kubectl wait --for=condition=Ready node --all --timeout=300s

echo "🏷️  Untainting the control-plane node to allow scheduling..."
# Dynamically get the node name instead of hardcoding it.
NODE_NAME=$(sudo -u ubuntu kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# Remove the control-plane taint so that application pods can be scheduled on this node.
sudo -u ubuntu kubectl taint node $NODE_NAME node-role.kubernetes.io/control-plane:NoSchedule- || true

echo "🌐 Installing Ingress Nginx Controller..."
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "✅ Kubernetes cluster setup is complete."
