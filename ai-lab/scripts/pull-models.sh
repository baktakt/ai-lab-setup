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
  echo ""
  echo "Pulling: $1"
  docker exec "$CONTAINER" ollama pull "$1"
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
