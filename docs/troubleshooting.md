# Troubleshooting

## Bar icon does nothing

The panel must implement `open()`. Restart the shell:

```bash
omarchy restart shell
```

Confirm the plugin is enabled:

```bash
omarchy plugin list
```

## Hover still says the old tooltip / UI looks stale

`keepLoaded` services do not always pick up QML until a shell restart. Also
make sure `~/.config/omarchy/plugins/io.github.dankestrick.omapandora/qml/Panel.qml`
is **not** zero bytes (that happened during development).

## Visualizer is still / not bouncing

Cava must hear the **speaker monitor**, not the microphone. `cava-run` sets
`PULSE_SOURCE` to `$(pactl get-default-sink).monitor`. Music has to be playing.

```bash
pactl get-default-sink
pgrep -a cava
```

## Pithos window keeps popping up

A second `pithos` launch raises the existing app. OmaPandora’s launch helper
skips start if MPRIS is already there. Add the Hyprland rule in
[install.md](install.md) so the GTK window stays on `special:pithos`.

## X does not stop the music

X calls `stopAndQuit`, which pauses and then quits Pithos only if OmaPandora
started it. A Pithos you opened yourself is paused and left running. To close
it by hand:

```bash
pkill -f /usr/bin/pithos
```

## Pins do not save

Check `~/.config/omarchy/omapandora-pins.json`. **C** pins the **highlighted**
row in My list or Your stations, not necessarily the song that is playing.

## Plugin folder as a symlink

Omarchy validation fails if the plugin directory is a symlink. Copy or git
clone into `~/.config/omarchy/plugins/<id>/`.
