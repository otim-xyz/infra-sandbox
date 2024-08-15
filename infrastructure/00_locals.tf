locals {
  name_prefix = "dev-infra-sandbox"
  admin_name  = "otim-admin"
}

locals {
  influxdb_api_token = data.external.get_influxdb_api_token.result["influxdb_api_token"]
}

locals {
  syslog_identifier          = "otim-offchain"
  poll_interval              = 2
  fibonacci_contract_address = "326d78837ddb62431aae57245899b188f1d02310"
}
