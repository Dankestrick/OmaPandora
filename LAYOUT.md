# Where files go

This repo **is** the Omarchy plugin. `omarchy plugin add` clones it as
`~/.config/omarchy/plugins/io.github.dankestrick.omapandora/`.
`manifest.json` must stay in the repo root.

```
OmaPandora/
├── manifest.json          Plugin contract (id, kinds, entry points). Keep here.
├── preview.png            Marketplace card image.
├── README.md              What it is, install, links into docs/.
├── LICENSE                MIT.
├── CONTRIBUTING.md        How to edit and copy into the live plugin folder.
├── CHANGELOG.md           Version notes.
├── LAYOUT.md              This map.
│
├── qml/                   All Quickshell UI and the keepLoaded service.
│   ├── BarWidget.qml      Bar icon + mini player. Manifest barWidget.
│   ├── Panel.qml          Full floating player. Manifest panel.
│   ├── Service.qml        Pithos / MPRIS / pins. Manifest service.
│   ├── Api.js             Shared helpers. Import as "Api.js" from qml/.
│   ├── Visualizer.qml     Cava bars.
│   ├── TransportButton.qml
│   ├── PlaybackSlider.qml
│   └── RetryImage.qml     Album art.
│
├── helpers/               Programs QML launches. Do not put these in qml/.
│   ├── pithosctl          Python: MPRIS, launch, quit, pin save.
│   ├── cava-run           Pulse sink-monitor wrapper for cava.
│   └── cava.conf          Reference config. cava-run writes its own temp file.
│
├── docs/                  Human guides. Not loaded by Omarchy.
│   ├── README.md          Index of these guides.
│   ├── install.md
│   ├── uninstall.md
│   ├── dependencies.md
│   ├── first-run.md
│   ├── keyboard.md
│   ├── layout.md          Player layout (not this file).
│   ├── pithos.md
│   ├── screenshots.md
│   ├── troubleshooting.md
│   └── screenshots/       PNG files. kebab-case names, no spaces.
│
└── scripts/               Local tools. Not loaded by Omarchy.
    ├── install.sh         Copy qml/ + helpers/ + manifest into the live plugin dir.
    ├── uninstall.sh       omarchy plugin remove.
    └── validate.sh        omarchy plugin validate + qmllint.
```

## Put new work here

| You are adding… | Put it in |
| --- | --- |
| Bar, panel, or service QML | `qml/` |
| A reusable QML control used by Panel/Bar | `qml/` (same folder so types resolve) |
| A script the UI execs (`pithosctl`, cava) | `helpers/` |
| A user-facing guide | `docs/<topic>.md` |
| A screenshot | `docs/screenshots/<name>.png` |
| A one-off local command | `scripts/` |
| Plugin id, kinds, bar settings | `manifest.json` only |
| Install story for GitHub | `README.md` |

Do not add new QML next to `manifest.json`. Do not symlink this repo into
`~/.config/omarchy/plugins/`. Copy with `scripts/install.sh`.

Pins live outside the plugin: `~/.config/omarchy/omapandora-pins.json`.
