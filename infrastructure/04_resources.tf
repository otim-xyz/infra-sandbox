resource "aws_security_group" "main_sg" {
  name   = "${local.name_prefix}-main-sg"
  vpc_id = data.aws_vpc.default.id

  # this should be removed from the sg after setup
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_instance" "monitoring" {
  ami                    = "ami-0b9593848b0f1934e"
  instance_type          = "t2.large"
  key_name               = "matthew@technocore"
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = true
  }
  tags = {
    Name = "${local.name_prefix}-monitoring"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-tailscale.sh"
    content     = file("${path.module}/../scripts/install-tailscale.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-influxdb.sh"
    content     = file("${path.module}/../scripts/install-influxdb.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-grafana.sh"
    content     = file("${path.module}/../scripts/install-grafana.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-vector.sh"
    content     = file("${path.module}/../scripts/install-vector.sh")
  }

  provisioner "remote-exec" {
    inline = [
      "export TAILSCALE_AUTHKEY='${var.tailscale_authkey}'",
      "export TAILSCALE_HOSTNAME='${self.tags.Name}'",
      "export INFLUXDB_PASSWORD='${var.influxdb_password}'",
      "export INFLUXDB_ADMIN='${local.admin_name}'",
      "export INFLUXDB_HOST='localhost'",

      "bash /home/ec2-user/install-tailscale.sh",
      "bash /home/ec2-user/install-influxdb.sh",
      "bash /home/ec2-user/install-grafana.sh",
      "bash /home/ec2-user/install-vector.sh"
    ]
  }
}

resource "aws_instance" "database" {
  ami                    = "ami-0b9593848b0f1934e"
  instance_type          = "t2.micro"
  key_name               = "matthew@technocore"
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = true
  }
  tags = {
    Name = "${local.name_prefix}-database"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-tailscale.sh"
    content     = file("${path.module}/../scripts/install-tailscale.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-vector.sh"
    content     = file("${path.module}/../scripts/install-vector.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-mongodb.sh"
    content     = file("${path.module}/../scripts/install-mongodb.sh")
  }

  provisioner "remote-exec" {
    inline = [
      "export TAILSCALE_AUTHKEY='${var.tailscale_authkey}'",
      "export TAILSCALE_HOSTNAME='${self.tags.Name}'",

      "sudo systemctl set-environment INFLUXDB_HOST='${aws_instance.monitoring.private_ip}'",
      "sudo systemctl set-environment INFLUXDB_API_TOKEN='${local.influxdb_api_token}'",

      "bash /home/ec2-user/install-tailscale.sh",
      "bash /home/ec2-user/install-vector.sh",
      "bash /home/ec2-user/install-mongodb.sh"
    ]
  }
}

resource "aws_instance" "chain" {
  ami                    = "ami-0b9593848b0f1934e"
  instance_type          = "t2.micro"
  key_name               = "matthew@technocore"
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = true
  }
  tags = {
    Name = "${local.name_prefix}-chain"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-tailscale.sh"
    content     = file("${path.module}/../scripts/install-tailscale.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-vector.sh"
    content     = file("${path.module}/../scripts/install-vector.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-docker.sh"
    content     = file("${path.module}/../scripts/install-docker.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/docker-compose.yml"
    content     = file("${path.module}/../chain/docker-compose.yml")
  }

  provisioner "remote-exec" {
    inline = [
      "export TAILSCALE_AUTHKEY='${var.tailscale_authkey}'",
      "export TAILSCALE_HOSTNAME='${self.tags.Name}'",

      "sudo systemctl set-environment INFLUXDB_HOST='${aws_instance.monitoring.private_ip}'",
      "sudo systemctl set-environment INFLUXDB_API_TOKEN='${local.influxdb_api_token}'",

      "bash /home/ec2-user/install-tailscale.sh",
      "bash /home/ec2-user/install-vector.sh",
      "bash /home/ec2-user/install-docker.sh",

      "sudo docker-compose --file /home/ec2-user/docker-compose.yml up --detach"
    ]
  }
}

resource "aws_instance" "executor" {
  ami                    = "ami-0b9593848b0f1934e"
  instance_type          = "t2.micro"
  key_name               = "matthew@technocore"
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = true
  }
  tags = {
    Name = "${local.name_prefix}-executor"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-tailscale.sh"
    content     = file("${path.module}/../scripts/install-tailscale.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-vector.sh"
    content     = file("${path.module}/../scripts/install-vector.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/install-docker.sh"
    content     = file("${path.module}/../scripts/install-docker.sh")
  }

  provisioner "file" {
    destination = "/home/ec2-user/docker-compose.yml"
    content     = file("${path.module}/../agents/crates/executor/docker-compose.yml")
  }

  provisioner "file" {
    destination = "/home/ec2-user/.env"
    content = templatefile("${path.module}/templates/executor-env.tftpl", {
      monitoring_private_ip      = aws_instance.monitoring.private_ip,
      database_private_ip        = aws_instance.database.private_ip,
      chain_private_ip           = aws_instance.chain.private_ip,
      fibonacci_contract_address = var.fibonacci_contract_address,
      poll_interval              = var.poll_interval,
      executor_signer_key        = var.executor_signer_key
    })
  }

  provisioner "remote-exec" {
    inline = [
      "export TAILSCALE_AUTHKEY='${var.tailscale_authkey}'",
      "export TAILSCALE_HOSTNAME='${self.tags.Name}'",

      "sudo systemctl set-environment INFLUXDB_HOST='${aws_instance.monitoring.private_ip}'",
      "sudo systemctl set-environment INFLUXDB_API_TOKEN='${local.influxdb_api_token}'",

      "bash /home/ec2-user/install-tailscale.sh",
      "bash /home/ec2-user/install-vector.sh",
      "bash /home/ec2-user/install-docker.sh",

      "sudo docker-compose --file /home/ec2-user/docker-compose.yml up --detach"
    ]
  }
}
