#!/usr/bin/env bash
# Pre-deploy en Dokploy (desde el clone del repo en el deploy).
#
# Preferido en producción (instalado en el host, sin pedir contraseña):
#   sudo /usr/local/bin/cleanpool-kill-stack
#
# Alternativa si aún no instalaste cleanpool-kill-stack:
#   sudo bash scripts/cleanpool-kill-stack.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -x /usr/local/bin/cleanpool-kill-stack ]]; then
  exec /usr/local/bin/cleanpool-kill-stack
fi

if [[ "${EUID:-}" -ne 0 ]]; then
  exec sudo bash "$SCRIPT_DIR/cleanpool-kill-stack.sh"
fi

exec bash "$SCRIPT_DIR/cleanpool-kill-stack.sh"
