#!/usr/bin/env bash
set -euo pipefail

WORLD_DIR="/opt/valheim/data"
BACKUP_DIR="/opt/valheim/data/backups"
ENV_FILE="/opt/valheim/docker/.env"

# Read active world name from .env
WORLD_NAME=$(grep -E '^WORLD_NAME=' "$ENV_FILE" | cut -d= -f2)
if [[ -z "$WORLD_NAME" ]]; then
  echo "[backup] ERROR: WORLD_NAME not set in $ENV_FILE"
  exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/world_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"
echo "[backup] Backing up world '$WORLD_NAME' at $TIMESTAMP"
tar -czf "$BACKUP_FILE" -C "$WORLD_DIR" $(find "$WORLD_DIR/worlds_local" -maxdepth 1 -name "${WORLD_NAME}.*" -printf "worlds_local/%f\n")
echo "[backup] Written to $BACKUP_FILE"
