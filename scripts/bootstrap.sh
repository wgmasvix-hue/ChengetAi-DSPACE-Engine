#!/usr/bin/env bash
# Prepare a fresh Ubuntu/Debian server for a ChengetAi DSpace deployment.
# Installs make, curl, and Docker Engine with the compose plugin.
# Run once as root (or with sudo) on a new server:  ./scripts/bootstrap.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo ./scripts/bootstrap.sh" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null; then
  echo "This bootstrap supports Ubuntu/Debian (apt) only." >&2
  echo "Install make and Docker Engine + compose plugin manually, then re-run make up." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing base packages (make, curl, git)..."
apt-get update -q
apt-get install -y -q make curl git ca-certificates

if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  echo "==> Docker with compose plugin already installed: $(docker --version)"
else
  echo "==> Installing Docker Engine + compose plugin..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
fi

echo
echo "Server ready. Next steps:"
echo "  cp .env.example .env             # set POSTGRES_PASSWORD + site URLs"
echo "  cp config/local.cfg.example config/local.cfg"
echo "  make up                          # or make up-prod for production"
echo "  make admin"
