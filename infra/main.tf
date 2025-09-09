provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-04f59c565deeb2199" # Your AMI
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]

  # No user_data anymore — bootstrap will be handled via workflow SSH

  tags = {
    Name = "k8s-master-runner"
  }
}
