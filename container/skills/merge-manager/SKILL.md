---
name: merge-manager
description: Manage PR merges, detect and resolve merge conflicts, and maintain clean git history. Use this skill whenever the user asks to merge a PR, fix conflicts, resolve merge issues, rebase a branch, or clean up branches after merge. Handles both simple fast-forward merges and complex conflict resolution.
---

# Merge Manager

Handle PR merges, conflict resolution, and branch cleanup. Ensures clean git history and prevents broken merges.

## Prerequisites

All secrets are available as environment variables automatically — no sourcing required.

- `GITHUB_PAT_SLOTHLABS` — for SlothLabs repos (e.g. `slothlabs-ai/waveiq`)
- `GITHUB_PAT_INVOCAP` — for Invocap repos
- SSH configured for `github-slothlabs` and `github-invocap` host aliases (for git push)

Choose the right token for the repo:
```bash
# SlothLabs
TOKEN=$GITHUB_PAT_SLOTHLABS
REPO=slothlabs-ai/waveiq

# Invocap
TOKEN=$GITHUB_PAT_INVOCAP
REPO=OWNER/REPO
```

## Workflow

### Step 1: Pre-Merge Assessment

```bash
# Check PR status
GH_TOKEN=$TOKEN gh pr view PR_NUMBER --repo $REPO \
  --json mergeable,mergeStateStatus,statusCheckRollup,reviewDecision

# Check for conflicts
GH_TOKEN=$TOKEN gh pr view PR_NUMBER --repo $REPO --json mergeable
# mergeable: "MERGEABLE", "CONFLICTING", or "UNKNOWN"

# Check CI status
GH_TOKEN=$TOKEN gh pr checks PR_NUMBER --repo $REPO

# Check review approval
GH_TOKEN=$TOKEN gh pr view PR_NUMBER --repo $REPO --json reviewDecision
```

### Step 2: Decision Matrix

| Mergeable | CI | Review | Action |
|-----------|------|--------|--------|
| ✅ Clean | ✅ Pass | ✅ Approved | Merge immediately |
| ✅ Clean | ✅ Pass | ⏳ Pending | Ask user to approve or merge anyway |
| ✅ Clean | ❌ Fail | Any | Report failures, do NOT merge |
| ❌ Conflicts | Any | Any | Resolve conflicts first (Step 3) |
| ⏳ Unknown | Any | Any | Wait and retry, or fetch and check locally |

### Step 3: Conflict Resolution

When conflicts are detected:

```bash
cd /tmp
GH_TOKEN=$TOKEN gh repo clone $REPO merge-workspace
cd merge-workspace

# Fetch PR branch
git fetch origin pull/PR_NUMBER/head:pr-branch
git checkout pr-branch

# Attempt rebase on main
git fetch origin main
git rebase origin/main
```

#### If rebase has conflicts:

```bash
# List conflicted files
git diff --name-only --diff-filter=U
git diff --check
```

**Conflict resolution strategy:**

1. **Auto-resolvable** (formatting, imports, non-overlapping changes):
   - Resolve automatically
   - Document what was resolved

2. **Logic conflicts** (same function modified differently):
   - Analyze both versions
   - Determine which is newer/correct based on commit messages and issue context
   - If unclear, report to user with both versions and ask for decision

3. **Structural conflicts** (file moved/renamed + modified):
   - These require human decision
   - Report the conflict with full context

After resolving:

```bash
git add resolved_file.js
git rebase --continue
git push --force-with-lease origin pr-branch
```

### Step 4: Execute Merge

```bash
# Squash merge (preferred for agent PRs — clean history)
GH_TOKEN=$TOKEN gh pr merge PR_NUMBER \
  --repo $REPO \
  --squash \
  --delete-branch

# Regular merge (preserves commit history)
GH_TOKEN=$TOKEN gh pr merge PR_NUMBER \
  --repo $REPO \
  --merge \
  --delete-branch

# Rebase merge (linear history)
GH_TOKEN=$TOKEN gh pr merge PR_NUMBER \
  --repo $REPO \
  --rebase \
  --delete-branch
```

**Merge strategy selection:**
- **Squash**: Default for agent-generated PRs (cleans up messy agent commits)
- **Merge commit**: When preserving individual commits matters
- **Rebase**: When linear history is preferred and commits are clean

### Step 5: Post-Merge Cleanup

```bash
# Delete remote branch if --delete-branch wasn't used
GH_TOKEN=$TOKEN gh api -X DELETE repos/$REPO/git/refs/heads/BRANCH_NAME

# Close related issues if not auto-closed
GH_TOKEN=$TOKEN gh issue close ISSUE_NUMBER --repo $REPO --reason completed

# Check for stale branches
GH_TOKEN=$TOKEN gh api repos/$REPO/branches --jq '.[].name' | grep -v main | grep -v develop
```

### Step 6: Cascading Merge Check

After merging, check if other open PRs are now conflicted:

```bash
GH_TOKEN=$TOKEN gh pr list --repo $REPO --state open --json number,title,mergeable
# Notify user of any that became conflicting
```

### Step 7: Report to User

Send the user:
- Merge status (success/failure)
- Merge method used (squash/merge/rebase)
- Branch cleanup status
- Any cascading conflicts detected in other PRs
- Link to the merged PR

## Batch Merge

When multiple PRs need merging (e.g., after a sprint):

1. List all ready PRs: `gh pr list --state open --json number,title,mergeable,statusCheckRollup`
2. Sort by dependency order (base branches first)
3. Merge sequentially, checking for cascading conflicts after each
4. Report summary of all merges

```bash
for PR in 34 35 36; do
  echo "Merging PR #$PR..."
  GH_TOKEN=$TOKEN gh pr merge $PR --repo $REPO --squash --delete-branch
  sleep 2
  GH_TOKEN=$TOKEN gh pr list --repo $REPO --state open --json number,mergeable
done
```

## Troubleshooting

### "Not mergeable" but no visible conflicts
- Branch may be out of date: `git fetch origin main && git rebase origin/main`
- Required status checks may be pending: wait for CI
- Branch protection rules may require reviews

### Force push after conflict resolution fails
- Check branch protection: `gh api repos/$REPO/branches/BRANCH/protection`
- May need admin override or temporarily disabled protection

### Merge queue issues
- Some repos use merge queues — PR enters queue rather than merging immediately
- Check: `gh pr view PR_NUMBER --json mergeStateStatus`
- If queued, just wait — don't retry
