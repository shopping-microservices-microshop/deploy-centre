provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-04f59c565deeb2199" # Update to your latest Ubuntu AMI
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]

  # We removed user_data, since the GitHub Actions workflow now handles bootstrap via SSH
  user_data = null

  tags = {
    Name = "k8s-master-runner"
  }
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.k8s_master.public_ip
}
