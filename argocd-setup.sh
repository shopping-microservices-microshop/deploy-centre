#!/bin/bash
set -e

# --- This script installs and configures ArgoCD on a Kubernetes cluster ---

# 1. Install dependencies: apache2-utils (for htpasswd), curl, and jq.
echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y apache2-utils curl jq

# 2. Install ArgoCD from the official stable manifest.
echo "Installing ArgoCD..."
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Patch the ArgoCD server service to type NodePort and set a static port.
#    - http is set to port 30080.
#    - https is set to port 30443.
echo "Patching ArgoCD server service to a static NodePort (30080)..."
kubectl -n argocd patch svc argocd-server --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}, {"op": "replace", "path": "/spec/ports", "value": [{"name": "http", "port": 80, "targetPort": 8080, "nodePort": 30080, "protocol": "TCP"}, {"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30443, "protocol": "TCP"}]}]'

# 4. Wait for the ArgoCD server deployment to be ready before proceeding.
echo "Waiting for ArgoCD server to be ready..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

# 5. Change the default admin password to 'appu@123'.
#    It generates a bcrypt hash and patches the argocd-secret.
echo "Changing ArgoCD admin password..."
NEW_PASS_HASH=$(htpasswd -nbBC 10 "" "appu@123" | tr -d ':\n')
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'"$NEW_PASS_HASH"'", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'

# 6. Restart the ArgoCD server to apply the password change.
echo "Restarting ArgoCD server..."
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s # Wait for restart to complete

# 7. Install the ArgoCD command-line interface (CLI).
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# 8. Get the cluster's internal IP and set the static NodePort.
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=30080 # This is now hardcoded to match the patch above.

# 9. Log in using the ArgoCD CLI to verify credentials and server access.
echo "Logging in with ArgoCD CLI..."
argocd login $NODE_IP:$NODE_PORT \
  --username admin \
  --password appu@123 \
  --insecure

echo "Applying all ArgoCD application manifests from kubernetes/argocd/..."
# This command applies all .yaml files in the directory
sudo -u ubuntu kubectl apply -f /home/ubuntu/deploy-centre/kubernetes/argocd/

# 12. Print the final access details.
echo ""
echo "✅ ArgoCD setup completed!"
echo "👉 Username: admin"
echo "👉 Password: appu@123"
echo "👉 Access ArgoCD at: http://$NODE_IP:$NODE_PORT"

