#!/bin/bash

sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install tailscale -y
sudo systemctl enable --now tailscaled
sudo tailscale up \
  --authkey "$TAILSCALE_AUTHKEY" \
  --hostname "$TAILSCALE_HOSTNAME"
