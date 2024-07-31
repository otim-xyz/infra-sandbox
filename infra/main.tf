terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "dev"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "sandbox_sg_tf" {
  name   = "sandbox-security-group"
  vpc_id = data.aws_vpc.default.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_ssh_from_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sandbox_sg_tf.id
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINN42oBOs/3BVkjlrjve3aN9eWRuLXZvXTwVWDmbALLi m@lattejed.com"
}

resource "aws_instance" "sandbox_alpha" {
  ami                         = "ami-0162fe8bfebb6ea16"
  instance_type               = "t2.micro"
  key_name                    = "ssh-key"
  vpc_security_group_ids      = [aws_security_group.sandbox_sg_tf.id]
  associate_public_ip_address = true
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }
  tags = {
    Name = "sandbox-alpha"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.sandbox_alpha.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.sandbox_alpha.public_ip
}
