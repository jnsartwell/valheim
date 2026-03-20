#!/usr/bin/env bash
set -euo pipefail
echo "[stop] Stopping Valheim server (graceful, 60s timeout)..."
docker compose -f /opt/valheim/scripts/compose.yaml --env-file /opt/valheim/docker/.env stop
echo "[stop] Server stopped."
