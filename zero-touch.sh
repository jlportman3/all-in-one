#!/bin/bash
set -euo pipefail

# Install required packages on a fresh Ubuntu system
install_packages() {
    if ! command -v curl >/dev/null 2>&1; then
        sudo apt update -y
        sudo apt install -y curl
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        sudo apt update -y
        sudo apt install -y python3
    fi

    if ! command -v docker >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com | sudo sh
    fi

    if ! docker compose version >/dev/null 2>&1; then
        sudo apt install -y docker-compose-plugin
    fi
}

install_packages

# This script starts Nextcloud AIO together with a Caddy reverse proxy.
# If NC_DOMAIN is not set in the environment or as the first argument,
# the script will prompt for it and store the value inside a `.env` file
# located in the current working directory.

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

NC_DOMAIN="${1:-${NC_DOMAIN:-}}"
if [ -z "$NC_DOMAIN" ]; then
    read -rp "Enter the domain for Nextcloud: " NC_DOMAIN
fi

if [ -z "$NC_DOMAIN" ]; then
    echo "No domain provided" >&2
    exit 1
fi

# Persist the domain in the .env file
if [ -f "$ENV_FILE" ] && grep -q '^NC_DOMAIN=' "$ENV_FILE"; then
    sed -i "s/^NC_DOMAIN=.*/NC_DOMAIN=$NC_DOMAIN/" "$ENV_FILE"
else
    echo "NC_DOMAIN=$NC_DOMAIN" >> "$ENV_FILE"
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
