# Contributing

Thanks for helping improve FixMyGrammar.

## Prerequisites

- macOS **14** or later (matches `Package.swift` and `Packaging/Info.plist`).
- **Swift 5.9+** toolchain.
- **Xcode** (recommended): full Xcode includes `XCTest`, so `swift test` works locally. With **Command Line Tools only**, you may only be able to run `swift build` until you install Xcode.
- [LM Studio](https://lmstudio.ai/) (or any OpenAI-compatible server on your configured base URL).

## Clone and build

```bash
git clone https://github.com/Dmytro-Kopylov-personal/fixmygrammar.git
cd fixmygrammar
swift package resolve
swift build
swift test   # requires Xcode toolchain with XCTest
```

Run the binary:

```bash
open .build/debug/FixMyGrammar
# or
.build/debug/FixMyGrammar
```

## App bundle (Accessibility identity)

For a stable **`.app`** and clearer macOS permissions, use:

```bash
./scripts/bundle_mac_app.sh release
open dist/FixMyGrammar.app
```

Then grant **Accessibility** if you use selection-based capture (see README).

## Project layout

- `Sources/FixMyGrammar/` — SwiftUI app, hotkey, networking, overlays.
- `Sources/FixMyGrammarCore/` — shared grammar JSON types and parser (used by tests and the app).
- `Tests/FixMyGrammarTests/` — unit tests.
- `Packaging/Info.plist` — bundle metadata for `bundle_mac_app.sh`.
- `docs/ARCHITECTURE.md` — high-level data flow.

## Pull requests

- Keep changes focused; match existing style and naming.
- Run `swift build` and `swift test` before pushing (CI runs the same on `macos-14`).
- If you change user-visible behavior, update **README.md** and **CHANGELOG.md** under `[Unreleased]`.

## Version bumps

When cutting a release, align:

1. Run **`./scripts/pre_public_audit.sh`** (no committed secrets or `dist/` / `.build/`).
2. `CHANGELOG.md` — move items from `[Unreleased]` into a dated section.
3. `Packaging/Info.plist` — `CFBundleShortVersionString` / `CFBundleVersion`.
4. `Sources/FixMyGrammar/AppMetadata.swift` — `fallbackMarketingVersion` (used when not running from a bundle).
5. Public repo checklist: **[docs/GITHUB_REPOSITORY_SETTINGS.md](docs/GITHUB_REPOSITORY_SETTINGS.md)**.

## License

By contributing, you agree your contributions will be licensed under the **MIT License** (`LICENSE`).
