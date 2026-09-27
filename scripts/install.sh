#!/usr/bin/env bash
# Developer install: copy this repo's plugin payload into the live Omarchy
# plugin folder. Does not touch ~/.config/omarchy/omapandora-pins.json.
#
# It only replaces a folder that this script created, marked by
# .omapandora-dev-install. A folder from `omarchy plugin add` (a git
# checkout) or anything else is left alone; remove it first with
# `omarchy plugin remove io.github.dankestrick.omapandora`.
set -euo pipefail

ID="io.github.dankestrick.omapandora"
MARKER=".omapandora-dev-install"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
DEST="$PLUGINS/$ID"

refuse() {
  echo "Not installing: $1" >&2
  echo "Remove it first: omarchy plugin remove $ID" >&2
  exit 1
}

mkdir -p "$PLUGINS"
if [ -L "$PLUGINS" ]; then
  echo "Not installing: $PLUGINS is a symlink" >&2
  exit 1
fi

if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  [ -L "$DEST" ] && refuse "$DEST is a symlink."
  [ -d "$DEST" ] || refuse "$DEST is not a folder."
  [ -O "$DEST" ] || refuse "$DEST is not owned by you."
  [ -e "$DEST/.git" ] && refuse "$DEST is a git checkout (installed by omarchy plugin add)."
  if [ ! -f "$DEST/$MARKER" ] || [ -L "$DEST/$MARKER" ]; then
    refuse "$DEST was not created by scripts/install.sh."
  fi
fi

# Build the new copy next to the old one, then swap it in, so a failed
# copy never leaves a half-written plugin behind.
STAGE="$(mktemp -d "$PLUGINS/.$ID.new.XXXXXX")"
trap 'rm -rf -- "$STAGE"' EXIT
mkdir "$STAGE/qml" "$STAGE/helpers"
cp "$ROOT/manifest.json" "$STAGE/manifest.json"
cp "$ROOT/qml/"* "$STAGE/qml/"
cp "$ROOT/helpers/"* "$STAGE/helpers/"
chmod +x "$STAGE/helpers/pithosctl" "$STAGE/helpers/cava-run"
echo "Created by OmaPandora scripts/install.sh; safe for it to replace." > "$STAGE/$MARKER"
chmod 755 "$STAGE"

if [ -d "$DEST" ]; then
  OLD="$(mktemp -d "$PLUGINS/.$ID.old.XXXXXX")"
  mv -T "$DEST" "$OLD/plugin"
  if ! mv -T "$STAGE" "$DEST"; then
    mv -T "$OLD/plugin" "$DEST"
    rmdir "$OLD"
    exit 1
  fi
  rm -rf -- "$OLD"
else
  mv -T "$STAGE" "$DEST"
fi
trap - EXIT

echo "Installed to $DEST"
echo "If the keepLoaded service looks stale: omarchy restart shell"
