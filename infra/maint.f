provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-04f59c565deeb2199" # Ubuntu 22.04 (example), update if needed
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]

  # Inject sensitive values into bootstrap script securely
  user_data = templatefile("${path.module}/bootstrap.sh.tpl", {
    runner_token        = var.runner_token
    aws_access_key_id   = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
  })

  tags = {
    Name = "k8s-master-runner"
    Environment = "GitOps"
    ManagedBy   = "Terraform"
  }
}

# Output the EC2 public IP
output "public_ip" {
  description = "Public IP of the GitOps EC2 instance"
  value       = aws_instance.k8s_master.public_ip
}
