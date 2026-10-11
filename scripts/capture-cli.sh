#!/bin/sh
# capture-cli.sh - regenerate docs/reference/cli from the real binary.
# Usage: SLUICE_BIN=/tmp/sluice-audit ./scripts/capture-cli.sh
# Fails on drift when run via scripts/check-docs.sh.
set -eu
BIN="${SLUICE_BIN:?set SLUICE_BIN to a built ./cmd/sluice binary}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/reference/cli"
mkdir -p "$OUT"
for c in version init validate submit watch status cancel list logs serve doctor run; do
  if [ "$c" = run ]; then
    "$BIN" run --help > "$OUT/sluice-run.txt" 2>&1 || true
  else
    "$BIN" "$c" --help > "$OUT/sluice-$c.txt" 2>&1
  fi
done
"$BIN" --help > "$OUT/sluice.txt" 2>&1
echo "captured $(ls "$OUT" | wc -l) files in $OUT"
