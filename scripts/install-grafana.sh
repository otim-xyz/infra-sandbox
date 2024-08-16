#!/bin/bash

set -e

curl -LO https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key
rm gpg.key

cat <<EOF >grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo mv grafana.repo /etc/yum.repos.d/grafana.repo

sudo dnf install grafana -y

cat <<EOF >influxdb-datasource.yaml
apiVersion: 1

datasources:
  - name: InfluxDB_v2_Flux
    version: 2
    type: influxdb
    access: proxy
    url: http://localhost:8086
    jsonData:
      version: Flux
      organization: otim-xyz
      defaultBucket: otim-default
      skipTlsVerify: true
    secureJsonData:
      token: '$INFLUXDB_API_TOKEN'
    editable: true
EOF

sudo mv influxdb-datasource.yaml /etc/grafana/provisioning/datasources/influxdb-datasource.yaml

cat <<EOF >loki-datasource.yaml
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://localhost:3100
    jsonData:
      timeout: 60
      maxLines: 1000
EOF

sudo mv loki-datasource.yaml /etc/grafana/provisioning/datasources/loki-datasource.yaml

sudo dnf install loki -y

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
