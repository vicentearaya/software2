#!/usr/bin/env bash
# Mata y elimina contenedores cleanpool_* (AppArmor / Snap+docker).
# Instalar una vez en el servidor:
#   sudo cp scripts/cleanpool-kill-stack.sh /usr/local/bin/cleanpool-kill-stack
#   sudo chmod +x /usr/local/bin/cleanpool-kill-stack
#   echo 'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack' | sudo tee /etc/sudoers.d/cleanpool-dokploy
#
# Dokploy → Advanced → Pre Deploy Command:
#   sudo /usr/local/bin/cleanpool-kill-stack

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Requiere root: sudo /usr/local/bin/cleanpool-kill-stack" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/force-remove-cleanpool.sh
source "$SCRIPT_DIR/lib/force-remove-cleanpool.sh"
force_remove_cleanpool_containers

echo "cleanpool-kill-stack: listo para redeploy de Dokploy."
