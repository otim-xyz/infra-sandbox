data "aws_vpc" "default" {
  default = true
}

data "external" "get_influxdb_api_token" {
  program = ["bash", "${path.module}/../scripts/get-influxdb-api-token.sh"]

  query = {
    public_ip = aws_instance.monitoring.public_ip
  }
}
