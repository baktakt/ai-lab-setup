#!/usr/bin/env bash
# Start all AI services
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Starting AI stack..."
if [[ -f .env ]]; then
  enable_home_assistant="$(grep -E '^ENABLE_HOME_ASSISTANT=' .env | tail -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
else
  enable_home_assistant=""
fi

if [[ "${enable_home_assistant,,}" == "true" ]]; then
  docker compose --profile home-assistant up -d
else
  docker compose up -d
fi
echo ""
echo "Services:"
docker compose ps
echo ""
echo "Open WebUI → http://localhost:3000"
echo "ComfyUI    → http://localhost:8188"
echo "Hermes     → http://localhost:8080"
echo "Qdrant     → http://localhost:6333"
echo "Ollama API → http://localhost:11434"
if [[ "${enable_home_assistant,,}" == "true" ]]; then
  echo "Home Assistant → http://localhost:8123"
fi
