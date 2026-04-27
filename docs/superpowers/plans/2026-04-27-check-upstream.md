# /check-upstream Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a read-only NanoClaw slash command `/check-upstream` that diffs `upstream/main` against the user's fork and produces a risk-rated cherry-pick report.

**Architecture:** Single skill directory under `.claude/skills/check-upstream/` containing a `SKILL.md` orchestrator and one shell helper. The orchestrator (Opus) dispatches a Haiku subagent to extract pending commits as JSON, classifies risk in-context, then dispatches a Sonnet subagent to render a markdown report under `docs/upstream-checks/`.

**Tech Stack:** Bash, `git cherry` (patch-ID-aware diff), `jq` (JSON construction), Claude Code `Agent` tool with `model=` override for tri-model orchestration.

**Spec:** `docs/superpowers/specs/2026-04-27-check-upstream-design.md`

---

## File Structure

| File | Purpose |
|------|---------|
| `.claude/skills/check-upstream/SKILL.md` | Orchestrator instructions for Opus; numbered flow |
| `.claude/skills/check-upstream/scripts/extract-pending.sh` | Haiku-runnable; emits JSON of pending upstream commits |
| `.claude/skills/check-upstream/protected.json` | Committed override list (`alwaysHigh: [...]`) |
| `docs/upstream-checks/` | Output directory for generated reports (created lazily) |

---

## Task 1: Scaffold skill directory and protected.json

**Files:**
- Create: `.claude/skills/check-upstream/protected.json`
- Create: `.claude/skills/check-upstream/scripts/.gitkeep`

- [ ] **Step 1: Create directory tree**

```bash
mkdir -p .claude/skills/check-upstream/scripts
touch .claude/skills/check-upstream/scripts/.gitkeep
```

- [ ] **Step 2: Write `protected.json` with starter override list**

Path: `.claude/skills/check-upstream/protected.json`

```json
{
  "alwaysHigh": [
    "src/router.ts",
    "container/build.sh",
    "groups/main/CLAUDE.md"
  ],
  "comment": "Files always treated as high-risk regardless of auto-derived protection. Add files here that you've heavily customized or that are security-sensitive."
}
```

Rationale for the starter list: `src/router.ts` contains the security refusal logic the user has customized; `container/build.sh` is build infra that has caused trouble historically; `groups/main/CLAUDE.md` is the user's main group prompt (Triad orchestrator).

- [ ] **Step 3: Verify**

Run: `cat .claude/skills/check-upstream/protected.json | jq .`
Expected: Valid JSON output with `alwaysHigh` array.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/check-upstream/protected.json .claude/skills/check-upstream/scripts/.gitkeep
git commit -m "feat(check-upstream): scaffold skill directory with protected.json

Starter override list for files always treated as high-risk during
upstream cherry-pick analysis.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Write `extract-pending.sh`

**Files:**
- Create: `.claude/skills/check-upstream/scripts/extract-pending.sh`

This script is invoked by the Haiku subagent. It outputs a single JSON object to stdout containing all pending upstream commits and their diffs. Optional `--since <duration>` arg filters by date.

- [ ] **Step 1: Write the script**

Path: `.claude/skills/check-upstream/scripts/extract-pending.sh`

