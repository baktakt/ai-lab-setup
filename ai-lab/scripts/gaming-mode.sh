#!/usr/bin/env bash
# Switch to gaming mode: stop GPU-heavy AI services, keep Qdrant running.
# Run this before launching games to free VRAM.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Switching to gaming mode..."
echo "Stopping: ollama, open-webui, ComfyUI, hermes-agent"
systemctl --user stop comfyui.service
docker compose stop ollama hermes-agent open-webui

echo ""
echo "VRAM now available for gaming."
echo ""
nvidia-smi --query-gpu=name,memory.used,memory.free --format=csv,noheader
echo ""
echo "Qdrant is still running (lightweight, safe to keep up)."
echo "To stop everything: ~/ai-lab/scripts/ai-stop.sh"
echo "To return to AI mode: ~/ai-lab/scripts/ai-start.sh"
