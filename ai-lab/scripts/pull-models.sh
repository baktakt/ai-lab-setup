#!/usr/bin/env bash
# Pull starter models into Ollama.
# Requires the ollama container to be running: ai-start.sh first.
set -euo pipefail

CONTAINER="ai-ollama"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Error: $CONTAINER is not running."
  echo "Start the stack first: ~/ai-lab/scripts/ai-start.sh"
  exit 1
fi

pull() {
  local model="$1"
  local output wanted_digest wanted_blob

  echo ""
  echo "Pulling: $model"

  set +e
  output="$(docker exec "$CONTAINER" ollama pull "$model" 2>&1)"
  local status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    printf '%s\n' "$output"
    return 0
  fi

  if [[ "$output" =~ digest\ mismatch.*want\ (sha256:[0-9a-f]+) ]]; then
    wanted_digest="${BASH_REMATCH[1]}"
    wanted_blob="/root/.ollama/models/blobs/${wanted_digest/:/-}"

    printf '%s\n' "$output"
    echo "Detected corrupted Ollama blob: $wanted_digest"
    echo "Removing $wanted_blob and retrying once..."

    docker exec "$CONTAINER" rm -f "$wanted_blob"
    docker exec "$CONTAINER" ollama pull "$model"
    return
  fi

  printf '%s\n' "$output" >&2
  return "$status"
}

# General reasoning (fast)
pull llama3.1:8b

# Code / reasoning (main workhorse)
pull qwen2.5-coder:14b

# Good all-rounder
pull mistral-nemo

# Embeddings (required for Qdrant/RAG)
pull nomic-embed-text

echo ""
echo "Done. Installed models:"
docker exec "$CONTAINER" ollama list
