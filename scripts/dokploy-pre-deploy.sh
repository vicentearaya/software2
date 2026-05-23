#!/usr/bin/env bash
# Pre-deploy en Dokploy: libera nombres cleanpool_* (requiere root).
#
# En Dokploy → Advanced → Pre Deploy Command:
#   sudo KEEP_VOLUMES=1 bash scripts/dokploy-pre-deploy.sh

set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT_DIR="$(dirname "$0")"

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Ejecutando con sudo..."
  exec sudo KEEP_VOLUMES=1 bash "$SCRIPT_DIR/dokploy-pre-deploy.sh"
fi

# shellcheck source=lib/force-remove-cleanpool.sh
source "$SCRIPT_DIR/lib/force-remove-cleanpool.sh"
force_remove_cleanpool_containers

docker compose down --remove-orphans 2>/dev/null || true

echo "Pre-deploy: contenedores CleanPool liberados (volúmenes conservados)."
