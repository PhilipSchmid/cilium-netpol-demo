#!/usr/bin/env bash

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)

# Wait for the Kubernetes API server to be reachable.
# while ! kubectl get namespace > /dev/null 2>&1;
# do
#   sleep 10
# done