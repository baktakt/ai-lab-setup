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
PYTORCH_WHEEL_ROOT="${PYTORCH_INDEX_URL:-https://download.pytorch.org/whl/cu130}"
PYTORCH_WHEEL_ROOT="${PYTORCH_WHEEL_ROOT%/}"

echo "Updating Docker images..."
docker compose --project-directory "$LAB_DIR" pull
docker compose --project-directory "$LAB_DIR" up -d --remove-orphans

echo "Updating ComfyUI..."
git -C "$COMFYUI_REPO_DIR" pull --ff-only
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "${PYPI_INDEX_URL:-https://pypi.org/simple}" \
  pip setuptools wheel
# Keep transitive NVIDIA dependencies on PyPI rather than PyTorch's mirror links.
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "${PYPI_INDEX_URL:-https://pypi.org/simple}" \
  --find-links "$PYTORCH_WHEEL_ROOT/torch/" \
  --find-links "$PYTORCH_WHEEL_ROOT/torchvision/" \
  --find-links "$PYTORCH_WHEEL_ROOT/torchaudio/" \
  torch torchvision torchaudio
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "${PYPI_INDEX_URL:-https://pypi.org/simple}" \
  -r "$COMFYUI_REPO_DIR/requirements.txt"

systemctl --user restart comfyui.service
echo "Update complete."
docker compose --project-directory "$LAB_DIR" ps
systemctl --user --no-pager --full status comfyui.service || true
