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

Parse the returned JSON. Fields: `rangeBase`, `rangeTip`, `upstreamHead`, `commits[]`. Each commit has: `sha`, `subject`, `author`, `date`, `files[]`, `diffstat`, `diffPreview` (first ~8 KB of the diff), `diffTruncated` (bool).

If `commits` is empty: tell the user "Already up to date with upstream — no pending commits." and stop.

Note: `diffPreview` is intentionally truncated. For borderline classifications you can read the full diff via `Bash`: `git show <sha>`.

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
