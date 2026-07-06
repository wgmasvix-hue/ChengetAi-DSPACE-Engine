#!/usr/bin/env bash
# Back up the DSpace database and assetstore to ./backups/<UTC timestamp>/.
# Produces: dspace-db.sql.gz (pg_dump) and assetstore.tar.gz (bitstreams).
set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

POSTGRES_DB="${POSTGRES_DB:-dspace}"
POSTGRES_USER="${POSTGRES_USER:-dspace}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="backups/${STAMP}"
mkdir -p "$DEST"

echo "Backing up database ${POSTGRES_DB}..."
docker compose exec -T dspacedb pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  | gzip > "${DEST}/dspace-db.sql.gz"

echo "Backing up assetstore..."
docker compose exec -T dspace tar -czf - -C /dspace assetstore \
  > "${DEST}/assetstore.tar.gz"

echo "Backup complete: ${DEST}"
ls -lh "$DEST"
