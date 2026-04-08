#!/usr/bin/env bash
# Usage:
#   ./scripts/download-model.sh <model-name>
#   ./scripts/download-model.sh lmstudio-community/Qwen3.5-35B-A3B-GGUF
#
# The model will be downloaded into the container's /root/.lmstudio/models volume.

set -e

CONTAINER="${CONTAINER:-lmstudio}"
MODEL="${1}"

if [[ -z "${MODEL}" ]]; then
  echo "Usage: $0 <model-name>"
  echo ""
  echo "Examples:"
  echo "  $0 lmstudio-community/Qwen3.5-35B-A3B-GGUF"
  echo ""
  echo "Browse models at: https://lmstudio.ai/models"
  exit 1
fi

echo "[download-model] Downloading '${MODEL}' into container '${CONTAINER}' ..."
docker exec -it "${CONTAINER}" lms get "${MODEL}"
echo "[download-model] Done. Model is available in the persistent volume."
