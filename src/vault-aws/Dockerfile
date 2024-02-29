FROM hashicorp/vault:1.15.6 as vault

FROM infrablocks/alpine-aws-s3-config:0.23.0

RUN addgroup vault && \
    adduser -S -G vault vault

RUN apk add --no-cache ca-certificates libcap su-exec tzdata gettext && \
        mkdir -p /vault/logs && \
        mkdir -p /vault/file && \
        mkdir -p /vault/config && \
        chown -R vault:vault /vault

COPY --from=vault /bin/vault /bin/vault
COPY --from=vault /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

VOLUME /vault/logs
VOLUME /vault/file

EXPOSE 8200

COPY --from=vault /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-vault-entrypoint.sh

COPY start.sh /usr/local/bin/start.sh

COPY scripts/fetch-configuration.sh /usr/local/bin/fetch-configuration.sh
RUN ["chmod", "+x", "/usr/local/bin/fetch-configuration.sh"]

ENV FETCH_SECRETS_FILES_SCRIPT_PATH=/usr/local/bin/fetch-configuration.sh
ENV STARTUP_SCRIPT_PATH=/usr/local/bin/start.sh