```bash
#!/usr/bin/env bash
# Extract pending upstream commits as JSON.
# Usage: extract-pending.sh [--since <git-date-spec>]
# Output: JSON to stdout. Errors to stderr; exit non-zero on failure.

set -euo pipefail

SINCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Verify required tooling.
command -v jq >/dev/null || { echo "jq required" >&2; exit 3; }
command -v git >/dev/null || { echo "git required" >&2; exit 3; }

# Verify upstream remote exists.
if ! git rev-parse --verify upstream/main >/dev/null 2>&1; then
  echo "upstream/main not found — fetch upstream before running" >&2
  exit 4
fi

UPSTREAM_HEAD=$(git rev-parse upstream/main)

# git cherry main upstream/main marks pending commits with '+'.
# Already-cherry-picked commits (matching patch-id) get '-' and are skipped.
PENDING_SHAS=$(git cherry main upstream/main | awk '/^\+/ {print $2}')

# Optional date filter.
if [[ -n "$SINCE" ]]; then
  FILTERED=""
  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    if git log -1 --since="$SINCE" --format=%H "$sha" | grep -q .; then
      FILTERED+="$sha"$'\n'
    fi
  done <<< "$PENDING_SHAS"
  PENDING_SHAS="$FILTERED"
fi

# Build JSON. Use jq for safe escaping.
COMMITS_JSON="[]"
while IFS= read -r sha; do
  [[ -z "$sha" ]] && continue
  subject=$(git show --no-patch --format=%s "$sha")
  author=$(git show --no-patch --format=%an "$sha")
  date=$(git show --no-patch --format=%aI "$sha")
  files_json=$(git show --name-only --pretty=format: "$sha" | grep -v '^$' | jq -R . | jq -s .)
  diff=$(git show --pretty=format: "$sha")

  COMMITS_JSON=$(jq \
    --arg sha "$sha" \
    --arg subject "$subject" \
    --arg author "$author" \
    --arg date "$date" \
    --argjson files "$files_json" \
    --arg diff "$diff" \
    '. + [{sha: $sha, subject: $subject, author: $author, date: $date, files: $files, diff: $diff}]' \
    <<< "$COMMITS_JSON")
done <<< "$PENDING_SHAS"

jq -n \
  --arg rangeBase "main" \
  --arg rangeTip "upstream/main" \
  --arg upstreamHead "$UPSTREAM_HEAD" \
  --argjson commits "$COMMITS_JSON" \
  '{rangeBase: $rangeBase, rangeTip: $rangeTip, upstreamHead: $upstreamHead, commits: $commits}'
```

- [ ] **Step 2: Make executable**

```bash
chmod +x .claude/skills/check-upstream/scripts/extract-pending.sh
```

- [ ] **Step 3: Verify shellcheck passes (if available)**

Run: `command -v shellcheck && shellcheck .claude/skills/check-upstream/scripts/extract-pending.sh || echo "shellcheck not installed, skipping"`
Expected: No errors. If shellcheck not installed, skip silently.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/check-upstream/scripts/extract-pending.sh
git commit -m "feat(check-upstream): add extract-pending.sh

Emits JSON of pending upstream commits using git cherry for
patch-ID-aware filtering. Used by the Haiku subagent during
/check-upstream invocation.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Verify `extract-pending.sh` against real divergence

The user's repo currently has 14 pending commits between `main` and `upstream/main` (verified during brainstorming). This is a real-world test fixture — use it.

- [ ] **Step 1: Ensure upstream is fetched**

Run: `git fetch upstream`
Expected: Either "Already up to date" or a fetch summary.

- [ ] **Step 2: Run the script and capture output**

Run: `./.claude/skills/check-upstream/scripts/extract-pending.sh > /tmp/check-upstream-test.json`
Expected: Exit 0, no stderr output.

- [ ] **Step 3: Validate JSON structure**

Run:
```bash
jq -e '.rangeBase == "main" and .rangeTip == "upstream/main" and (.upstreamHead | length == 40) and (.commits | type == "array")' /tmp/check-upstream-test.json
```
Expected: `true`. If `false` or error, the JSON shape is wrong.

- [ ] **Step 4: Validate commit count is non-zero**

Run: `jq '.commits | length' /tmp/check-upstream-test.json`
Expected: A positive integer (was 14 at spec time; may differ now if user has cherry-picked since).

- [ ] **Step 5: Validate each commit has required fields**

Run:
```bash
jq -e '.commits | all(has("sha") and has("subject") and has("author") and has("date") and has("files") and has("diff"))' /tmp/check-upstream-test.json
```
Expected: `true`.

- [ ] **Step 6: Test --since filter**

Run: `./.claude/skills/check-upstream/scripts/extract-pending.sh --since 7d > /tmp/check-upstream-test-7d.json && jq '.commits | length' /tmp/check-upstream-test-7d.json`
Expected: A non-negative integer, ≤ the unfiltered count from Step 4.

- [ ] **Step 7: Test missing-upstream error path**

Run: `git remote rename upstream upstream_backup && ./.claude/skills/check-upstream/scripts/extract-pending.sh; rc=$?; git remote rename upstream_backup upstream; echo "exit code: $rc"`
Expected: Non-zero exit code (4), stderr message about upstream not found. The remote is restored after.

