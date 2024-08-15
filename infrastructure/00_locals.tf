locals {
  name_prefix = "dev-infra-sandbox"
  admin_name  = "otim-admin"
}

locals {
  influxdb_api_token = data.external.get_influxdb_api_token.result["influxdb_api_token"]
}
