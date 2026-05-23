#!/usr/bin/env bash
# Publica el panel Dokploy en el puerto 8886 (contenedor sigue en 3000).
# Uso: sudo bash scripts/configure-dokploy-port-8886.sh

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo bash $0"
  exit 1
fi

if ! docker service ls --format '{{.Name}}' | grep -qx dokploy; then
  echo "No existe el servicio swarm 'dokploy'. ¿Está instalado Dokploy?"
  exit 1
fi

echo "==> Publicando Dokploy en 8886 (target 3000)..."
docker service update dokploy \
  --publish-add published=8886,target=3000,mode=host

# Quitar publicación en 3000 del host si existe (puede fallar si ya no está).
docker service update dokploy --publish-rm 3000 2>/dev/null || true

sleep 5
if curl -sf -o /dev/null --connect-timeout 3 http://127.0.0.1:8886/; then
  echo "OK: Dokploy responde en http://127.0.0.1:8886"
else
  echo "Aviso: comprueba con: docker service ps dokploy && curl -I http://127.0.0.1:8886/"
  exit 1
fi
