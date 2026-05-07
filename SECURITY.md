# Security policy

## Supported versions

Security fixes are applied to the latest release on the default branch (`main`). There are no long-term support branches.

## Reporting a vulnerability

Please **do not** open a public issue for security-sensitive reports.

- Use [GitHub Security Advisories](https://github.com/Dmytro-Kopylov-personal/fixmygrammar/security/advisories/new) to report a vulnerability privately, or
- Open a draft security advisory and we will coordinate a fix and disclosure timeline.

Include enough detail to reproduce the issue (macOS version, app version or commit, and steps). We will aim to acknowledge within a few business days.

## Scope

FixMyGrammar talks **only to the LM Studio URL you configure** (default `http://127.0.0.1:1234`). It reads **clipboard** and optionally **Accessibility-selected text** as documented in the README. Threat models around malicious local proxies or compromised LM Studio instances are largely outside the app’s control; still, we welcome reports about unsafe defaults, injection in UI, or mishandling of untrusted data.
