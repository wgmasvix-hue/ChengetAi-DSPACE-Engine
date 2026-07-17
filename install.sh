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

# Is a directory a clone of this template?
is_template_clone() {
  [ -d "$1/.git" ] && git -C "$1" remote get-url origin 2>/dev/null | grep -qi "ChengetAi-DSPACE-Engine"
}

if is_template_clone "$INSTALL_DIR"; then
  echo "==> Updating existing installation in ${INSTALL_DIR}"
  git -C "$INSTALL_DIR" pull --ff-only
elif [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
  # INSTALL_DIR exists but holds other content (e.g. it's a projects folder).
  # Use or create a template clone inside it instead of failing.
  INSTALL_DIR="${INSTALL_DIR}/ChengetAi-DSPACE-Engine"
  if is_template_clone "$INSTALL_DIR"; then
    echo "==> Updating existing installation in ${INSTALL_DIR}"
    git -C "$INSTALL_DIR" checkout main
    git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "==> Install dir is occupied; cloning deployment template into ${INSTALL_DIR}"
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
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
