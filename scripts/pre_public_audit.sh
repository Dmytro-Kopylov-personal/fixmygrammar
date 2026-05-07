#!/usr/bin/env bash
# Local checks before making the repository public or tagging a release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "error: $*" >&2; exit 1; }

echo "== 1. Tracked build / artifact paths (should be empty) =="
if git ls-files dist .build 2>/dev/null | grep -q .; then
	git ls-files dist .build
	fail "Do not commit dist/ or .build/. Check .gitignore."
fi
echo "ok"

echo "== 2. Local secrets file must not be tracked =="
if git ls-files --error-unmatch .cursor/mcp.json >/dev/null 2>&1; then
	fail ".cursor/mcp.json is tracked; remove it and use .example only."
fi
echo "ok"

echo "== 3. Obvious secret-like tokens in tracked code (high confidence) =="
if git grep -nE 'sk-[a-zA-Z0-9]{16,}|ghp_[a-zA-Z0-9]{20,}|xox[baprs]-' -- Sources Tests scripts .github 2>/dev/null; then
	fail "Possible API tokens — review and remove before going public."
fi
echo "ok"

echo "== 4. Swift build =="
swift build -c release

echo ""
echo "All pre-public audits passed."
echo "Next: read docs/GITHUB_REPOSITORY_SETTINGS.md, then tag / release if needed."