- [ ] **Step 8: No commit (this task is verification only)**

---

## Task 4: Write `SKILL.md`

**Files:**
- Create: `.claude/skills/check-upstream/SKILL.md`

This is the orchestrator instruction set. It tells Opus how to: pre-flight, fetch, dispatch Haiku for extraction, classify in-context, dispatch Sonnet for report rendering.

- [ ] **Step 1: Write the skill file**

Path: `.claude/skills/check-upstream/SKILL.md`

````markdown
---
name: check-upstream
description: "Read-only upstream analysis. Diffs upstream/main against your fork and produces a risk-rated cherry-pick report. Triggers on \"check upstream\", \"upstream diff\", \"what's new upstream\"."
version: 1.0.0
allowed-tools: Bash, Read, Write, Edit, Agent
invocation: slash
---

# Check Upstream

Read-only complement to `/update`. Produces a markdown report of pending upstream changes with risk-rated cherry-pick suggestions. Never modifies the working tree, never auto-merges, never pushes.

**Principle:** This skill exists because `/update` has previously broken the repo by auto-merging. Stay read-only. The user decides what to apply.

**Optional arg:** `--since <duration>` (e.g., `7d`, `30d`) filters pending commits by date.

## 1. Pre-flight (dispatch Sonnet)

Use the `Agent` tool with `subagent_type=general-purpose`, `model=sonnet`, prompt:

> Run these commands in sequence and report the results in one paragraph:
> 1. `git remote get-url upstream || echo "MISSING"` — if MISSING, run `git remote add upstream git@github.com:qwibitai/nanoclaw.git`.
> 2. `git remote get-url origin || echo "MISSING"` — if MISSING, abort with error.
> 3. `git status --porcelain` — note whether working tree is clean.
> 4. `git rev-list --left-right --count main...origin/main` — note any local↔origin drift.
> Output format: a single line per check, prefixed with the check name.

Read the result. If origin is missing, stop and tell the user the skill needs an `origin` remote. Otherwise note any warnings inline (uncommitted changes, drift) and continue.

## 2. Fetch (dispatch Sonnet)

Use the `Agent` tool with `subagent_type=general-purpose`, `model=sonnet`, prompt:

> Run `git fetch upstream && git fetch origin`. Report any errors.

## 3. Extract pending commits (dispatch Haiku)

Use the `Agent` tool with `subagent_type=general-purpose`, `model=haiku`, prompt:

> Run `./.claude/skills/check-upstream/scripts/extract-pending.sh${SINCE_ARG}` and return its stdout verbatim. If the script exits non-zero, return the stderr.

Where `${SINCE_ARG}` is ` --since <duration>` if the user passed `--since`, otherwise empty.

Parse the returned JSON. Fields: `rangeBase`, `rangeTip`, `upstreamHead`, `commits[]`.

If `commits` is empty: tell the user "Already up to date with upstream — no pending commits." and stop.

## 4. Derive protected set (do this in-context)

Use the `Bash` tool to run:

```bash
git cherry upstream/main main | awk '/^\+/ {print $2}' \
  | xargs -n1 -I{} git show --name-only --pretty=format: {} 2>/dev/null \
  | sort -u | grep -v '^$'
```

This is the auto-derived protected set: files touched in commits that exist in `main` but whose patch-ID does NOT appear in `upstream` — i.e., genuine local customizations.

Use the `Read` tool on `.claude/skills/check-upstream/protected.json` to get the override list (`alwaysHigh` array).

## 5. Classify each commit by risk (do this in-context)

For each commit in the JSON from step 3, assign:

- 🔴 **High** if any of:
  - any file matches an entry in `alwaysHigh` (exact path or glob)
  - any file appears in the auto-derived protected set AND the diff hunks overlap with the user's fork-only edits to that file (use your judgment from reading the diff)
  - the commit is a major version bump in `package.json`
  - the commit deletes a file that the user has added to (check via `git log main --not upstream/main -- <file>`)
  - the commit touches `src/router.ts` or other security-sensitive paths

- 🟡 **Medium** if any of:
  - touches a file in the protected set but in non-overlapping line ranges
  - refactors a file the user depends on without changing its public interface (judgment call)
  - introduces a new exported API in `src/`

