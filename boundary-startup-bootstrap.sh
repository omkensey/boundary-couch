#!/bin/bash

set -euo pipefail

TF_OUTPUT=$(terraform output -json)

BOUNDARY_BOOTSTRAP_HOST=$(echo $TF_OUTPUT | jq -r .boundary_bootstrap_public_ipaddr.value)

scp files/boundary_bootstrap/* core@${BOUNDARY_BOOTSTRAP_HOST}:
ssh -t core@$BOUNDARY_BOOTSTRAP_HOST "sudo cp *.service /etc/systemd/system && sudo mkdir -p /etc/boundary && sudo mv boundary.env boundary-database-init.hcl vault.env /etc/boundary && sudo systemctl daemon-reload && sudo systemctl enable --now boundary-database-migrate && sleep 10 && journalctl -o cat -u boundary-database-init | grep -A 7 'Initial auth information' "
