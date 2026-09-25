# Dependencies

Declared in `manifest.json` as well.

| Name | Package | Required | Why |
| --- | --- | --- | --- |
| **Pithos** | `pithos` | Yes | Pandora has no public hobby OAuth like Spotify. Pithos logs in, holds the station list, and plays audio. OmaPandora talks to it over MPRIS. |
| **cava** | `cava` | Yes (for the visualizer) | Now Playing bar visualizer. Listens to the default speaker monitor, not the microphone. |
| **Omarchy** | Omarchy desktop | Yes | Quickshell host (`omarchy-shell`), bar, theme colors. |
| **PipeWire / Pulse** | already on Omarchy | Yes | Pithos playback and cava capture. |

## Install

```bash
sudo pacman -S --needed pithos cava
```

If `pithos` is AUR-only on your snapshot:

```bash
omarchy pkg aur add pithos
```

## Runtime extras (usually already installed)

- `pactl` (libpulse) — cava-run finds the default sink monitor
- `stdbuf` (coreutils) — line-buffered cava output
- Python 3 + PyGObject (`gi.repository.Gio`) — `pithosctl`
- Desktop keyring — Pithos saves the Pandora password

## What OmaPandora does **not** use

- Spotify / OmaSpotify AuthManager
- A Pandora developer client id
- Chromium or a webview
