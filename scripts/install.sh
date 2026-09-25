#!/usr/bin/env bash
# Copy this repo's plugin payload into the live Omarchy plugin folder.
# Does not touch ~/.config/omarchy/omapandora-pins.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/io.github.dankestrick.omapandora"

mkdir -p "$DEST/qml" "$DEST/helpers"
cp -f "$ROOT/manifest.json" "$DEST/manifest.json"
cp -f "$ROOT/qml/"* "$DEST/qml/"
cp -f "$ROOT/helpers/"* "$DEST/helpers/"
chmod +x "$DEST/helpers/pithosctl" "$DEST/helpers/cava-run"

# Drop leftover root copies from the old flat layout so Omarchy
# only sees qml/ + helpers/ + manifest.json.
for stale in Api.js BarWidget.qml Panel.qml Service.qml Visualizer.qml \
  TransportButton.qml PlaybackSlider.qml RetryImage.qml pithosctl cava-run cava.conf \
  LICENSE .gitignore; do
  rm -f "$DEST/$stale"
done

echo "Installed to $DEST"
echo "If the keepLoaded service looks stale: omarchy restart shell"
