#!/bin/bash

set -euo pipefail

# Script to generate Cluster Mesh Certificate Authority certificate and key shared in each cluster
#
# The base64 encoded certificates and keys are used in Helm values file for each Cluster.
#
# Requirements:
#   * openssl
#
# Usage:
#   ./ca-certs.sh up
#
# Cleanup:
#   ./ca-certs.sh down

CILIUM_CA_NAME="cilium-ca"
CILIUM_CA_CRT_FILENAME="${CILIUM_CA_NAME}-crt.pem"
CILIUM_CA_KEY_FILENAME="${CILIUM_CA_NAME}-key.pem"

function down() {
  # Delete the certificates and private keys.
  rm -f "${CILIUM_CA_CRT_FILENAME}" "${CILIUM_CA_KEY_FILENAME}"

}

function info() {
    echo "==> ${1}"
}

function up() {
  # Generate a private key and a certificate for the certificate authority.
  info "Creating a certificate authority..."
  if [[ ! -f "${CILIUM_CA_KEY_FILENAME}" ]];
  then
      openssl genrsa -out "${CILIUM_CA_KEY_FILENAME}" 4096
  fi
  if [[ ! -f "${CILIUM_CA_CRT_FILENAME}" ]];
  then
      openssl req -x509 \
          -days 3650 \
          -key "${CILIUM_CA_KEY_FILENAME}" \
          -new \
          -nodes \
          -out "${CILIUM_CA_CRT_FILENAME}" \
          -sha256 \
          -subj "/CN=${CILIUM_CA_NAME}"
  fi

  # Grab the certificates and private keys into environment variables.
  BASE64_ENCODED_CA_CRT="$(openssl base64 -A < ${CILIUM_CA_CRT_FILENAME})"
  BASE64_ENCODED_CA_KEY="$(openssl base64 -A < ${CILIUM_CA_KEY_FILENAME})"
}

function warn() {
  echo "(!) ${1}"
}

case "${1:-""}" in
  "down")
    down
    ;;
  "up")
    up
    ;;
  *)
    warn "Please specify one of 'up' or 'down'."
    exit 1
    ;;
esac
