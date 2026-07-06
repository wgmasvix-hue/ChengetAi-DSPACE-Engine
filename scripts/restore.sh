#!/usr/bin/env bash
# Restore a backup produced by scripts/backup.sh.
# Usage: ./scripts/restore.sh backups/<timestamp>
# WARNING: replaces the current database contents and assetstore.
set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

BACKUP_DIR="${1:?usage: $0 backups/<timestamp>}"
[ -f "${BACKUP_DIR}/dspace-db.sql.gz" ] || { echo "No dspace-db.sql.gz in ${BACKUP_DIR}" >&2; exit 1; }
[ -f "${BACKUP_DIR}/assetstore.tar.gz" ] || { echo "No assetstore.tar.gz in ${BACKUP_DIR}" >&2; exit 1; }

POSTGRES_DB="${POSTGRES_DB:-dspace}"
POSTGRES_USER="${POSTGRES_USER:-dspace}"

read -r -p "This OVERWRITES database '${POSTGRES_DB}' and the assetstore. Continue? [y/N] " ANSWER
[ "${ANSWER,,}" = "y" ] || { echo "Aborted."; exit 1; }

echo "Stopping backend so the database can be replaced..."
docker compose stop dspace dspace-angular

echo "Restoring database..."
docker compose exec -T dspacedb psql -U "$POSTGRES_USER" -d postgres -c \
  "DROP DATABASE IF EXISTS ${POSTGRES_DB}; CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"
gunzip -c "${BACKUP_DIR}/dspace-db.sql.gz" \
  | docker compose exec -T dspacedb psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

echo "Restoring assetstore..."
docker compose start dspace
docker compose exec -T dspace bash -c "rm -rf /dspace/assetstore/* && tar -xzf - -C /dspace" \
  < "${BACKUP_DIR}/assetstore.tar.gz"

echo "Restarting stack and reindexing discovery..."
docker compose up -d
docker compose exec dspace /dspace/bin/dspace index-discovery -b

echo "Restore complete from ${BACKUP_DIR}"
