#!/usr/bin/env bash
# Helper: mata procesos de contenedores cleanpool_* y los elimina.
# Uso: source scripts/lib/force-remove-cleanpool.sh && force_remove_cleanpool_containers

force_remove_cleanpool_containers() {
  if [[ "${EUID:-}" -ne 0 ]]; then
    echo "force_remove_cleanpool_containers requiere root (sudo)." >&2
    return 1
  fi

  echo "==> Relajando perfiles AppArmor de Docker (temporal)..."
  for profile in docker-default snap.docker.dockerd snap.docker.docker; do
    if command -v aa-status &>/dev/null && aa-status 2>/dev/null | grep -q "$profile"; then
      aa-complain "$profile" 2>/dev/null || true
    fi
  done

  echo "==> Forzando parada de contenedores CleanPool..."
  local found=0 name pid remaining
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
    return 0
  fi

  remaining="$(docker ps -a --format '{{.Names}}' | grep -cE 'cleanpool_|_cleanpool_' || true)"
  if [[ "${remaining:-0}" -gt 0 ]]; then
    echo "==> Reiniciando servicio Docker..."
    systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || true
    sleep 2
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      docker rm -f "$name" 2>/dev/null && echo "  eliminado tras restart: $name" || true
    done < <(docker ps -a --format '{{.Names}}' | grep -E 'cleanpool_|_cleanpool_' || true)
  fi
}
