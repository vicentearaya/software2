#!/usr/bin/env bash
# Mata y elimina contenedores cleanpool_* (AppArmor / Snap+docker).
#
# Instalar en el servidor:
#   sudo cp scripts/cleanpool-kill-stack.sh /usr/local/bin/cleanpool-kill-stack
#   sudo chmod +x /usr/local/bin/cleanpool-kill-stack
#   echo 'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack' | sudo tee /etc/sudoers.d/cleanpool-dokploy
#
# Dokploy → Advanced → Run Command (sustituir el default):
#   bash -c 'sudo /usr/local/bin/cleanpool-kill-stack && docker compose -p produccin-appdespliegue-hwhkj3 -f ./docker-compose.yml up -d --build --remove-orphans'

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Requiere root: sudo /usr/local/bin/cleanpool-kill-stack" >&2
  exit 1
fi

echo "==> Relajando perfiles AppArmor de Docker (temporal)..."
for profile in docker-default snap.docker.dockerd snap.docker.docker; do
  if command -v aa-status &>/dev/null && aa-status 2>/dev/null | grep -q "$profile"; then
    aa-complain "$profile" 2>/dev/null || true
  fi
done

echo "==> Forzando parada de contenedores CleanPool..."
found=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  found=1
  pid="$(docker inspect -f '{{.State.Pid}}' "$name" 2>/dev/null || echo 0)"
  if [[ -n "$pid" && "$pid" != "0" ]]; then
    echo "  kill -9 pid=$pid ($name)"
    kill -9 "$pid" 2>/dev/null || true
    sleep 0.3
  fi
  if docker rm -f "$name" 2>/dev/null; then
    echo "  eliminado: $name"
  else
    echo "  aviso: no se pudo rm $name" >&2
  fi
done < <(docker ps -a --format '{{.Names}}' | grep -E 'cleanpool_|_cleanpool_' || true)

if [[ "$found" -eq 0 ]]; then
  echo "  (no hay contenedores cleanpool)"
else
  remaining="$(docker ps -a --format '{{.Names}}' | grep -cE 'cleanpool_|_cleanpool_' || true)"
  if [[ "${remaining:-0}" -gt 0 ]]; then
    echo "==> Reiniciando servicio Docker..."
    systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || true
    sleep 3
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      docker rm -f "$name" 2>/dev/null && echo "  eliminado tras restart: $name" || true
    done < <(docker ps -a --format '{{.Names}}' | grep -E 'cleanpool_|_cleanpool_' || true)
  fi
fi

echo "cleanpool-kill-stack: listo para redeploy de Dokploy."
