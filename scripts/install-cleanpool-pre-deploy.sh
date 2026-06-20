#!/usr/bin/env bash
# Instala cleanpool-pre-deploy en /usr/local/bin (una vez por servidor).
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${EUID:-}" -ne 0 ]]; then
  exec sudo bash "$0"
fi

cp scripts/cleanpool-pre-deploy.sh /usr/local/bin/cleanpool-pre-deploy
chmod +x /usr/local/bin/cleanpool-pre-deploy

SUDOERS_FILE=/etc/sudoers.d/cleanpool-dokploy
if [[ -f "$SUDOERS_FILE" ]]; then
  if ! grep -q 'cleanpool-pre-deploy' "$SUDOERS_FILE"; then
    echo 'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-pre-deploy' >>"$SUDOERS_FILE"
  fi
else
  printf '%s\n' \
    'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack' \
    'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-pre-deploy' \
    >"$SUDOERS_FILE"
fi
chmod 440 "$SUDOERS_FILE"

echo "Instalado: /usr/local/bin/cleanpool-pre-deploy"
