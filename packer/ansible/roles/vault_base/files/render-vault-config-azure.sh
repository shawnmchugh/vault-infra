#!/bin/bash
set -euo pipefail

VAULT_NODE_ID="$(hostname)"
PRIVATE_IP="$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-02-01&format=text" || echo 127.0.0.1)"

export VAULT_NODE_ID
export PRIVATE_IP

envsubst < /etc/vault.d/vault.hcl.tpl > /etc/vault.d/vault.hcl

echo "Vault config rendered for Azure to /etc/vault.d/vault.hcl"

