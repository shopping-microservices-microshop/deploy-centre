# Microservices E-Commerce Platform - Deployment Center

A comprehensive deployment solution for a microservices-based e-commerce platform running on Kubernetes with automated infrastructure provisioning, CI/CD, and monitoring.

## 🏗️ Architecture Overview

This repository contains the deployment infrastructure for a complete e-commerce microservices platform including:

- **Frontend Service** - User interface and web application
- **Product Service** - Product catalog and inventory management
- **Cart Service** - Shopping cart functionality with SQLite persistence
- **Query Service** - AI-powered product search using AWS Bedrock

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with secrets configured
- EC2 Key Pair for SSH access
- Security Group allowing HTTP/HTTPS traffic

### Required GitHub Secrets

Configure the following secrets in your GitHub repository:

```
AWS_ACCESS_KEY_ID       # AWS access key for infrastructure provisioning
AWS_SECRET_ACCESS_KEY   # AWS secret key
SSH_PRIVATE_KEY         # Private key for EC2 SSH access
GIT_PAT                 # GitHub Personal Access Token for runner registration
```

### One-Click Deployment

1. Navigate to the **Actions** tab in your GitHub repository
2. Select the **"Provision + Run master-setup (Option 2)"** workflow
3. Click **"Run workflow"** to trigger deployment

The workflow will:
- Provision EC2 infrastructure using Terraform
- Install and configure Kubernetes
- Set up ArgoCD for GitOps
- Deploy monitoring with Prometheus and Grafana
- Configure GitHub Actions self-hosted runner

## 📁 Repository Structure

```
.
├── .github/workflows/          # GitHub Actions workflows
│   └── main.yml               # Main deployment workflow
├── infra/                     # Terraform infrastructure code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   └── bootstrap.sh.tpl      # EC2 bootstrap template
├── kubernetes/               # Kubernetes manifests
│   ├── argocd/              # ArgoCD application definitions
│   └── cluster-infra/       # Cluster-wide resources
├── cluster-addons/          # Helm chart configurations
│   └── monitoring/          # Prometheus/Grafana values
├── *.sh                     # Setup and installation scripts
└── README.md               # This file
```

## 🛠️ Components

### Infrastructure (Terraform)

- **EC2 Instance**: t2.large running Ubuntu
- **S3 Backend**: Terraform state storage with versioning
- **DynamoDB**: State locking for concurrent operations
- **Security Groups**: Network access control

### Kubernetes Platform

- **Runtime**: CRI-O container runtime
- **CNI**: Weave Net networking
- **Ingress**: NGINX Ingress Controller
- **Metrics**: Metrics Server for HPA
- **Storage**: Local persistent volumes

### GitOps (ArgoCD)

- **Applications**: Individual service deployments
- **Sync Policy**: Automated with self-healing
- **Access**: NodePort on port 30080
- **Credentials**: admin/appu@123

### Monitoring Stack

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Access**: 
  - Grafana: Port 32000 (admin/Password@123)
  - Prometheus: Port 32001

### Security Features

- **Network Policies**: Zero-trust networking with default deny
- **RBAC**: Least-privilege access controls
- **Security Contexts**: Non-root containers with proper permissions
- **Secrets Management**: Kubernetes secrets for sensitive data

## 🔧 Manual Setup (Alternative)

If you prefer manual deployment, follow these steps on your EC2 instance:

```bash
# Clone the repository
git clone https://github.com/shopping-microservices-microshop/deploy-centre.git
cd deploy-centre

# Make scripts executable
chmod +x *.sh

# Run the master setup script
./master-setup.sh <RUNNER_TOKEN> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>
```

## 📊 Service Access Points

After successful deployment, access your services:

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | `http://<EC2_IP>/` | - |
| ArgoCD | `http://<EC2_IP>:30080` | admin/appu@123 |
| Grafana | `http://<EC2_IP>:32000` | admin/Password@123 |
| Prometheus | `http://<EC2_IP>:32001` | - |

## 🔍 Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Check all pods
kubectl get pods -A

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress status
kubectl get ingress
```

### View Logs

```bash
# System logs
sudo tail -f /var/log/cloud-init-output.log

# Kubernetes logs
kubectl logs -n argocd deployment/argocd-server

# Service logs
kubectl logs -l app=product-service
```

### Common Issues

1. **Pods in Pending State**: Check resource availability and PVC binding
2. **Network Issues**: Verify NetworkPolicy configurations
3. **ArgoCD Sync Issues**: Check repository access and manifest validity

## 🏆 Best Practices Implemented

### Security
- **Zero-Trust Networking**: Default deny with explicit allow rules
- **Least Privilege**: Minimal RBAC permissions
- **Non-Root Containers**: Security contexts enforcing non-root execution
- **Secret Management**: External secrets injection

### High Availability
- **Health Checks**: Startup, liveness, and readiness probes
- **Auto-scaling**: HPA based on CPU and memory metrics
- **Resource Limits**: Guaranteed QoS classes
- **Persistent Storage**: Proper volume management

### Operations
- **GitOps**: Declarative configuration management
- **Monitoring**: Comprehensive metrics and visualization
- **Automation**: Infrastructure as Code with Terraform
- **Documentation**: Inline comments and troubleshooting guides

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- Open an issue in this repository
- Check the troubleshooting section above
- Review the Kubernetes best practices documentation

## 🔮 Roadmap

- [ ] Add SSL/TLS certificates with Let's Encrypt
- [ ] Implement backup strategies for persistent data
- [ ] Add distributed tracing with Jaeger
- [ ] Implement blue-green deployment strategies
- [ ] Add automated security scanning
