> **Access Note:** This session's GitHub MCP tools are scoped to `djsloth/nanoclaw` only. No `gh` CLI was available. Data for `slothlabs-coder/*` (Neptune) and `invocap/*` (Saturn) could not be retrieved — both are documented as unavailable below. Expand MCP scope or provide Doppler-injected `gh` PATs to enable full Triad coverage.

---

## Access Limitations

| Org Scope | Agent | Status |
|-----------|-------|--------|
| `slothlabs-coder/*` | Neptune | ❌ No access — MCP restricted to `djsloth/nanoclaw` |
| `invocap/*` | Saturn | ❌ No access — MCP restricted to `djsloth/nanoclaw` |

---

## SlothLabs (Neptune)

> Data unavailable — `slothlabs-coder/*` is outside current MCP scope.

### Open PRs
_No data_

### Triaged Issues
_No data_

### Stale Branches
_No data_

---

## Invocap (Saturn)

> Data unavailable — `invocap/*` is outside current MCP scope.

### Open PRs
_No data_

### Triaged Issues
_No data_

### Stale Branches
_No data_

---

## DjSloth/NanoClaw (Host Repo)

### Open PRs

✅ No open pull requests.

### Triaged Issues

✅ No open issues labelled `bug` or `security`.

### Stale Branches

**All 21 non-main branches** have no commits in the last 30 days (checked: 2026-05-04).

#### 🔴 Very Stale (>60 days) — 20 branches

| Branch | Last Commit | Age | Author |
|--------|-------------|-----|--------|
| ⚠️ `security/sdk-env-secrets` | 2026-02-14 | 79d | gavrielc |
| `feat/telegram-integration-with-swarms` | 2026-02-09 | 84d | gavrielc |
| `claude/fix-timestamp-message-loss-58EEi` | 2026-02-01 | 92d | Claude |
| `claude/extract-mount-skill-ua7Ef` | 2026-02-02 | 91d | Claude |
| `claude/review-commit-docs-R2OF7` | 2026-02-17 | 76d | Claude |
| `feat/skills-engine-v0.1` | 2026-02-18 | 75d | gavrielc |
| `feat/discord-threads-and-buttons` | 2026-02-19 | 74d | TomGranot |
| `gavrielc-patch-1` | 2026-02-19 | 74d | gavrielc |
| `add-convert-to-apple-container` | 2026-02-20 | 73d | gavrielc |
| `extract-container-runtime` | 2026-02-20 | 73d | gavrielc |
| `feat/voice-transcription-skill` | 2026-02-20 | 73d | gavrielc |
| `update-skills-docker-references` | 2026-02-20 | 73d | gavrielc |
| `feat/create-skill` | 2026-02-21 | 72d | TomGranot |
| `fix/home-dir-fallback` | 2026-02-21 | 72d | vaibhav / gavrielc |
| `fix/idle-preemption` | 2026-02-21 | 72d | gavrielc |
| `fix/unhandled-rejections-v2` | 2026-02-21 | 72d | gavrielc |
| `fix/container-mount-tampering` | 2026-02-22 | 71d | gavrielc |
| `fix/container-timezone` | 2026-02-22 | 71d | gavrielc |
| `fix/pass-assistant-name-to-container` | 2026-02-22 | 71d | gavrielc |
| `update-nanoclaw` | 2026-02-22 | 71d | gavrielc |

#### 🟡 Stale (30–60 days) — 1 branch

| Branch | Last Commit | Age | Author |
|--------|-------------|-----|--------|
| `merge-upstream-1.2.12` | 2026-03-09 | 56d | Darren Ross |

---

## Summary

| Scope | Repos Scanned | Open PRs | Bug/Security Issues | Stale Branches (>30d) | Very Stale (>60d) |
|-------|--------------|----------|---------------------|-----------------------|-------------------|
| slothlabs-coder (Neptune) | ⚠️ no access | — | — | — | — |
| invocap (Saturn) | ⚠️ no access | — | — | — | — |
| djsloth/nanoclaw | 1 | 0 | 0 | **21** | **20** |

**This week's focus:** Triage `security/sdk-env-secrets` (79 days, security-classified, unmerged) — merge, close, or document; then bulk-close the 19 other Feb-vintage branches that predate the Docker runtime migration and are now fully superseded, to reduce branch noise before next check.
