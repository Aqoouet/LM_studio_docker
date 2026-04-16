#!/usr/bin/env bash
set -e

LMS_PORT="${LMS_PORT:-1234}"
LMS_HOST="${LMS_HOST:-0.0.0.0}"
LMS_CONTEXT_LENGTH="${LMS_CONTEXT_LENGTH:-262144}"
LMS_AUTOLOAD="${LMS_AUTOLOAD:-true}"
LMS_MODEL="${LMS_MODEL:-}"
LMS_GET_MODEL="${LMS_GET_MODEL:-}"

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
  if [ -n "${LMS_MODEL}" ]; then
    MODEL_CANDIDATES="${LMS_MODEL}"
  else
    echo "[entrypoint] WARNING: LMS_MODEL is unset. Will try models from 'lms ls --llm' in list order and load the first that succeeds (not necessarily your preferred model). Set LMS_MODEL in .env to fix."
    MODEL_CANDIDATES="$(lms ls --llm | sed -n 's/^[[:space:]]*\([a-zA-Z0-9._][a-zA-Z0-9._-]*-[a-zA-Z0-9._-]*\)[[:space:]].*/\1/p')"
  fi

  if [ -n "${MODEL_CANDIDATES}" ]; then
    MODEL_LOADED=false
    for MODEL_TO_LOAD in ${MODEL_CANDIDATES}; do
      echo "[entrypoint] Auto-loading model '${MODEL_TO_LOAD}' with context length ${LMS_CONTEXT_LENGTH} ..."
      for ATTEMPT in 1 2 3 4 5 6; do
        if lms load "${MODEL_TO_LOAD}" -c "${LMS_CONTEXT_LENGTH}" -y; then
          MODEL_LOADED=true
          break 2
        fi
        echo "[entrypoint] Load attempt ${ATTEMPT}/6 failed for '${MODEL_TO_LOAD}', waiting for model index ..."
        sleep 5
      done
      echo "[entrypoint] Could not auto-load '${MODEL_TO_LOAD}', trying next candidate ..."
    done

    if [ "${MODEL_LOADED}" != "true" ]; then
      echo "[entrypoint] WARNING: failed to auto-load any local model. Server remains running."
    fi
  else
    echo "[entrypoint] No local LLM model found. Skipping auto-load."
  fi
else
  echo "[entrypoint] Auto-load disabled (LMS_AUTOLOAD=${LMS_AUTOLOAD})."
fi

echo "[entrypoint] Server running. Tailing daemon logs (Ctrl+C to stop) ..."
exec lms log stream
