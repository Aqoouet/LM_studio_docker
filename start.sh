#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Recreate .env on every start from .env.example
echo "[start] Recreating .env from .env.example"
cp .env.example .env

set -a
source .env
set +a

PRIMARY_MODELS_ROOT="${LMS_MODELS_ROOT_PRIMARY:-${PRIMARY_MODELS_ROOT:-/expert_scratch/lmstudio-models}}"
FALLBACK_MODELS_ROOT="${LMS_MODELS_ROOT_FALLBACK:-${FALLBACK_MODELS_ROOT:-/filer/users/rymax1e/lmstudio-models}}"
MODEL1_SUBDIR="${LMS_MODEL1_SUBDIR:-${MODEL1_SUBDIR:-lmstudio-community/Qwen3.6-35B-A3B-GGUF}}"
MODEL2_SUBDIR="${LMS_MODEL2_SUBDIR:-${MODEL2_SUBDIR:-lmstudio-community/Qwen3-4B-Instruct-2507-GGUF}}"

resolve_model_path() {
    local subdir="$1"
    local candidate
    local model_file
    local selected=""

    for candidate in "${PRIMARY_MODELS_ROOT}/${subdir}" "${FALLBACK_MODELS_ROOT}/${subdir}"; do
        [ -d "${candidate}" ] || continue
        for model_file in "${candidate}"/*.gguf; do
            [ -e "${model_file}" ] || continue
            case "$(basename "${model_file}")" in
                mmproj-*|*mmproj*)
                    continue
                    ;;
            esac
            selected="${model_file}"
            break
        done

        if [ -z "${selected}" ]; then
            selected="$(ls -1 "${candidate}"/*.gguf 2>/dev/null | head -n 1 || true)"
        fi

        if [ -n "${selected}" ]; then
            if [[ "${candidate}" == "${PRIMARY_MODELS_ROOT}"* ]]; then
                printf "/models_primary/%s/%s" "${subdir}" "$(basename "${selected}")"
            else
                printf "/models_fallback/%s/%s" "${subdir}" "$(basename "${selected}")"
            fi
            return 0
        fi
    done

    return 1
}

MODEL1_CONTAINER_PATH="$(resolve_model_path "${MODEL1_SUBDIR}" || true)"
MODEL2_CONTAINER_PATH="$(resolve_model_path "${MODEL2_SUBDIR}" || true)"

API_PORT_MODEL1_EFFECTIVE="${LMS_PORT_MODEL1:-${API_PORT_MODEL1:-1234}}"
API_PORT_MODEL2_EFFECTIVE="${LMS_PORT_MODEL2:-${API_PORT_MODEL2:-1235}}"
MAX_CONCURRENT_EFFECTIVE="${LMS_MAX_CONCURRENT:-${MAX_CONCURRENT:-4}}"
THREADS_EFFECTIVE="${LMS_THREADS:-${THREADS:-16}}"
CTX_SIZE_EFFECTIVE="${LMS_CTX_SIZE:-${CTX_SIZE:-4096}}"
MEM_LIMIT_EFFECTIVE="${LMS_CONTAINER_MAX_RAM:-${CONTAINER_MAX_RAM:-120g}}"

if [ -z "${MODEL1_CONTAINER_PATH}" ]; then
    echo "[start] ERROR: no GGUF found for model1 in:"
    echo "        ${PRIMARY_MODELS_ROOT}/${MODEL1_SUBDIR}"
    echo "        ${FALLBACK_MODELS_ROOT}/${MODEL1_SUBDIR}"
    exit 1
fi

if [ -z "${MODEL2_CONTAINER_PATH}" ]; then
    echo "[start] ERROR: no GGUF found for model2 in:"
    echo "        ${PRIMARY_MODELS_ROOT}/${MODEL2_SUBDIR}"
    echo "        ${FALLBACK_MODELS_ROOT}/${MODEL2_SUBDIR}"
    exit 1
fi

# Block startup if swap is currently in use.
SWAP_TOTAL=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
SWAP_FREE=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
if [ "${SWAP_USED}" -gt 0 ]; then
    echo "[start] ERROR: swap is in use (${SWAP_USED} kB). Disable swap usage before starting."
    echo "[start] Hint: sudo swapoff -a"
    exit 1
fi

export LMS_MODEL1_CONTAINER_PATH="${MODEL1_CONTAINER_PATH}"
export LMS_MODEL2_CONTAINER_PATH="${MODEL2_CONTAINER_PATH}"

echo "[start] Effective configuration:"
echo "        LMS_IMAGE=${LMS_IMAGE:-ghcr.io/ggml-org/llama.cpp:server}"
echo "        LMS_MODELS_ROOT_PRIMARY=${PRIMARY_MODELS_ROOT}"
echo "        LMS_MODELS_ROOT_FALLBACK=${FALLBACK_MODELS_ROOT}"
echo "        LMS_MODEL1_SUBDIR=${MODEL1_SUBDIR}"
echo "        LMS_MODEL2_SUBDIR=${MODEL2_SUBDIR}"
echo "        LMS_MODEL1_CONTAINER_PATH=${MODEL1_CONTAINER_PATH}"
echo "        LMS_MODEL2_CONTAINER_PATH=${MODEL2_CONTAINER_PATH}"
echo "        LMS_PORT_MODEL1=${API_PORT_MODEL1_EFFECTIVE}"
echo "        LMS_PORT_MODEL2=${API_PORT_MODEL2_EFFECTIVE}"
echo "        LMS_MAX_CONCURRENT=${MAX_CONCURRENT_EFFECTIVE}"
echo "        LMS_THREADS=${THREADS_EFFECTIVE}"
echo "        LMS_CTX_SIZE=${CTX_SIZE_EFFECTIVE}"
echo "        LMS_CONTAINER_MAX_RAM=${MEM_LIMIT_EFFECTIVE}"

echo "[start] Starting llama.cpp API container (CPU-only) ..."
docker compose up -d --remove-orphans

echo "[start] Waiting for llama-api-qwen36 and llama-api-qwen34 to become healthy ..."
for i in $(seq 1 30); do
    STATUS1=$(docker inspect llama-api-qwen36 --format '{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    STATUS2=$(docker inspect llama-api-qwen34 --format '{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    if [ "$STATUS1" = "healthy" ] && [ "$STATUS2" = "healthy" ]; then
        echo "[start] both API containers are healthy."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[start] WARNING: services not healthy after 5 min."
        echo "[start] Check logs:"
        echo "        docker logs --tail 120 llama-api-qwen36"
        echo "        docker logs --tail 120 llama-api-qwen34"
        exit 1
    fi
    sleep 10
done

echo "[start] API model endpoints:"
API1="http://127.0.0.1:${API_PORT_MODEL1_EFFECTIVE}"
API2="http://127.0.0.1:${API_PORT_MODEL2_EFFECTIVE}"
curl -fsS "${API1}/v1/models" || true
curl -fsS "${API2}/v1/models" || true

echo "[start] Model1 path: ${MODEL1_CONTAINER_PATH}"
echo "[start] Model2 path: ${MODEL2_CONTAINER_PATH}"
echo "[start] API #1: http://$(hostname -I | awk '{print $1}'):${API_PORT_MODEL1_EFFECTIVE}/v1"
echo "[start] API #2: http://$(hostname -I | awk '{print $1}'):${API_PORT_MODEL2_EFFECTIVE}/v1"
