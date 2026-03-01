---
name: pr-reviewer
description: Review GitHub pull requests for code quality, security, consistency, and correctness. Use this skill whenever the user asks to review a PR, check a PR, look at changes, or assess agent output. Performs structured review with actionable feedback and approve/request-changes recommendation.
---

# PR Reviewer

Review pull requests with structured analysis. Designed to evaluate both human and agent-generated code against project standards.

## Prerequisites

All secrets are available as environment variables automatically — no sourcing required.

- `GITHUB_PAT_SLOTHLABS` — for SlothLabs repos (e.g. `slothlabs-ai/waveiq`)
- `GITHUB_PAT_INVOCAP` — for Invocap repos

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

### Step 1: Fetch PR Details

```bash
# PR metadata
GH_TOKEN=$TOKEN gh pr view PR_NUMBER --repo $REPO \
  --json title,body,additions,deletions,files,commits,baseRefName,headRefName

# Full diff
GH_TOKEN=$TOKEN gh pr diff PR_NUMBER --repo $REPO

# CI status
GH_TOKEN=$TOKEN gh pr checks PR_NUMBER --repo $REPO
```

### Step 2: Understand Context

Before reviewing code, understand:
- What issue does this PR address? (check PR body for issue references)
- What was the original intent/acceptance criteria?
- Is the base branch stale?

```bash
# Check linked issue
GH_TOKEN=$TOKEN gh issue view ISSUE_NUMBER --repo $REPO --json title,body
```

### Step 3: Review Checklist

#### Code Quality
- [ ] Functions are focused and reasonably sized
- [ ] Variable/function names are clear and consistent
- [ ] No dead code or commented-out blocks
- [ ] Error handling is present where needed
- [ ] No hardcoded values that should be config/env

#### Security
- [ ] No exposed secrets, API keys, or tokens
- [ ] User inputs are validated/sanitized
- [ ] API endpoints check authentication/authorization
- [ ] No SQL injection or XSS vulnerabilities
- [ ] Dependencies don't introduce known vulnerabilities

#### Architecture & Consistency
- [ ] Follows existing project patterns and conventions
- [ ] File placement matches project structure
- [ ] Imports are clean (no unused, no circular)
- [ ] State management follows established patterns (Vuex/Pinia, composables, etc.)
- [ ] API calls go through service layer, not directly in components

#### Testing
- [ ] New functionality has corresponding tests
- [ ] Existing tests still pass
- [ ] Edge cases are covered
- [ ] Test descriptions are clear

#### Scope
- [ ] Changes are limited to what the issue/PR describes
- [ ] No unrelated modifications
- [ ] No accidental file changes (formatting-only diffs, lockfile churn)

### Step 4: Generate Review

```markdown
## PR Review: #NUMBER — Title

### Summary
One paragraph: what this PR does and overall assessment.

### Verdict: ✅ APPROVE | 🔄 REQUEST CHANGES | ⚠️ APPROVE WITH COMMENTS

### Critical Issues (must fix)
- **[File:Line]** Description of issue and suggested fix

### Suggestions (should fix)
- **[File:Line]** Description and recommendation

### Nits (optional)
- **[File:Line]** Minor style/preference items

### What Looks Good
- Positive callouts — what was done well
```

### Step 5: Submit Review

```bash
# Comment only (informational)
GH_TOKEN=$TOKEN gh pr review PR_NUMBER \
  --repo $REPO \
  --comment \
  --body "REVIEW_CONTENT"

# Approve
GH_TOKEN=$TOKEN gh pr review PR_NUMBER \
  --repo $REPO \
  --approve \
  --body "REVIEW_CONTENT"

# Request changes
GH_TOKEN=$TOKEN gh pr review PR_NUMBER \
  --repo $REPO \
  --request-changes \
  --body "REVIEW_CONTENT"
```

### Step 6: Report to User

Send the user:
- Verdict (approve/changes needed)
- Count of critical vs minor issues
- Whether CI is passing
- Recommendation: merge, fix and re-review, or close

## Project-Specific Standards

### Vue.js / Vuetify Projects (WaveIQ, Invocap CRM)
- Components use `<script setup>` with Composition API
- Vuetify components preferred over custom UI elements
- Services in `/services/` directory, composables in `/composables/`
- API calls via service layer, never directly in components
- Supabase client initialized once, imported from config

### Express.js Backend
- Routes in `/routes/`, business logic in `/services/`
- Middleware for auth, validation, error handling
- Environment variables for all config (12-factor)
- Consistent error response format

## Agent-Specific Review Notes

When reviewing PRs from coding agents (Copilot, Claude Code):
- **Check for hallucinated imports** — agents sometimes import packages not in `package.json`
- **Verify API endpoints exist** — agents may call endpoints that don't exist yet
- **Watch for mock data left behind** — agents sometimes leave placeholder data
- **Check for duplicate code** — agents may reimplement existing utilities
- **Validate file paths** — agents occasionally create files in wrong directories
