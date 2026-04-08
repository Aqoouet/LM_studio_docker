#!/usr/bin/env bash
set -e

LMS_PORT="${LMS_PORT:-1234}"
LMS_HOST="${LMS_HOST:-0.0.0.0}"

echo "[entrypoint] Starting lms daemon ..."
lms daemon up

echo "[entrypoint] Waiting for daemon to initialize ..."
sleep 5

echo "[entrypoint] Starting server on ${LMS_HOST}:${LMS_PORT} ..."
lms server start -p "${LMS_PORT}" --bind "${LMS_HOST}"

echo "[entrypoint] Server running. Tailing daemon logs (Ctrl+C to stop) ..."
exec lms log stream
