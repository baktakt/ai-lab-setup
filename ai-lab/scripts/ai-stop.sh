#!/usr/bin/env bash
# Stop all AI services
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Stopping AI stack..."
if command -v systemctl &>/dev/null; then
  systemctl --user stop comfyui.service
fi
docker compose down
echo "Done."
