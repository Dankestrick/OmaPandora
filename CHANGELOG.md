# Changelog

## Unreleased

- Fixed: the full player could get stuck open but treated as closed (no big
  album art, flat visualizer, Esc not closing, the bar icon opening the mini
  player on top). Moving the window to another monitor briefly hides it, and
  that hide was taken as a close. The window now moves only when it is on the
  wrong monitor, and a hide during the move no longer closes the player.
- `scripts/install.sh` only replaces a plugin folder it created itself. It no
  longer writes into or deletes files from an `omarchy plugin add` checkout or
  any other folder at the plugin path.
- `scripts/install.sh` also stops if its own folder has a file it did not
  install or a file changed since, so nothing you added there is deleted. It
  records each installed file's SHA-256 in `.omapandora-dev-install` and removes
  only those files from the old copy.
- Pinned stations: if `omapandora-pins.json` exists but can't be read, pinning
  is paused and the player says so, instead of replacing the file.
- `docs/uninstall.md` removes the plugin with `omarchy plugin remove` instead
  of `rm -rf`.
- Pins are saved by the helper as a private (0600) file, and it also refuses
  to replace a pins file it can't read.
- Album art loads only from Pithos's local cache (`file://`), with a size
  limit on every image; the shell never fetches art over the network.
- Pithos is started from `/usr/bin/pithos` instead of the first `pithos` on
  `$PATH`.
- Fixed: opening the player twice while Pithos was still starting could
  record the PID of a second copy that exits at once, so X only paused the
  Pithos OmaPandora had started. The helper no longer starts a second copy
  and records a PID only if that process keeps running.
- `cava-run` gives `pactl` a 3-second time limit, and pipes cava its config
  instead of writing a temp file, so a shell restart can't leave one behind.
- Docs: the command to quit Pithos uses its real bus name,
  `org.mpris.MediaPlayer2.io.github.Pithos`.
- `scripts/uninstall.sh` runs `omarchy plugin remove` once and shows its errors.

## 0.1.1

- The full player opens on the monitor your mouse is on, not always workspace 3.
- Scrolling on the bar icon skips to the next song while the mini player is open.
- README: bar clicks, bar settings, keybind commands, and troubleshooting.

## 0.1.0

- First public layout: `qml/`, `helpers/`, `docs/`, `scripts/`.
- Bar widget, mini player, full player, Pithos backend, cava visualizer.
