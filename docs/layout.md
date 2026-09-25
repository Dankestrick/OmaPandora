# Layout

OmaPandora is a Quickshell plugin with three entry points (`manifest.json`):

| Kind | File | Role |
| --- | --- | --- |
| Service | `qml/Service.qml` | Talks to Pithos, cava helper, pins |
| Bar widget | `qml/BarWidget.qml` | Music-note icon on the Omarchy bar |
| Panel | `qml/Panel.qml` | Large floating player |

## Bar

- Default section: **left**
- Icon: the same Nerd Font music note that used to sit by “Now playing”
- Click toggles the floating player
- Hover label: **OmaPandora**

## Floating window

Hyprland can float and center a window titled `OmaPandora`.

Top header: music note + **Now Playing - (station name)**

### Sidebar (left)

- Themed outer border
- **My list** — pinned stations (Tab group 1)
- **Your stations** — remaining stations (Tab group 2)
- Settings

### Main (right)

Album art, title, artist, album, visualizer (Tab group 3, together with the
sound bar).

### Footer

Transport, love / tired / ban, volume. Lights up with the big player when you
Tab to group 3.

## Theme

Uses Omarchy `Color` / `Style` (`qs.Commons`). Window fill is the theme
background at half opacity. Accent color is used for the active Tab frame.
