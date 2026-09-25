#!/usr/bin/env bash
set -euo pipefail
omarchy plugin remove io.github.dankestrick.omapandora --yes 2>/dev/null \
  || omarchy plugin remove io.github.dankestrick.omapandora
echo "Plugin removed. Pins stay in ~/.config/omarchy/omapandora-pins.json"
