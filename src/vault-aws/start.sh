#!/usr/bin/env bash

LISTENER_TCP=""

if [ -n "$TLS_DISABLE" ]; then
  LISTENER_TCP=$(cat << EOF
listener "tcp" {
  tls_disable = 1
}
EOF
)
fi

if [ ! -f "/vault/config/config.hcl" ]; then
  cat << EOF > /vault/config/config.hcl
  storage "inmem" {}

  $LISTENER_TCP

  disable_mlock = true
EOF
fi

/usr/local/bin/docker-vault-entrypoint.sh server
