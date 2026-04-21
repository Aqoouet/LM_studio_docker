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

echo "[entrypoint] Starting lms daemon ..."
lms daemon up

echo "[entrypoint] Waiting for daemon to initialize ..."
sleep 5

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
