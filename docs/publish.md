# Publish (GitHub tomorrow)

Do this from `~/GitDank/OmaPandora`. Do not clone into `~/Work`.

## 1. Check the folder

```bash
./scripts/validate.sh
```

## 2. First commit (repo already exists)

Remote: https://github.com/Dankestrick/OmaPandora.git

```bash
git add -A
git status
git commit -m "Initial public layout for OmaPandora"
git remote add origin https://github.com/Dankestrick/OmaPandora.git   # skip if origin exists
git push -u origin main
```

## 3. Smoke-test the GitHub install

On a machine (or after a fresh copy):

```bash
omarchy plugin add https://github.com/Dankestrick/OmaPandora.git --enable
```

Bar icon, mini dropdown, full player, skip, pin, X quits Pithos.

## 4. Marketplace listing

https://plugins.omarchy.org/publish.html

Open the submit form with that GitHub URL, category **Media**, tags like
`pandora`, `music`, `pithos`. The listing needs `manifest.json` at the
repo root (already there), README, LICENSE, and `preview.png`.