- 🟢 **Low** if all files are outside the protected set; pure additions (new files in untouched directories); patch/minor `package.json` bumps.

For each commit, write a one-sentence `reason` and a `suggestedAction` of `cherry-pick`, `review`, or `skip`.

## 6. Render report (dispatch Sonnet)

Use the `Agent` tool with `subagent_type=general-purpose`, `model=sonnet`, prompt:

> Write the following markdown to `docs/upstream-checks/<TODAY>.md`, creating the directory if needed. Today's date in YYYY-MM-DD format is: <TODAY>.
>
> Markdown content:
>
> ```markdown
> <RENDERED_REPORT>
> ```
>
> After writing, output only the path of the file you wrote.

`<RENDERED_REPORT>` follows this template:

```markdown
# Upstream Check — <YYYY-MM-DD>

**Range:** `main..upstream/main` · <N> pending commits · upstream HEAD: `<short-sha>`

## Summary
- 🟢 Low risk: <count> — safe to cherry-pick
- 🟡 Medium risk: <count> — review diff first
- 🔴 High risk: <count> — likely conflicts with your customizations

## 🟢 Low risk

| SHA | Subject | Files |
|-----|---------|-------|
| `<short-sha>` | <subject> | `<files-summary>` |
…

Apply all low-risk in one shot:

    git cherry-pick <sha1> <sha2> …

## 🟡 Medium risk

### `<short-sha>` — <subject>
**Files:** `<files>`
**Reason:** <reason>
**Suggested:** review

    git show <sha>
    git cherry-pick <sha>  # if hunks don't conflict

…

## 🔴 High risk

### `<short-sha>` — <subject>
**Files:** `<files>`
**Reason:** <reason>
**Suggested:** skip

…

## Protected files (auto-derived)
- `<file>`
…

## Protected files (override)
- `<file>`
…
```

## 7. Print summary inline

After Sonnet returns the report path, print:

```
Upstream check complete. <N> pending commits: 🟢 <low>  🟡 <med>  🔴 <high>.
Report: <path>
```

If there were any pre-flight warnings (uncommitted changes, local↔origin drift), append them as bullet points below the summary.

## Troubleshooting

- **`upstream/main` not found:** the pre-flight should auto-add the remote. If it didn't, check `git remote -v` manually.
- **Extraction script fails:** run it manually with `./.claude/skills/check-upstream/scripts/extract-pending.sh` and read the stderr.
- **`jq` missing:** install with `apt install jq` (Linux) or `brew install jq` (macOS).
- **Hundreds of pending commits:** re-invoke with `--since 30d` or shorter.

## Non-goals

This skill does NOT:
- Apply any cherry-picks.
- Modify the working tree.
- Push anything to `origin` or `upstream`.
- Replace `/update` (which remains the auto-merge path for users who want it).
````

- [ ] **Step 2: Verify the file is readable**

Run: `head -10 .claude/skills/check-upstream/SKILL.md`
Expected: YAML frontmatter with `name: check-upstream`.

- [ ] **Step 3: Verify frontmatter completeness per project rules**

Run:
```bash
grep -E "^(name|description|version|allowed-tools|invocation):" .claude/skills/check-upstream/SKILL.md | wc -l
```
Expected: `5` (all required frontmatter fields per `.claude/rules/contributions.md`).

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/check-upstream/SKILL.md
git commit -m "feat(check-upstream): add SKILL.md orchestrator

Tri-model flow: Sonnet for pre-flight + fetch + report write,
Haiku for raw extraction, Opus for risk classification.
Read-only; never modifies working tree or pushes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Manual end-to-end smoke test

Skills cannot be unit-tested in isolation; this task is a manual invocation against the user's real repo state.

- [ ] **Step 1: Ensure clean test conditions**

Run: `git status --porcelain | wc -l`
Note: There may be uncommitted changes (e.g., `groups/main/CLAUDE.md`). The skill should handle this gracefully (warn, proceed). Do NOT abort the test on this — it's part of what we're testing.

- [ ] **Step 2: Invoke the skill**

In the Claude Code session, invoke: `/check-upstream`

- [ ] **Step 3: Verify pre-flight output**

Expect inline: notes about the working-tree state and any local↔origin drift. No errors.

- [ ] **Step 4: Verify extraction**

