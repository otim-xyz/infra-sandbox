#!/bin/bash

# install tailscale

sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install tailscale -y
sudo systemctl enable --now tailscaled
sudo tailscale up \
  --authkey "${tailscale_authkey}" \
  --hostname "${tailscale_hostname}"
