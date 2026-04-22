#!/usr/bin/env bash
set -e

LMS_PORT="${LMS_PORT:-1234}"
LMS_HOST="${LMS_HOST:-0.0.0.0}"
LMS_CONTEXT_LENGTH="${LMS_CONTEXT_LENGTH:-262144}"
LMS_AUTOLOAD="${LMS_AUTOLOAD:-true}"
LMS_MAX_CONCURRENT="${LMS_MAX_CONCURRENT:-10}"
LMS_GET_MODEL="${LMS_GET_MODEL:-}"
# LMS_MODELS: space-separated list of model keys to autoload
# e.g. "qwen/qwen3-4b-2507 qwen3.6-35b-a3b"
# Falls back to LMS_MODEL (single model, legacy) if LMS_MODELS is unset.
LMS_MODELS="${LMS_MODELS:-${LMS_MODEL:-}}"
# LMS_PLATFORMS: comma-separated list for --docker-compatible-platforms
# e.g. "cuda" or "cpu-only" or "cuda,cpu-only"
LMS_PLATFORMS="${LMS_PLATFORMS:-cpu-only}"

FILER_DIR="${FILER_DIR:-/lmstudio-filer}"

if [ ! -x "${FILER_DIR}/bin/lms" ]; then
  echo "[entrypoint] ERROR: lms binary not found at ${FILER_DIR}/bin/lms"
  echo "[entrypoint] Install LM Studio on the host filer first, then mount it to ${FILER_DIR}"
  exit 1
fi

# Link binaries + models from CIFS filer into the local (writable) .lmstudio volume.
# CIFS with cifsacl prevents container writes inside filer dirs; local volume has no such restriction.
echo "[entrypoint] Linking filer dirs into ${LMS_INSTALL_DIR} ..."
mkdir -p "${LMS_INSTALL_DIR}"
for LINK in bin llmster models; do
  if [ ! -e "${LMS_INSTALL_DIR}/${LINK}" ]; then
    ln -s "${FILER_DIR}/${LINK}" "${LMS_INSTALL_DIR}/${LINK}"
    echo "[entrypoint]   linked ${LINK}"
  fi
done

# Find the llmster daemon binary under filer (version directory may change)
LLMSTER_BIN=$(find "${FILER_DIR}/llmster" -maxdepth 2 -name "llmster" -type f 2>/dev/null | head -1)
if [ -z "${LLMSTER_BIN}" ] || [ ! -x "${LLMSTER_BIN}" ]; then
  echo "[entrypoint] ERROR: llmster binary not found under ${LMS_INSTALL_DIR}/llmster/"
  exit 1
fi
echo "[entrypoint] Found llmster at: ${LLMSTER_BIN}"

# Build platform args array
PLATFORM_ARGS=()
IFS=',' read -ra PLATFORMS <<< "${LMS_PLATFORMS}"
for P in "${PLATFORMS[@]}"; do
  PLATFORM_ARGS+=(--docker-compatible-platforms "${P}")
done

echo "[entrypoint] Starting llmster daemon (platforms: ${LMS_PLATFORMS}) ..."
"${LLMSTER_BIN}" "${PLATFORM_ARGS[@]}" &
LLMSTER_PID=$!

echo "[entrypoint] Waiting for daemon to initialize (pid ${LLMSTER_PID}) ..."
for I in $(seq 1 30); do
  if lms status 2>/dev/null | grep -qi "running\|connected\|server"; then
    echo "[entrypoint] Daemon ready after ${I}s."
    break
  fi
  if ! kill -0 "${LLMSTER_PID}" 2>/dev/null; then
    echo "[entrypoint] ERROR: llmster process exited unexpectedly."
    exit 1
  fi
  sleep 2
done

if [ -n "${LMS_GET_MODEL}" ]; then
  echo "[entrypoint] Ensuring model '${LMS_GET_MODEL}' is downloaded ..."
  for ATTEMPT in 1 2 3 4 5 6; do
    if lms get "${LMS_GET_MODEL}"; then
      break
    fi
    if [ "${ATTEMPT}" -eq 6 ]; then
      echo "[entrypoint] WARNING: failed to download '${LMS_GET_MODEL}'. Continuing startup."
      break
    fi
    echo "[entrypoint] Download attempt ${ATTEMPT}/6 failed for '${LMS_GET_MODEL}', retrying ..."
    sleep 5
  done
fi

echo "[entrypoint] Starting server on ${LMS_HOST}:${LMS_PORT} ..."
lms server start -p "${LMS_PORT}" --bind "${LMS_HOST}"

if [ "${LMS_AUTOLOAD}" = "true" ]; then
  if [ -z "${LMS_MODELS}" ]; then
    echo "[entrypoint] WARNING: LMS_MODELS is unset. Skipping autoload. Set LMS_MODELS in .env."
  else
    for MODEL_TO_LOAD in ${LMS_MODELS}; do
      echo "[entrypoint] Auto-loading '${MODEL_TO_LOAD}' (context=${LMS_CONTEXT_LENGTH}, parallel=${LMS_MAX_CONCURRENT}) ..."
      LOADED=false
      for ATTEMPT in 1 2 3 4 5 6; do
        if lms load "${MODEL_TO_LOAD}" \
            -c "${LMS_CONTEXT_LENGTH}" \
            --parallel "${LMS_MAX_CONCURRENT}" \
            -y; then
          LOADED=true
          break
        fi
        echo "[entrypoint] Load attempt ${ATTEMPT}/6 failed for '${MODEL_TO_LOAD}', retrying ..."
        sleep 5
      done
      if [ "${LOADED}" != "true" ]; then
        echo "[entrypoint] WARNING: failed to auto-load '${MODEL_TO_LOAD}'. Continuing."
      fi
    done
  fi
else
  echo "[entrypoint] Auto-load disabled (LMS_AUTOLOAD=${LMS_AUTOLOAD})."
fi

echo "[entrypoint] Server running. Tailing daemon logs (Ctrl+C to stop) ..."
exec lms log stream