Expect: Haiku subagent runs the script, returns JSON. Orchestrator parses it without error.

- [ ] **Step 5: Verify report file is created**

Run: `ls -la docs/upstream-checks/`
Expected: A file named `<today>.md` exists.

- [ ] **Step 6: Verify report contents**

Run: `head -20 docs/upstream-checks/$(date +%Y-%m-%d).md`
Expected:
- Title line with today's date.
- Range line with commit count > 0.
- Summary section with three risk-tier counts that sum to total pending commits.

- [ ] **Step 7: Verify protected set is sensible**

Run: `grep -A 20 "Protected files (auto-derived)" docs/upstream-checks/$(date +%Y-%m-%d).md`
Expected: Includes files the user has actually modified on their fork (e.g., `groups/main/CLAUDE.md`, `container/skills/places/**`, etc., based on auto-memory `project_darren_skills.md`).

- [ ] **Step 8: Verify no working tree changes**

Run: `git status --porcelain | grep -v "^.. groups/main/CLAUDE.md$" | grep -v "^?? docs/upstream-checks/"`
Expected: Empty output (only the pre-existing dirty file and the new report should be present; no other changes).

- [ ] **Step 9: Try the --since arg**

In the Claude Code session, invoke: `/check-upstream --since 14d`
Expected: Report has fewer or equal commits compared to the unfiltered run.

- [ ] **Step 10: No commit**

The generated report files in `docs/upstream-checks/` are useful artifacts but not part of the skill's source. Add a `.gitignore` entry in Task 6.

---

## Task 6: Add gitignore entry and update CLAUDE.md skill table

**Files:**
- Modify: `.gitignore`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Check `.gitignore` exists and read its current content**

Run: `cat .gitignore | head -20`

- [ ] **Step 2: Add `docs/upstream-checks/` to `.gitignore`**

Append to `.gitignore`:

```
# /check-upstream skill output (per-run reports)
docs/upstream-checks/
```

- [ ] **Step 3: Add the skill to the `Skills` table in `CLAUDE.md`**

Find the existing skills table in `CLAUDE.md` (currently includes `/setup`, `/customize`, `/debug`, `/update`, `/qodo-pr-resolver`, `/get-qodo-rules`, `/docs-sync`, `/git-sync`).

Insert a new row immediately after the `/update` row:

```markdown
| `/check-upstream` | Read-only upstream diff with risk-rated cherry-pick suggestions (alternative to `/update`) |
```

- [ ] **Step 4: Verify**

Run: `grep "check-upstream" CLAUDE.md`
Expected: One line matching the new table row.

- [ ] **Step 5: Commit**

```bash
git add .gitignore CLAUDE.md
git commit -m "chore(check-upstream): gitignore reports, document skill in CLAUDE.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

Spec coverage check (run mentally against `docs/superpowers/specs/2026-04-27-check-upstream-design.md`):

- ✅ Goal: Tasks 1-6 build a read-only `/check-upstream` skill.
- ✅ Tri-model architecture: Task 4's SKILL.md dispatches Haiku (extract) and Sonnet (pre-flight, fetch, report write); Opus orchestrates and classifies.
- ✅ Pre-flight: Task 4 § 1.
- ✅ Fetch: Task 4 § 2.
- ✅ Extract via `git cherry`: Task 2's script + Task 4 § 3.
- ✅ Risk classification with auto-derived protected set: Task 4 §§ 4-5; uses `git cherry upstream/main main` (reverse direction) for patch-ID-aware derivation per spec correction.
- ✅ Override file: Task 1 creates `protected.json`; Task 4 § 4 reads it.
- ✅ Report at `docs/upstream-checks/YYYY-MM-DD.md`: Task 4 § 6.
- ✅ Inline summary: Task 4 § 7.
- ✅ Edge cases (no upstream, no origin, dirty tree, zero commits, --since): Tasks 2, 3, 4, 5.
- ✅ Frontmatter per `.claude/rules/contributions.md`: Task 4 Step 3.

Placeholder scan: no TBD/TODO/"implement later" entries. Every code step has actual code.

Type/identifier consistency: `protected.json` schema (`alwaysHigh` array) referenced consistently across Task 1 and Task 4 § 4. Script invocation path consistent across Tasks 2-5.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-27-check-upstream.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
