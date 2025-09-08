# This Terraform configuration creates the EC2 instance and uses a
# bootstrap script to configure the entire environment.

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-04f59c565deeb2199" # Your specified AMI
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  # This now uses a variable to attach your existing security group.
  vpc_security_group_ids      = [var.security_group_id]

  # The templatefile function securely injects secrets into the bootstrap script.
  user_data = templatefile("${path.module}/bootstrap.sh.tpl", {
    github_runner_token   = var.github_runner_token
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
  })

  tags = {
    Name = "k8s-master-runner"
  }
}


