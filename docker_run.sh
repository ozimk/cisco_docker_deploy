#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[*] Pulling images..."
docker compose pull || true

echo "[*] Starting stack..."
docker compose up -d

echo "[*] Stack is running. Listing containers:"
docker compose ps
