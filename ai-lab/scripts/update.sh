#!/usr/bin/env bash
# Update Docker services and the host ComfyUI installation.
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ai-lab/comfyui.env"

if [[ ! -r "$CONFIG_FILE" ]]; then
  echo "Missing ComfyUI config: $CONFIG_FILE (run setup.sh first)." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

echo "Updating Docker images..."
docker compose --project-directory "$LAB_DIR" pull
docker compose --project-directory "$LAB_DIR" up -d --remove-orphans

echo "Updating ComfyUI..."
git -C "$COMFYUI_REPO_DIR" pull --ff-only
"$COMFYUI_VENV/bin/python" -m pip install --upgrade pip setuptools wheel
"$COMFYUI_VENV/bin/python" -m pip install --upgrade \
  torch torchvision torchaudio \
  --extra-index-url "${PYTORCH_INDEX_URL:-https://download.pytorch.org/whl/cu130}"
"$COMFYUI_VENV/bin/python" -m pip install --upgrade -r "$COMFYUI_REPO_DIR/requirements.txt"

systemctl --user restart comfyui.service
echo "Update complete."
docker compose --project-directory "$LAB_DIR" ps
systemctl --user --no-pager --full status comfyui.service || true
