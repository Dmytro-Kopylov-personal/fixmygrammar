# GitHub settings before / after going public

Use this as a maintainer checklist. The **repo file tree** already includes CI, `SECURITY.md`, and templates; these items are configured in the GitHub **web UI** (or `gh` where noted).

## Visibility

- **Settings → General → Danger zone → Change repository visibility → Public**  
  Do this only after `scripts/pre_public_audit.sh` passes locally.

## Security

- **Settings → General → Security**
  - Enable **Private vulnerability reporting** (aligns with [SECURITY.md](../SECURITY.md)).
  - Turn on **Dependency graph** (usually on for public repos).
  - Enable **Dependabot alerts** and **Dependabot security updates** (version updates are driven by [`.github/dependabot.yml`](../.github/dependabot.yml)).

## Branch protection (recommended)

After **CI has run at least once** on `main`, note the exact **status check** name from the PR or branch page (often `CI / build-and-test`).

- **Settings → Branches → Add branch protection rule** (or **Rules → Rulesets** on newer UI)
  - Branch name pattern: `main`
  - Require **status checks** to pass before merging (add the CI check name).
  - Optionally: **Require a pull request before merging**.

Status check names can differ; copy the string GitHub shows when hovering the green check on a commit.

## Social & discovery

- **Settings → General** (scroll to **Social preview**): upload an image (e.g. 1280×640) for link previews.
- **Topics**: add e.g. `macos`, `swift`, `swiftui`, `lm-studio`, `grammar`, `menubar`, `local-llm`.

## Releases

- Create a **[Release](https://github.com/Dmytro-Kopylov-personal/fixmygrammar/releases)** from tag `v1.0.x` and attach **`FixMyGrammar.app`** zip if you ship binaries (optional).

## Optional: GitHub CLI

```bash
gh repo edit --add-topic macos --add-topic swift --add-topic lm-studio
```

(Adjust repo slug if you fork or rename.)
