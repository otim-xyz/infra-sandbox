#!/bin/bash

sudo yum install -y mongodb-mongosh-shared-openssl3

cat <<EOF >mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

sudo mv mongodb-org-7.0.repo /etc/yum.repos.d/mongodb-org-7.0.repo
sudo yum install -y mongodb-org

cat <<EOF >mongodb.conf
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Where and how to store data.
storage:
  dbPath: /var/lib/mongo

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0
EOF

sudo mv mongodb.conf /etc/mongod.conf

sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl enable mongod
