terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "tailscale_authkey" {
  type      = string
  nullable  = false
  sensitive = true
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "dev"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "tailscale_test_sg" {
  name   = "tailscale_test_sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "All private ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tailscale_test" {
  ami                         = "ami-0b9593848b0f1934e"
  instance_type               = "t2.micro"
  key_name                    = "matthew@technocore"
  vpc_security_group_ids      = [aws_security_group.tailscale_test_sg.id]
  associate_public_ip_address = false
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = true
  }
  tags = {
    Name = "Tailscale Test"
  }
  user_data_replace_on_change = true
  user_data = <<EOF
#!/bin/bash

${templatefile("${path.module}/scripts/install-tailscale.sh", {
  tailscale_authkey  = var.tailscale_authkey
  tailscale_hostname = "dev-infra-sandbox-tailscale-test"
})}

${templatefile("${path.module}/scripts/install-node-exporter.sh", {})}

${templatefile("${path.module}/scripts/install-docker.sh", {})}

# echo '${templatefile("${path.module}/../monitoring/docker-compose.yml", {})}' \
#   > /home/ec2-user/docker-compose.yml

EOF
}
