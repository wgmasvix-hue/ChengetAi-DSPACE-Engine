#!/usr/bin/env bash
# Create the first DSpace administrator account inside the backend container.
# Reads ADMIN_* defaults from .env; prompts for the password if unset.
set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

ADMIN_EMAIL="${ADMIN_EMAIL:?ADMIN_EMAIL must be set in .env}"
ADMIN_FIRSTNAME="${ADMIN_FIRSTNAME:-Repository}"
ADMIN_LASTNAME="${ADMIN_LASTNAME:-Administrator}"

if [ -z "${ADMIN_PASSWORD:-}" ]; then
  read -r -s -p "Password for ${ADMIN_EMAIL}: " ADMIN_PASSWORD; echo
  read -r -s -p "Confirm password: " CONFIRM; echo
  [ "$ADMIN_PASSWORD" = "$CONFIRM" ] || { echo "Passwords do not match." >&2; exit 1; }
fi

docker compose exec dspace /dspace/bin/dspace create-administrator \
  -e "$ADMIN_EMAIL" \
  -f "$ADMIN_FIRSTNAME" \
  -l "$ADMIN_LASTNAME" \
  -p "$ADMIN_PASSWORD" \
  -c en

echo "Administrator ${ADMIN_EMAIL} created."
