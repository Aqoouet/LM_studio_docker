#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure .env exists
if [ ! -f .env ]; then
    echo "[start] .env not found — copying from .env.example"
    cp .env.example .env
fi

# Warn if swap is active (degrades inference speed for large models)
SWAP_TOTAL=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
SWAP_FREE=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
if [ "$SWAP_USED" -gt 0 ]; then
    echo "[start] WARNING: ${SWAP_USED} kB swap in use. Disable for best inference speed:"
    echo "          sudo swapoff -a"
fi

# mlockall is enabled inside the container via:
#   cap_add: IPC_LOCK  +  ulimits.memlock: -1  (set in docker-compose.yml)
echo "[start] Starting stack (mlock: IPC_LOCK cap + memlock=-1 ulimit active) ..."

# Use 'up' not 'restart' so .env changes are always picked up
docker compose up -d --build

echo "[start] Waiting for lmstudio to become healthy ..."
for i in $(seq 1 30); do
    STATUS=$(docker inspect lmstudio --format '{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    if [ "$STATUS" = "healthy" ]; then
        echo "[start] lmstudio healthy."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[start] WARNING: not healthy after 5 min. Check: docker logs lmstudio"
        exit 1
    fi
    sleep 10
done

echo "[start] Loaded models:"
docker exec lmstudio lms ps

WEBUI_PORT=$(grep '^WEBUI_PORT=' .env | cut -d= -f2)
echo "[start] Open WebUI: http://$(hostname -I | awk '{print $1}'):${WEBUI_PORT:-3000}"
