output "influxdb_api_token" {
  value     = data.external.get_influxdb_api_token.result
  sensitive = true
}

output "monitoring_private_ip" {
  value = aws_instance.monitoring.private_ip
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}

output "database_public_ip" {
  value = aws_instance.database.public_ip
}
