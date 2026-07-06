#!/usr/bin/env bash
# =============================================================================
# ChengetAi DSpace one-line installer
#
#   curl -fsSL https://raw.githubusercontent.com/wgmasvix-hue/ChengetAi-DSPACE-Engine/main/install.sh | sudo bash
#
# Clones the deployment template into /opt/chengetai (override with
# CHENGETAI_HOME), installs prerequisites (make, Docker + compose plugin),
# and links the `chengetai` CLI into /usr/local/bin.
# =============================================================================
set -euo pipefail

REPO_URL="${CHENGETAI_REPO:-https://github.com/wgmasvix-hue/ChengetAi-DSPACE-Engine.git}"
INSTALL_DIR="${CHENGETAI_HOME:-/opt/chengetai}"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: run as root, e.g.  curl -fsSL .../install.sh | sudo bash" >&2
  exit 1
fi

if ! command -v git >/dev/null; then
  echo "==> Installing git..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q && apt-get install -y -q git
fi

if [ -d "${INSTALL_DIR}/.git" ]; then
  echo "==> Updating existing installation in ${INSTALL_DIR}"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "==> Cloning deployment template into ${INSTALL_DIR}"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

"${INSTALL_DIR}/scripts/bootstrap.sh"

ln -sf "${INSTALL_DIR}/bin/chengetai" /usr/local/bin/chengetai

echo
echo "ChengetAi deploy CLI installed ($(chengetai version))."
echo
echo "Start a deployment with:"
echo "  chengetai deploy"
