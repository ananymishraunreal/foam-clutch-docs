#!/bin/sh
# check-docs.sh - CI-friendly drift check for the docs repo.
# 1. Regenerates CLI captures and fails on diff.
# 2. Checks relative links and anchors over all *.md files.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "${SLUICE_BIN:?set SLUICE_BIN}" ] || { echo "SLUICE_BIN missing" >&2; exit 2; }
"$ROOT/scripts/capture-cli.sh"
if [ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no docs/reference/cli)" ]; then
  echo "docs/reference/cli drifted; update docs to match --help" >&2
  git -C "$ROOT" status --porcelain --untracked-files=no docs/reference/cli >&2
  exit 1
fi
python3 - "$ROOT" <<'PY'
import os, re, sys
root = sys.argv[1]
files = []
for dp, _, fns in os.walk(root):
    if '.git' in dp: continue
    for f in fns:
        if f.endswith('.md'): files.append(os.path.join(dp, f))
anchors = {}
for f in files:
    txt = open(f).read()
    ids = set(re.findall(r'^#{1,6}\s+(.*)', txt, re.M))
    norm = set()
    for h in ids:
        h = re.sub(r'`', '', h).strip().lower()
        h = re.sub(r'[^a-z0-9 -]', '', h).replace(' ', '-')
        norm.add(h)
    anchors[f] = norm
bad = 0
for f in files:
    for m in re.finditer(r'\[[^\]]*\]\(([^)]+)\)', open(f).read()):
        link = m.group(1)
        if re.match(r'https?://|mailto:|#', link): continue
        path, _, frag = link.partition('#')
        tgt = os.path.normpath(os.path.join(os.path.dirname(f), path)) if path else f
        if not os.path.exists(tgt):
            print(f'{f}: broken link {link}'); bad = 1; continue
        if frag and tgt.endswith('.md') and frag not in anchors.get(tgt, set()):
            print(f'{f}: missing anchor {link}'); bad = 1
sys.exit(bad)
PY
echo "docs check passed"
