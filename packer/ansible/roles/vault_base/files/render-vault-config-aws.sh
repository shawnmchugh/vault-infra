#!/bin/bash
set -euo pipefail

VAULT_NODE_ID="$(hostname)"
PRIVATE_IP="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo 127.0.0.1)"

export VAULT_NODE_ID
export PRIVATE_IP

envsubst < /etc/vault.d/vault.hcl.tpl > /etc/vault.d/vault.hcl

echo "Vault config rendered for AWS to /etc/vault.d/vault.hcl"

