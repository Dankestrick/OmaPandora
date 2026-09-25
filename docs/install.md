# Install OmaPandora

OmaPandora is an Omarchy shell plugin. It needs **Pithos** (Pandora login and
audio) and **cava** (the Now Playing visualizer).

## 1. Omarchy

You need a working Omarchy desktop (Hyprland + `omarchy-shell`). Check:

```bash
omarchy plugin list
```

## 2. Dependencies

```bash
sudo pacman -S --needed pithos cava
```

Pithos may come from the AUR on some setups:

```bash
omarchy pkg aur add pithos
```

Confirm:

```bash
command -v pithos
command -v cava
```

Details: [dependencies.md](dependencies.md)

## 3. Add the plugin

### From GitHub (once the repo is public)

```bash
omarchy plugin add https://github.com/Dankestrick/OmaPandora.git --enable
```

That clones into `~/.config/omarchy/plugins/io.github.dankestrick.omapandora/`
and puts the widget on the bar.

### From this folder (local development)

```bash
cd ~/GitDank/OmaPandora
./scripts/install.sh
omarchy plugin enable io.github.dankestrick.omapandora left
omarchy restart shell
```

That copies `manifest.json`, `qml/`, and `helpers/` only. Do **not** symlink
the plugin folder. Omarchy rejects plugin trees that are symlinks.

## 4. Optional window rules

In `~/.config/hypr/hyprland.lua` you can park Pithos off-screen and float the
player:

```lua
o.window("^(io\\.github\\.Pithos|[Pp]ithos)$", {
  workspace = "special:pithos silent",
  no_focus = true,
})

o.window({ title = "^OmaPandora$" }, {
  float = true,
  center = true,
})
```

Then:

```bash
hyprctl reload
```

## 5. Sign in

1. Click the music-note icon on the bar (opens OmaPandora).
2. If nothing is connected, open Pithos from Settings and sign in with your
   Pandora account.
3. Pithos stores the password in the system keyring. You should only need to
   do this once.
4. Close Pithos’s window if it appeared; playback is controlled from OmaPandora.

Next: [first-run.md](first-run.md)
