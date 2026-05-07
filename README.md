# FixMyGrammar

[![CI](https://github.com/Dmytro-Kopylov-personal/fixmygrammar/actions/workflows/ci.yml/badge.svg)](https://github.com/Dmytro-Kopylov-personal/fixmygrammar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14+-blue.svg)](Package.swift)

**FixMyGrammar** is a small **macOS menu-bar app** that sends text to [**LM Studio**](https://lmstudio.ai/) (or any **OpenAI-compatible** local server), then shows **grammar / style** suggestions in a compact overlay. Everything stays on your machine by default (your configured URL — typically `http://127.0.0.1:1234`).

There is **no Dock icon**; the app runs like a lightweight utility next to the clock (similar to many agent-style apps).

---

## Features

- **Menu bar** control: check grammar, open **Settings**, quit.
- **Global shortcut** (customizable) to run a check from any app.
- **Clipboard-first workflow** (recommended for browsers & Slack): copy text with ⌘C, then run the shortcut or use the menu.
- **Accessibility selection** (optional): works in some native apps; grant **Privacy → Accessibility** for a stable app bundle (`FixMyGrammar.app`).
- **Results overlay**: original vs. corrected text, optional issues list, copy buttons.
- **Local-first**: network calls only go to your LM Studio base URL; no bundled telemetry.

---

## Requirements

- **macOS 14** (Sonoma) or later  
- **LM Studio** (or compatible server) with a loaded model  
- Swift **5.9+** if you build from source  

---

## Quick start

### 1. Install LM Studio

Load a model and start the local server (default port is often **1234**).

### 2. Run FixMyGrammar

**Option A — app bundle (best for Accessibility & permissions)**

```bash
git clone https://github.com/Dmytro-Kopylov-personal/fixmygrammar.git
cd fixmygrammar
./scripts/bundle_mac_app.sh release
open dist/FixMyGrammar.app
```

Then open **Settings** from the menu bar (or **FixMyGrammar** in System Settings), set:

- **Base URL** — e.g. `http://127.0.0.1:1234`
- **Model id** — exactly the id LM Studio shows for the loaded model

**Option B — SwiftPM binary (developers)**

```bash
swift build -c release
.build/release/FixMyGrammar
```

### 3. Capture text

- **Clipboard**: Select text, **⌘C**, then trigger your shortcut (default includes ⌘⌥⇧G — see **Settings → Shortcut**).
- **Selection-only mode**: Enable in Settings; grant **Accessibility** to `FixMyGrammar.app` (use the bundle from `dist/` so macOS lists it reliably).

---

## Development

```bash
swift package resolve
swift build
swift test    # uses XCTest; install full Xcode if this fails with “no such module XCTest”
```

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for layout, versioning, and PR guidelines.

Architecture overview: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**.

---

## Privacy

- **Clipboard** may be read when capture settings allow it (never in “selection only” mode).
- **Accessibility** may read the focused app’s selection when enabled; macOS prompts for permission.
- **User text** is sent only to the **HTTP base URL** you set (plus optional API key header if you configure one).

---

## Troubleshooting

| Issue | What to try |
|--------|------------|
| “No text captured” | Copy the passage with **⌘C** first, or check **Capture** settings; browsers often need clipboard, not AX selection. |
| Model id errors | The **Model id** field must be the LM Studio model name only — not the paragraph you’re editing. |
| Accessibility | Build **`dist/FixMyGrammar.app`**, open it once, then add it under **System Settings → Privacy & Security → Accessibility**. |
| Results / JSON errors | The model must return a single JSON object as described in the system prompt (`FixMyGrammarCore`). Enable **Show full report** to inspect raw output. |

---

## License

[MIT License](LICENSE). See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Contributing & conduct

Contributions welcome: [CONTRIBUTING.md](CONTRIBUTING.md).  
Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).  
Security disclosures: [SECURITY.md](SECURITY.md).
