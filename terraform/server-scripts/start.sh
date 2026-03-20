#!/usr/bin/env bash
set -euo pipefail
echo "[start] Bringing up Valheim server..."
docker compose -f /opt/valheim/scripts/compose.yaml --env-file /opt/valheim/docker/.env up -d
echo "[start] Done. Check logs with: docker logs -f valheim"
