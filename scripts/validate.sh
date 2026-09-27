#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

omarchy plugin validate "$ROOT"
echo "omarchy plugin validate ok"

# Every Text item must say how to render its text. Qt's default (AutoText)
# renders anything that looks like HTML, so Pandora metadata could make the
# shell load remote images. Plain text only.
python3 - "$ROOT/qml" <<'PY'
import pathlib, re, sys
bad = []
for path in sorted(pathlib.Path(sys.argv[1]).glob("*.qml")):
    lines = path.read_text().split("\n")
    for i, line in enumerate(lines):
        if not re.match(r"^\s*Text\s*\{\s*$", line):
            continue
        depth, j, has = 1, i + 1, False
        while j < len(lines) and depth > 0:
            if depth == 1 and re.match(r"^\s*textFormat\s*:", lines[j]):
                has = True
            depth += lines[j].count("{") - lines[j].count("}")
            j += 1
        if not has:
            bad.append(f"{path.name}:{i + 1}")
if bad:
    sys.exit("Text items without textFormat: " + ", ".join(bad))
print("every Text item sets textFormat")
PY
