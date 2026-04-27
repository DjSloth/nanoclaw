---
title: /check-upstream — read-only upstream analysis with cherry-pick suggestions
date: 2026-04-27
status: approved
---

# /check-upstream

A NanoClaw slash command that diffs `upstream/main` against the user's fork and produces a risk-rated cherry-pick report. Read-only complement to the existing `/update` skill, which auto-merges and has previously broken the repo.

## Goal

Show the user what's new in `upstream` (`qwibitai/nanoclaw`) that isn't in their fork (`origin = DjSloth/nanoclaw`), classify each pending commit by how likely it is to disrupt their customizations, and emit a markdown report with ready-to-paste `git cherry-pick` commands. The user decides what to apply, manually, after the report is written.

## Non-goals

- Applying upstream changes (no merge, no cherry-pick, no rebase).
- Pushing anything anywhere.
- Modifying the working tree.
- Replacing or deprecating `/update`.
- Modifying `upstream` history or PR'ing back.

## Architecture

Tri-model orchestration:

| Model | Role | Why |
|-------|------|-----|
| Haiku | Raw data extraction | Cheap, fast, deterministic shell + git work |
| Opus | Risk classification | Judgment call; needs to reason about user's customization patterns |
| Sonnet | Report rendering + git pre-flight | Mid-tier work; precise file writes and git checks |

Orchestrator is the user's main Claude Code session (also Opus). It dispatches Haiku and Sonnet via the `Agent` tool with `model=` overrides.

```
Opus orchestrator
  ├─ Sonnet: pre-flight + fetch
  ├─ Haiku: extract pending commits as JSON
  ├─ Opus: classify by risk
  └─ Sonnet: write markdown report, print summary
```

## Flow

### 1. Pre-flight (Sonnet subagent)

- Verify `upstream` remote exists. If missing, add it: `git remote add upstream git@github.com:qwibitai/nanoclaw.git`.
- Verify `origin` remote exists. If missing, abort with error (this skill assumes a fork).
- Compare `main` against `origin/main`. If diverged, print a one-line note (do NOT auto-fix): "Local main and origin/main are out of sync — recommend resolving before cherry-picks."
- If working tree has uncommitted changes, print a one-line note: "Uncommitted changes detected — cherry-picks should wait until tree is clean." Do not abort.

### 2. Fetch (Sonnet subagent)

- `git fetch upstream`
- `git fetch origin`

### 3. Extract pending commits (Haiku subagent)

- Run `git cherry main upstream/main`. Lines beginning with `+` are pending (not yet integrated, accounting for cherry-picks via patch-ID); `-` lines are already integrated and excluded.
- Optional `--since <duration>` skill arg (e.g., `7d`, `30d`) filters commits by date.
- For each pending commit, collect:
  - `sha` (full)
  - `subject`
  - `author`
  - `date`
  - `files` (list of changed paths from `git show --name-only`)
  - `diff` (full unified diff from `git show`)
- Emit JSON to stdout:

```json
{
  "rangeBase": "main",
  "rangeTip": "upstream/main",
  "upstreamHead": "f8c3d02",
  "commits": [
    {"sha": "...", "subject": "...", "author": "...", "date": "...", "files": ["..."], "diff": "..."}
  ]
}
```

### 4. Classify by risk (Opus orchestrator, in-context)

- Derive **protected set**: files touched in *truly* fork-only commits (patch-ID-aware, so already-cherry-picked-from-upstream commits are excluded).
  ```
  git cherry upstream/main main | awk '/^\+/ {print $2}' \
    | xargs -n1 git show --name-only --pretty=format: \
    | sort -u
  ```
  Reverse direction of the pending-commits query: `+` lines here are commits in `main` whose patch-ID does not appear in `upstream`, i.e., genuine local customizations.
- Merge with optional override file at `.claude/skills/check-upstream/protected.json`:
  ```json
  { "alwaysHigh": ["container/build.sh", "src/router.ts"] }
  ```
- Classify each commit:

