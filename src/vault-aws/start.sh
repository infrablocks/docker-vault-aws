#!/usr/bin/env bash

# write config to /vault/config/something.hcl
cat << EOF > /vault/config/config.hcl
storage "inmem" {}

listener "tcp" {
  tls_disable = 1
}

disable_mlock = true
EOF

/usr/local/bin/docker-vault-entrypoint.sh server
