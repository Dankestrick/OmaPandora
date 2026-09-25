# Screenshots

Put files in [`screenshots/`](screenshots/). GitHub will show them from the
README once they exist.

Use PNG. Dark theme and light theme both help if you switch Omarchy themes.

## Suggested filenames

| File | Shot |
| --- | --- |
| `Main.png` | Full floating player (already in the README) |
| `ThemeChange1-4.png` / `MiniTheme1-4.png` | Full and mini player in the same four themes (already in the README) |
| `bar-icon.png` | Omarchy bar with the music-note OmaPandora icon |
| `player-now-playing.png` | Full floating window, Now Playing header with station name |
| `player-my-list.png` | Tab group 1: My list frame highlighted, a pin selected |
| `player-your-stations.png` | Tab group 2: Your stations frame highlighted |
| `player-big-player.png` | Tab group 3: art + visualizer + sound bar highlighted |
| `visualizer.png` | Cava bars moving with a song |
| `shortcuts.png` | `Ctrl+/` shortcut overlay |

## How to capture on Omarchy

```bash
# Region shot (typical Omarchy bind is Super+Shift+S or the capture menu)
omarchy-capture-screenshot
```

Copy the results into `docs/screenshots/` using the names above.

Then link them from the root README, for example:

```markdown
![Full player](docs/screenshots/player-now-playing.png)
```
