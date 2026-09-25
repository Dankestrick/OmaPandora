#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

omarchy plugin validate "$ROOT"
echo "omarchy plugin validate ok"
