# Zero Touch Setup

The `zero-touch.sh` script starts Nextcloud AIO with a bundled Caddy reverse proxy. It assumes a fresh Ubuntu installation and will automatically install a few dependencies if they are missing.

## Requirements
- `curl`
- `python3`
- Docker engine
- Docker Compose plugin

When the script is executed it verifies these packages and installs them using `apt` and the official Docker installation script if necessary.

## Usage
Run the script and provide your domain when prompted. You can also set the
domain via the `NC_DOMAIN` environment variable or pass it as the first
argument:

```bash
NC_DOMAIN=example.com ./zero-touch.sh
```

After the installation the script launches the mastercontainer and a Caddy container. Visit the printed URLs to continue the setup.
