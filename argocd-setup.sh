#!/bin/bash
set -e

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y apache2-utils curl jq

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch ArgoCD service to NodePort
echo "Patching ArgoCD server service to NodePort..."
kubectl -n argocd patch svc argocd-server \
  -p '{"spec": {"type": "NodePort"}}'

# Wait for ArgoCD server pod to be ready
echo "Waiting for ArgoCD server to be ready..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

# Change admin password
echo "Changing ArgoCD admin password..."
NEW_PASS_HASH=$(htpasswd -nbBC 10 "" "appu@123" | tr -d ':\n' | sed 's/^//')
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'"$NEW_PASS_HASH"'", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'

# Restart ArgoCD server to apply password change
echo "Restarting ArgoCD server..."
kubectl -n argocd rollout restart deploy/argocd-server

# Install ArgoCD CLI
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Get Node IP and NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Login with CLI
echo "Logging in with ArgoCD CLI..."
argocd login $NODE_IP:$NODE_PORT \
  --username admin \
  --password appu@123 \
  --insecure

# Create cart-service application
echo "Creating ArgoCD application: cart-service..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cart-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/shopping-microservices-microshop/deploy-centre.git'
    path: kubernetes/cart
    targetRevision: HEAD
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Auto-sync the application
echo "Syncing cart-service application..."
argocd app sync cart-service

echo "✅ ArgoCD setup completed!"
echo "👉 Username: admin"
echo "👉 Password: appu@123"
echo "👉 Access ArgoCD at: http://$NODE_IP:$NODE_PORT"
echo "👉 Application 'cart-service' has been created and synced."