| Risk | Trigger |
|------|---------|
| 🟢 Low | Touches only files outside the protected set; pure additions (new files in untouched dirs); patch/minor `package.json` bumps |
| 🟡 Medium | Touches files in the protected set in non-overlapping line ranges; refactors of files the user depends on indirectly; new exported APIs in `src/` |
| 🔴 High | Touches files in the override `alwaysHigh` list; touches files where the user has fork-only edits in the same hunks; major version bumps; deletes files the user has added to; touches security-sensitive paths (`src/router.ts`, refusal logic, container build scripts) |

- For each commit, also produce a `reason` string and `suggestedAction` (`cherry-pick` / `review` / `skip`).

### 5. Render report (Sonnet subagent)

- Write to `docs/upstream-checks/YYYY-MM-DD.md` (overwrite if same-day re-run).
- Format: see "Report format" below.
- Print summary inline to terminal:
  ```
  Upstream check complete. 14 pending commits: 🟢 6  🟡 5  🔴 3.
  Report: docs/upstream-checks/2026-04-27.md
  ```

## Report format

```markdown
# Upstream Check — 2026-04-27

**Range:** `main..upstream/main` · 14 pending commits · upstream HEAD: `f8c3d02`

## Summary
- 🟢 Low risk: 6 — safe to cherry-pick
- 🟡 Medium risk: 5 — review diff first
- 🔴 High risk: 3 — likely conflicts with your customizations

## 🟢 Low risk

| SHA | Subject | Files |
|-----|---------|-------|
| `abc123` | docs(readme): fix typo | `README.md` |
| `def456` | feat(skills): add /weather skill | `.claude/skills/add-weather/**` |

Apply all low-risk in one shot:

    git cherry-pick abc123 def456 ...

## 🟡 Medium risk

### `ghi789` — refactor(router): extract message normalization
**Files:** `src/router.ts`
**Reason:** You've modified `src/router.ts` (security refusal). Hunks may not overlap — diff before applying.
**Suggested:** review

    git show ghi789
    git cherry-pick ghi789  # if hunks don't conflict

(continued per-commit…)

## 🔴 High risk

### `jkl012` — feat(main): rewrite main group prompt
**Files:** `groups/main/CLAUDE.md`
**Reason:** Direct conflict with your Triad orchestrator commit (06b16bc). Skip unless you want to manually merge.
**Suggested:** skip

(continued per-commit…)

## Protected files (auto-derived)
- `groups/main/CLAUDE.md`
- `container/skills/places/**`
- `container/skills/surfline/**`
…

## Protected files (override)
- `container/build.sh`
- `src/router.ts`
```

## File layout

```
.claude/skills/check-upstream/
├── SKILL.md
├── scripts/
│   └── extract-pending.sh       # Haiku runs this; emits JSON to stdout
└── protected.json               # COMMITTED — user's high-risk override list
```

`protected.json` is committed to the fork because it reflects fork identity (which files the user wants always treated as high-risk), not per-machine preference.

## Edge cases

- **No upstream remote:** auto-add it pointing at `qwibitai/nanoclaw`.
- **No `origin` remote:** abort with clear message.
- **Local diverged from origin:** warn, proceed (read-only skill, doesn't matter for the analysis).
- **Uncommitted changes:** warn, proceed.
- **Zero pending commits:** print "Already up to date with upstream" and skip report write.
- **Hundreds of pending commits:** still works, but recommend `--since 30d` in the warning.
- **`git cherry` fails (e.g., no common ancestor):** fall back to `git log upstream/main --not main` and note the limitation in the report header.

## Security note

The user's `origin` remote currently has a GitHub PAT embedded in the URL. This skill does not touch remote URLs, but a follow-up cleanup task should rotate that token and switch `origin` to SSH (the `fork` remote already points at the SSH URL of the same repo).

## SKILL.md frontmatter (per project contribution rules)

```yaml
---
name: check-upstream
description: "Read-only upstream analysis. Diffs upstream/main against your fork and produces a risk-rated cherry-pick report. Triggers on \"check upstream\", \"upstream diff\", \"what's new upstream\"."
version: 1.0.0
allowed-tools: Bash, Read, Write, Edit, Agent
invocation: slash
---
```
