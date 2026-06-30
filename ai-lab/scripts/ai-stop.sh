#!/usr/bin/env bash
# Stop all AI services
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Stopping AI stack..."
docker compose down
echo "Done."
