#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

if [[ -n "${VAULT_CONFIGURATION_FILE_OBJECT_PATH}" ]]; then
  echo "Fetching vault configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${VAULT_CONFIGURATION_FILE_OBJECT_PATH}" \
    /vault/config/config.hcl.tpl
  envsubst \
    < /vault/config/config.hcl.tpl \
    > /vault/config/config.hcl
else
  var_name="VAULT_CONFIGURATION_FILE_OBJECT_PATH"
  echo "No ${var_name} provided. Using default configuration."
fi
