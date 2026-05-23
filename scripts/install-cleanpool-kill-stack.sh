#!/usr/bin/env bash
# Instala cleanpool-kill-stack en /usr/local/bin (una vez por servidor).
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${EUID:-}" -ne 0 ]]; then
  exec sudo bash "$0"
fi
cp scripts/cleanpool-kill-stack.sh /usr/local/bin/cleanpool-kill-stack
chmod +x /usr/local/bin/cleanpool-kill-stack
echo 'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack' > /etc/sudoers.d/cleanpool-dokploy
chmod 440 /etc/sudoers.d/cleanpool-dokploy
echo "Instalado: /usr/local/bin/cleanpool-kill-stack"
