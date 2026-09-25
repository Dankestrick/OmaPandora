# Contributing

Read [LAYOUT.md](LAYOUT.md) first. New files go in the folder that table names.

1. Edit in `~/GitDank/OmaPandora` (`qml/` for UI, `helpers/` for pithosctl/cava).
2. Copy into the live plugin folder:

   ```bash
   ./scripts/install.sh
   ```

   Do not symlink. Do not use `rsync --delete`.
3. `omarchy restart shell` if the keepLoaded service looks stale.
4. `./scripts/validate.sh` before you push.
5. Keep Pithos as the Pandora backend.

Do not put GitHub project work outside `~/GitDank`.

Screenshots: [docs/screenshots.md](docs/screenshots.md).
