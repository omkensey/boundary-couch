#!/bin/bash

set -euo pipefail

TF_OUTPUT=$(terraform output -json)

BOUNDARY_CONTROLLERS=$(echo $TF_OUTPUT | jq -r '.boundary_controller_public_ipaddrs.value | join(" ")')

for index in ${!BOUNDARY_CONTROLLERS[@]}; do 
  scp files/boundary_base/boundary-controller-${index}/* core@${BOUNDARY_CONTROLLERS[$index]}:
  ssh -t core@${BOUNDARY_CONTROLLERS[$index]} "sudo cp *.service /etc/systemd/system/; sudo mkdir -p /etc/boundary; sudo mv *.env *.hcl /etc/boundary; sudo systemctl daemon-reload; sudo systemctl enable --now boundary-controller"
done
