terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deploy" {
  key_name   = "newapi-deploy"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_security_group" "newapi" {
  name        = "newapi-sg"
  description = "New API host: SSH from admin IP only, HTTP/HTTPS open"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "LobeChat frontend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Infisical (admin IP only unless infisical_public is true)"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.infisical_public ? ["0.0.0.0/0"] : [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "newapi-sg"
  }
}

resource "aws_instance" "newapi" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [aws_security_group.newapi.id]

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    domain_name = var.domain_name
    public_ip   = aws_eip.newapi.public_ip
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = {
    Name = "newapi"
  }
}

resource "aws_eip" "newapi" {
  domain = "vpc"

  tags = {
    Name = "newapi"
  }
}

resource "aws_eip_association" "newapi" {
  instance_id   = aws_instance.newapi.id
  allocation_id = aws_eip.newapi.id
}
