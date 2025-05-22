#!/bin/bash
set -euo pipefail

# This script starts Nextcloud AIO together with a Caddy reverse proxy.
# Provide the domain via the NC_DOMAIN environment variable or as the first argument.

NC_DOMAIN="${1:-${NC_DOMAIN:-}}"
if [ -z "$NC_DOMAIN" ]; then
    echo "Usage: NC_DOMAIN=<your-domain> $0" >&2
    exit 1
fi

# Create Caddyfile configuration
CADDY_DIR="$(pwd)/caddy"
mkdir -p "$CADDY_DIR"
cat > "$CADDY_DIR/Caddyfile" <<CADDY
$NC_DOMAIN {
    reverse_proxy localhost:11000
}

$NC_DOMAIN:8443 {
    reverse_proxy https://localhost:8080 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
CADDY

# Ensure docker volumes exist
for vol in caddy_data caddy_config caddy_certs nextcloud_aio_mastercontainer; do
    docker volume inspect "$vol" >/dev/null 2>&1 || docker volume create "$vol" >/dev/null
done

# Start Nextcloud mastercontainer if not running
if ! docker ps --format '{{.Names}}' | grep -q '^nextcloud-aio-mastercontainer$'; then
    docker run -d --init --sig-proxy=false \
        --name nextcloud-aio-mastercontainer \
        --restart always \
        --publish 8080:8080 \
        --env APACHE_PORT=11000 \
        --env APACHE_IP_BINDING=127.0.0.1 \
        --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
        --volume /var/run/docker.sock:/var/run/docker.sock:ro \
        ghcr.io/nextcloud-releases/all-in-one:latest
fi

# Start Caddy container if not running
if ! docker ps --format '{{.Names}}' | grep -q '^caddy$'; then
    docker run -d --name caddy --restart always \
        --network host \
        -v caddy_certs:/certs \
        -v caddy_config:/config \
        -v caddy_data:/data \
        -v "$CADDY_DIR/Caddyfile":/etc/caddy/Caddyfile \
        caddy:alpine
fi

cat <<INFO
Nextcloud AIO is starting.
Access Nextcloud at: https://$NC_DOMAIN
AIO interface: https://$NC_DOMAIN:8443
INFO
