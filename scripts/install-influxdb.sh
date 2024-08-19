#!/bin/bash

set -e

curl -LO https://download.influxdata.com/influxdb/releases/influxdb2-2.7.8-1.x86_64.rpm
sudo dnf install influxdb2-2.7.8-1.x86_64.rpm -y
sudo systemctl start influxdb
sudo systemctl enable influxdb

curl -LO https://download.influxdata.com/influxdb/releases/influxdb2-client-2.7.5-linux-amd64.tar.gz
mkdir -p influxdb2-client
tar xvzf influxdb2-client-2.7.5-linux-amd64.tar.gz --directory influxdb2-client
sudo mv influxdb2-client/influx /usr/local/bin

influx setup \
  --username "$INFLUXDB_ADMIN" \
  --password "$INFLUXDB_PASSWORD" \
  --org otim-xyz \
  --bucket otim-default \
  --force

influx bucket create --name otim-tracing
influx bucket create --name otim-metrics

influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org otim-xyz \
  --token "$(influx auth list --json | jq --raw-output '.[0].token')"

# set up for local vector installation
sudo systemctl set-environment INFLUXDB_HOST="localhost"
sudo systemctl set-environment INFLUXDB_API_TOKEN="$(influx auth list --json | jq --raw-output '.[1].token')"

# set up for tofu remote data source
influx auth list --json | jq --raw-output '.[1].token' >/home/ec2-user/influxdb_api_token
