#!/bin/bash

set -e

curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash -s -- -y
sudo mkdir -p /var/lib/vector/
sudo chown -R ec2-user:ec2-user /var/lib/vector/

cat <<'EOF' >vector.yaml
#                                    __   __  __
#                                    \ \ / / / /
#                                     \ V / / /
#                                      \_/  \/
#
#                                    V E C T O R
#                                   Configuration
#
# ------------------------------------------------------------------------------
# Website: https://vector.dev
# Docs: https://vector.dev/docs
# Chat: https://chat.vector.dev
# ------------------------------------------------------------------------------

# Change this to use a non-default directory for Vector data storage:
# data_dir: "/var/lib/vector"

# Random Syslog-formatted logs
sources:

  journald:
    type: journald
    exclude_matches:
      _TRANSPORT:
        - kernel
    extra_args:
      - --identifier=otim-offchain
      - --output=json

  host:
    type: host_metrics
    collectors:
      - host
    namespace: host
    scrape_interval_secs: 5

  network:
    type: host_metrics
    collectors:
      - network
    namespace: host
    scrape_interval_secs: 5
    network:
      devices:
        excludes:
          - docker*
          - lo

  memory:
    type: host_metrics
    collectors:
      - memory
    namespace: host
    scrape_interval_secs: 5

  load:
    type: host_metrics
    collectors:
      - load
    namespace: host
    scrape_interval_secs: 5

  filesystem:
    type: host_metrics
    collectors:
      - filesystem
    namespace: host
    scrape_interval_secs: 5
    filesystem:
      mountpoints:
        excludes:
          - /boot*
      filesystems:
        includes:
          - xfs
          - vfat
          - ext*

# Parse Syslog logs
# See the Vector Remap Language reference for more info: https://vrl.dev
transforms:

  tracing:
    type: remap
    inputs:
      - journald
    source: |-
      . = filter(.) -> |k, v| { !starts_with(k, "_") }
      . = map_keys(.) -> |k| { downcase(k) }

      if .priority == "3" {
        .level = "ERROR"
      }
      if .priority == "4" {
        .level = "WARN"
      }
      if .priority == "5" {
        .level = "INFO"
      }
      if .priority == "6" {
        .level = "DEBUG"
      }
      if .priority == "7" {
        .level = "TRACE"
      }

      del(.priority)

  uptime:
    type: filter
    inputs:
      - host
    condition: |
      .name == "uptime"

  network_io:
    type: filter
    inputs:
      - network
    condition: >
      .name == "network_transmit_bytes_total"
      || .name == "network_receive_bytes_total"

  memory_used:
    type: filter
    inputs:
      - memory
    condition: >
      .name == "memory_total_bytes"
      || .name == "memory_available_bytes"

  load1:
    type: filter
    inputs:
      - load
    condition: |
      .name == "load1"

  filesystem_used:
    type: filter
    inputs:
      - filesystem
    condition: |
      .name == "filesystem_used_ratio"

sinks:

  influxdb_metrics:
    type: influxdb_metrics
    inputs:
      - load1
      - filesystem_used
      - memory_used
      - network_io
      - uptime
    bucket: otim-metrics
    endpoint: http://$INFLUXDB_HOST:8086
    org: otim-xyz
    token: $INFLUXDB_API_TOKEN

  influxdb_logs:
    type: influxdb_logs
    inputs:
      - tracing
    bucket: otim-tracing
    measurement: vector-logs
    endpoint: http://$INFLUXDB_HOST:8086
    org: otim-xyz
    token: $INFLUXDB_API_TOKEN

# Print parsed logs to stdout
# sinks:
#
#   print:
#     type: console
#     inputs:
#       - load1
#       - filesystem_used
#       - memory_used
#       - network_io
#       - uptime
#       - tracing
#     encoding:
#       codec: "json"
#       json:
#         pretty: true
EOF

sudo mkdir -p /home/ec2-user/.vector/config/
sudo mv vector.yaml /home/ec2-user/.vector/config/vector.yaml

cat <<'EOF' >vector.service
[Unit]
Description=Vector
After=network.target
Requires=network-online.target

[Service]
User=ec2-user
Group=ec2-user
ExecStart=/home/ec2-user/.vector/bin/vector --config /home/ec2-user/.vector/config/vector.yaml
ExecReload=/bin/kill -HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo mv vector.service /etc/systemd/system/vector.service
sudo systemctl daemon-reload
sudo systemctl start vector
sudo systemctl enable vector
