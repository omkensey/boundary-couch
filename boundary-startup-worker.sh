#!/bin/bash

set -euo pipefail

TF_OUTPUT=$(terraform output -json)

BOUNDARY_WORKER_BASE=$(echo $TF_OUTPUT | jq -r '.boundary_worker_base_public_ipaddr.value')
BOUNDARY_WORKER_DOCKER=$(echo $TF_OUTPUT | jq -r '.boundary_worker_docker_public_ipaddr.value')

scp files/boundary_base/boundary-worker/* core@${BOUNDARY_WORKER_BASE}:
ssh -t core@$BOUNDARY_WORKER_BASE "sudo cp *.service /etc/systemd/system/; sudo mkdir -p /etc/boundary; sudo mv *.env *.hcl /etc/boundary; sudo systemctl daemon-reload; sudo systemctl enable --now boundary-worker"

scp files/boundary_worker_docker/* core@${BOUNDARY_WORKER_DOCKER}:
ssh -t core@$BOUNDARY_WORKER_DOCKER "sudo cp *.service /etc/systemd/system/; sudo mkdir -p /etc/boundary; sudo mv *.env *.hcl /etc/boundary; sudo systemctl daemon-reload; sudo systemctl enable --now boundary-worker"
