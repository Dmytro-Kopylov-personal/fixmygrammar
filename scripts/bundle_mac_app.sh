#!/usr/bin/env bash
# Build a real FixMyGrammar.app so macOS lists it in Accessibility / Login Items with a stable identity.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CONFIG="${1:-release}"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)/FixMyGrammar"
if [[ ! -f "$BIN" ]]; then
	echo "error: missing binary at $BIN" >&2
	exit 1
fi

OUT_APP="$REPO_ROOT/dist/FixMyGrammar.app"
rm -rf "$OUT_APP"
mkdir -p "$OUT_APP/Contents/MacOS"

cp "$BIN" "$OUT_APP/Contents/MacOS/FixMyGrammar"
chmod +x "$OUT_APP/Contents/MacOS/FixMyGrammar"

cp "$REPO_ROOT/Packaging/Info.plist" "$OUT_APP/Contents/Info.plist"
printf 'APPL????' > "$OUT_APP/Contents/PkgInfo"

echo "Built: $OUT_APP"
echo "Open it from Finder or: open \"$OUT_APP\""
echo "Then add FixMyGrammar in System Settings → Privacy & Security → Accessibility (use + and pick the app in dist/)."
