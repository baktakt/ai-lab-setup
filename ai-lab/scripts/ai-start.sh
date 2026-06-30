#!/usr/bin/env bash
# Start all AI services
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Starting AI stack..."
docker compose up -d
echo ""
echo "Services:"
docker compose ps
echo ""
echo "Open WebUI → http://localhost:3000"
echo "ComfyUI    → http://localhost:8188"
echo "Hermes     → http://localhost:8080"
echo "Qdrant     → http://localhost:6333"
echo "Ollama API → http://localhost:11434"
