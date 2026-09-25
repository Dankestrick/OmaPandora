# Uninstall OmaPandora

This removes the plugin from Omarchy. Pithos and cava are separate packages;
remove those only if you do not want them for anything else.

## 1. Disable the bar widget

```bash
omarchy plugin disable io.github.dankestrick.omapandora
```

If that command is not available, edit `~/.config/omarchy/shell.json` and
delete the `io.github.dankestrick.omapandora` entry from `bar.layout` (usually
under `left`).

## 2. Delete the plugin files

```bash
rm -rf ~/.config/omarchy/plugins/io.github.dankestrick.omapandora
omarchy restart shell
```

Pinned stations live outside the plugin:

```bash
rm -f ~/.config/omarchy/omapandora-pins.json
```

## 3. Stop Pithos if it is still running

```bash
pkill -x pithos
```

## 4. Optional: window rules

If you added OmaPandora / Pithos rules to `~/.config/hypr/hyprland.lua`, delete
those `o.window(...)` blocks and run `hyprctl reload`.

## 5. Optional: packages

```bash
sudo pacman -Rns pithos cava
```

Only do this if nothing else on the machine needs them.

## 6. Optional: this git checkout

Your git clone of OmaPandora is **not** removed by the steps
above. Delete that folder yourself if you want the source gone too.
