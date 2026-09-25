# Pithos as a playback daemon

Pithos is a GTK Pandora client. OmaPandora does **not** embed Pandora login.
It starts Pithos, hides it, and controls it over MPRIS.

## Why

Pandora’s official API is partner-only. Pithos already implements login,
stations, thumbs, and skip. That is the same approach this plugin was built
around: Pithos is a dependency, not a competing UI.

## Life cycle

1. Open OmaPandora from the bar → `pithosctl launch` starts Pithos if needed
   (a second launch will **not** raise the window).
2. Hyprland can send the Pithos window to `special:pithos` so it stays off
   the regular workspaces.
3. `pithosctl` uses MPRIS (`PlayPause`, `Next`, playlists, Love/Ban/Tired).
4. **X** on OmaPandora → pause. If OmaPandora started this Pithos, it also
   sends MPRIS `Quit`, and ends that one process if it is still running a
   couple of seconds later. A Pithos you opened yourself is only paused.

Pithos is **not** in Hyprland autostart. It should not run 24/7.

## Helpers

- `pithosctl` — JSON status, station switch, ratings, launch, quit
- `cava-run` — cava pointed at `$(pactl get-default-sink).monitor`

## First login

Pithos stores email in GSettings and the password in the Secret Service
(`io.github.Pithos.Account`). If auto-connect fails, open Pithos once from
Settings.
