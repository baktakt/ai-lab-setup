#!/usr/bin/env sh
set -eu

if [ -d /opt/ComfyUI/custom_nodes.default ]; then
  mkdir -p /opt/ComfyUI/custom_nodes
  for node in /opt/ComfyUI/custom_nodes.default/*; do
    [ -e "$node" ] || continue
    target="/opt/ComfyUI/custom_nodes/$(basename "$node")"
    if [ ! -e "$target" ]; then
      cp -a "$node" "$target"
    fi
  done
fi

exec "$@"
