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

output "chain_private_ip" {
  value = aws_instance.chain.private_ip
}

output "chain_public_ip" {
  value = aws_instance.chain.public_ip
}

output "indexer_private_ip" {
  value = aws_instance.indexer.private_ip
}

output "indexer_public_ip" {
  value = aws_instance.indexer.public_ip
}

output "executor_private_ip" {
  value = aws_instance.executor.private_ip
}

output "executor_public_ip" {
  value = aws_instance.executor.public_ip
}
