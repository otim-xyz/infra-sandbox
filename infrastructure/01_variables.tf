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

variable "executor_signer_key" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "syslog_identifier" {
  type      = string
  nullable  = false
  sensitive = false
}

variable "poll_interval" {
  type      = string
  nullable  = false
  sensitive = false
}

variable "fibonacci_contract_address" {
  type      = string
  nullable  = false
  sensitive = false
}
