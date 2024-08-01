#!/bin/bash

aws eks \
  --region "$(tofu output -raw region)" \
  --profile dev \
  update-kubeconfig \
  --name "$(tofu output -raw cluster_name)"
