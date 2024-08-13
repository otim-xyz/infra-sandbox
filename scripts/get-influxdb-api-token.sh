#!/bin/bash

set -e

INPUT=$(cat)

PUBLIC_IP=$(echo "$INPUT" | jq --raw-output '.public_ip')

INFLUXDB_API_TOKEN=$(ssh -o StrictHostKeyChecking=no ec2-user@"$PUBLIC_IP" "cat /home/ec2-user/influxdb_api_token")

jq -n \
  --arg influxdb_api_token "$INFLUXDB_API_TOKEN" \
  '{"influxdb_api_token":$influxdb_api_token}'
