variable "tailscale_authkey" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "influxdb_password" {
  type      = string
  nullable  = false
  sensitive = true
}
