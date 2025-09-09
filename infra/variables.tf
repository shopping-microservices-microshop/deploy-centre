variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "ssh_key_name" {
  description = "The name of the EC2 Key Pair to allow SSH access to the instance."
  type        = string
  default     = "my-keypair" # <-- replace with your actual EC2 key pair name
}

variable "instance_type" {
  description = "EC2 instance type for the runner."
  type        = string
  default     = "t2.large"
}

variable "runner_token" {
  description = "The registration token for the GitHub Actions runner."
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for the query-service."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for the query-service."
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  description = "The ID of the existing security group to attach to the EC2 instance."
  type        = string
  default     = "sg-083cd817b13d667d1" # <-- replace with your actual security group ID
}
