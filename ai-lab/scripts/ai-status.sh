#!/usr/bin/env bash
# Show status of AI services and GPU
set -euo pipefail
cd "$(dirname "$0")/.."
echo "=== Docker services ==="
docker compose ps
echo ""
echo "=== GPU ==="
nvidia-smi
