variable "aws_profile" {
  description = "Local AWS CLI profile to use"
  type        = string
  default     = "pd-newapi"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m7i-flex.large"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the instance (your own IP, e.g. 1.2.3.4/32)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key to install on the instance"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "domain_name" {
  description = "Domain name for Caddy to request HTTPS for. Leave empty to serve plain HTTP on the instance's IP instead."
  type        = string
  default     = ""
}
