#!/usr/bin/env bash
# Remove the live Omarchy plugin. Does not delete pithos, cava, or pins.
set -euo pipefail
omarchy plugin remove io.github.dankestrick.omapandora --yes 2>/dev/null \
  || omarchy plugin remove io.github.dankestrick.omapandora
echo "Plugin removed."
echo "Pins still in ~/.config/omarchy/omapandora-pins.json"
echo "To drop pins: rm -f ~/.config/omarchy/omapandora-pins.json"
echo "To quit Pithos if it is still running: gdbus call --session --dest org.mpris.MediaPlayer2.pithos --object-path /org/mpris/MediaPlayer2 --method org.mpris.MediaPlayer2.Quit"
