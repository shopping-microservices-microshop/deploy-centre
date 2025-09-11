Microservices GitOps Deploy Centre
This repository is the central control plane for bootstrapping a complete, production-ready Kubernetes environment on AWS. It automates the entire lifecycle from infrastructure provisioning with Terraform to application deployment using a GitOps model with ArgoCD.

The core philosophy is to have a single, manually-triggered workflow that provisions a master node, which then sets up itself and the entire cluster, including a self-hosted GitHub Actions runner for future CI/CD tasks.

✨ Core Features
Automated Infrastructure as Code (IaC): Provisions an EC2 instance on AWS using Terraform, with remote state management via S3.

Automated Kubernetes Setup: Configures a Kubernetes cluster on the provisioned EC2 instance.

GitOps with ArgoCD: Automatically installs and configures ArgoCD to manage the deployment of all microservices.

Self-Hosted GitHub Runner: The provisioned EC2 instance is automatically configured as a self-hosted GitHub Actions runner for the organization.

Modular & Scripted Setup: The entire setup process is broken down into logical, reusable shell scripts (k8s-setup.sh, argocd-setup.sh, etc.).

Centralized Application Definitions: Uses the "App of Apps" pattern where ArgoCD tracks application definitions stored within this repository.

⚙️ How It Works: The Bootstrapping Flow
The entire environment is created by a single GitHub Actions workflow, Provision + Run master-setup. Here's a step-by-step breakdown of the process:

Manual Trigger: A developer triggers the workflow from the GitHub Actions UI.

Provision Infrastructure:

The workflow checks out this repository.

It uses Terraform to provision an EC2 instance in AWS.

During the terraform apply step, it generates a GitHub Actions runner registration token and passes it to the EC2 instance configuration.

Remote Execution:

The workflow waits for the EC2 instance to become available via SSH.

It then establishes an SSH connection to the new instance.

Master Setup Orchestration:

Once connected, it clones this deploy-centre repository onto the EC2 instance itself.

It executes the primary orchestration script, ./master-setup.sh, on the remote machine.

Cluster Configuration (on EC2):

The master-setup.sh script runs a series of sub-scripts to:

Install a Kubernetes distribution (e.g., k3s, kubeadm).

Set up Helm for package management.

Install and configure ArgoCD.

Apply the root ArgoCD application manifest (root-argo.yaml), which tells ArgoCD to start managing all other applications defined in the kubernetes/argocd directory.

Install monitoring tools and other cluster addons.

Configure and start the GitHub Actions runner service.

GitOps Takes Over:

ArgoCD, now running in the cluster, reads its configuration from this repository.

It finds the application definitions for cart-service, frontend, etc., and begins deploying them by pulling their respective repositories and Kubernetes manifests.

The cluster is now self-managing. Any changes merged to the microservice repositories' k8s manifests will be automatically synced by ArgoCD.

📂 Repository Structure
.
├── .github/workflows/      # Contains the main bootstrapping GitHub Action
├── infra/                  # Terraform code for AWS infrastructure (EC2, etc.)
│   ├── main.tf
│   └── variables.tf
├── kubernetes/             # Kubernetes manifests for ArgoCD
│   ├── root-argo.yaml      # The root "App of Apps" manifest
│   └── argocd/             # ArgoCD Application definitions for each microservice
│       ├── cart-argo.yaml
│       └── ...
├── cluster-addons/         # (Optional) Manifests for cluster tools like Prometheus, Grafana
├── master-setup.sh         # The master orchestration script run on the EC2 instance
├── k8s-setup.sh            # Script to install and configure Kubernetes
├── argocd-setup.sh         # Script to install and configure ArgoCD
├── helm-setup.sh           # Script to install Helm
├── runner-setup.sh         # Script to configure the self-hosted GitHub runner
└── ...                     # Other helper scripts and documentation

🚀 Getting Started: Full Environment Deployment
Follow these steps to provision and configure the entire environment from scratch.

Prerequisites
AWS Account: An AWS account with an IAM user and programmatic access (Access Key ID & Secret).

Terraform Backend: An S3 bucket and a DynamoDB table in your AWS account for managing Terraform's remote state.

# Example commands to create the backend resources
aws s3api create-bucket --bucket your-unique-terraform-state-bucket-name --region us-east-1
aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region us-east-1

GitHub PAT: A GitHub Personal Access Token with admin:org scope to allow the creation of organization-level self-hosted runners.

SSH Key Pair: An SSH key pair created in the AWS EC2 console. The private key will be used to connect to the instance.

Configuration
Update Terraform Backend: In infra/main.tf, update the backend "s3" block with your S3 bucket name and DynamoDB table name.

Add GitHub Secrets: Add the following secrets to your deploy-centre repository or to the organization's settings:

AWS_ACCESS_KEY_ID: Your AWS access key ID.

AWS_SECRET_ACCESS_KEY: Your AWS secret access key.

GIT_PAT: Your GitHub Personal Access Token.

SSH_PRIVATE_KEY: The entire content of your private SSH key file (.pem).

Deployment
Navigate to the Actions tab of this repository.

Find the "Provision + Run master-setup" workflow in the sidebar.

Click "Run workflow", leave the default branch (main), and click the green "Run workflow" button.

You can monitor the progress in the Actions log. The process will take several minutes.

🔎 Post-Deployment Verification
Once the GitHub Action completes successfully, your environment is ready.

Check the Runner: Go to your GitHub organization's Settings > Actions > Runners. You should see a new, idle self-hosted runner.

SSH into the Instance: Use the public IP address output by the GitHub Action to connect:

ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>

Access ArgoCD UI:

Get the initial admin password:

# Run this on the EC2 instance
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

Expose the ArgoCD server UI to your local machine:

# Run this on your local machine after SSH-ing to the EC2 instance in another terminal
kubectl port-forward svc/argocd-server -n argocd 8080:443

Open https://localhost:8080 in your browser, and log in with the username admin and the password from the previous step. You should see all your microservices being deployed and synced.
