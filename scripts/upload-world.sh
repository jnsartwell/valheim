#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --db <path> --fwl <path> --host <hostname>"
  echo ""
  echo "Upload world files to the Valheim server volume."
  echo ""
  echo "  --db    Path to the .db world save file"
  echo "  --fwl   Path to the .fwl world metadata file"
  echo "  --host  Server hostname or IP"
  exit 1
}

DB_PATH=""
FWL_PATH=""
HOST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db)  DB_PATH="$2"; shift 2 ;;
    --fwl) FWL_PATH="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$DB_PATH" || -z "$FWL_PATH" || -z "$HOST" ]]; then
  echo "Error: All flags (--db, --fwl, --host) are required."
  usage
fi

# Validate files exist
if [[ ! -f "$DB_PATH" ]]; then
  echo "Error: DB file not found: $DB_PATH"
  exit 1
fi
if [[ ! -f "$FWL_PATH" ]]; then
  echo "Error: FWL file not found: $FWL_PATH"
  exit 1
fi

# Validate extensions
if [[ "$DB_PATH" != *.db ]]; then
  echo "Error: DB file must have .db extension: $DB_PATH"
  exit 1
fi
if [[ "$FWL_PATH" != *.fwl ]]; then
  echo "Error: FWL file must have .fwl extension: $FWL_PATH"
  exit 1
fi

# Validate matching base names
DB_NAME=$(basename "$DB_PATH" .db)
FWL_NAME=$(basename "$FWL_PATH" .fwl)
if [[ "$DB_NAME" != "$FWL_NAME" ]]; then
  echo "Error: World names don't match: '$DB_NAME' (.db) vs '$FWL_NAME' (.fwl)"
  exit 1
fi

WORLD_NAME="$DB_NAME"
DEST="/mnt/valheim-world/worlds_local"

echo "Uploading world '$WORLD_NAME' to $HOST..."
scp "$DB_PATH" "$FWL_PATH" "root@${HOST}:${DEST}/"
echo "Upload complete."
echo ""
echo "Next steps:"
echo "  1. Set the WORLD_NAME GitHub variable to '$WORLD_NAME' (if different from current)"
echo "  2. Open a PR to trigger a deploy (or use Manual Deploy)"
echo "  3. Merge to activate the world"
