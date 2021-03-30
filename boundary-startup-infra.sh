#!/bin/bash

set -euo pipefail

TF_OUTPUT=$(terraform output -json)

BOUNDARY_INFRA_HOST=$(echo $TF_OUTPUT | jq -r .boundary_infra_public_ipaddr.value)

scp files/boundary_infra/* core@${BOUNDARY_INFRA_HOST}:
ssh -t core@$BOUNDARY_INFRA_HOST "sudo systemctl mask update-engine locksmithd && sudo cp *.service /etc/systemd/system && sudo mkdir -p /etc/{vault,postgres,postgres/postgres-data} && sudo mv vault.env /etc/vault && sudo chown -R 100:1000 /etc/vault && sudo mv postgres.env /etc/postgres && sudo systemctl daemon-reload && sudo systemctl enable --now postgres vault"
