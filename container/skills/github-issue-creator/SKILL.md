---
name: github-issue-creator
description: Create well-structured GitHub issues from high-level task descriptions. Use this skill whenever the user asks to create issues, plan a sprint, break down a feature, or queue work for coding agents. Handles issue creation with titles, descriptions, subtasks, acceptance criteria, labels, and agent assignment. Ensures separation of concerns so each issue can be worked on independently without merge conflicts.
---

# GitHub Issue Creator

Create agent-ready GitHub issues from high-level intent. Issues are structured so coding agents (Copilot, Claude Code, etc.) can pick them up and execute autonomously.

## Prerequisites

All secrets are available as environment variables automatically — no sourcing required.

- `GITHUB_PAT_SLOTHLABS` — for SlothLabs repos (e.g. `slothlabs-ai/waveiq`)
- `GITHUB_PAT_INVOCAP` — for Invocap repos
- **IMPORTANT**: PATs must be **classic tokens with `repo` scope** — fine-grained PATs cannot assign Copilot coding agent and will silently fail
- Copilot coding agent must be **enabled in repository settings** for each repo
- `gh` CLI must be **v2.80.0 or later** for `@copilot` assignment support

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

### Step 1: Understand the Request

Parse the user's message for:
- **Scope**: Single issue or multi-issue sprint plan?
- **Repo**: Which repository? (infer from context or ask)
- **Intent**: What needs to be done at a high level?

If given a plan file (from `co-architect` skill), read it:
```bash
cat /tmp/architect-plan-PROJECT-DATE.json
```

### Step 2: Assess Current State (if planning multiple issues)

```bash
GH_TOKEN=$TOKEN gh repo clone $REPO /tmp/repo -- --depth 1
cd /tmp/repo

# File inventory
find . -type f -name "*.vue" -o -name "*.js" -o -name "*.ts" | head -50
cat package.json | jq '.dependencies, .devDependencies'

# Existing issues and PRs
GH_TOKEN=$TOKEN gh issue list --repo $REPO --state open
GH_TOKEN=$TOKEN gh pr list --repo $REPO --state open

# GitHub Projects board
GH_TOKEN=$TOKEN gh project item-list --owner OWNER --format json
```

### Step 3: Plan with Separation of Concerns

When creating multiple issues, ensure:

1. **No file conflicts** — each issue touches different files/modules
2. **Clear boundaries** — one issue = one branch = one PR
3. **Dependency order** — label issues that must be done sequentially
4. **Parallel-safe** — maximize issues that can run concurrently

### Step 4: Create Issues

```bash
GH_TOKEN=$TOKEN gh issue create \
  --repo $REPO \
  --title "Issue title — concise action description" \
  --body "$(cat <<'EOF'
## Context
Brief explanation of why this work is needed and where it fits in the project.

## Scope
Specific files and modules this issue touches:
- `path/to/file1.js`
- `path/to/file2.vue`

## Tasks
- [ ] Task 1 — specific actionable step
- [ ] Task 2 — specific actionable step
- [ ] Task 3 — specific actionable step

## Acceptance Criteria
- [ ] Criterion 1 — measurable/verifiable outcome
- [ ] Criterion 2 — measurable/verifiable outcome
- [ ] Tests pass (if applicable)

## Notes for Agent
- Branch from `main` (or specify base branch)
- Do NOT modify files outside the scope listed above
- Run `npm test` / `npm run lint` before marking complete
EOF
)" \
  --label "label1,label2"
```

### Step 5: Assign to Copilot Coding Agent

**Method 1: `gh issue edit` (preferred)**

```bash
GH_TOKEN=$TOKEN gh issue edit ISSUE_NUMBER \
  --repo $REPO \
  --add-assignee "@copilot"
```

If you get `'copilot-swe-agent' not found`, check:
- Is the PAT a **classic** token with `repo` scope?
- Is Copilot coding agent **enabled** in repo settings?
- Is `gh` CLI version 2.80.0+? (`gh --version`)

**Method 2: `gh agent-task create` (skips issue)**

```bash
cd /path/to/repo
GH_TOKEN=$TOKEN gh agent-task create --prompt "Description of work to do"
```

Note: Requires OAuth auth. If using PAT, use Method 1.

**Method 3: GraphQL API (fallback)**

```bash
# Get issue node ID
ISSUE_ID=$(GH_TOKEN=$TOKEN gh api graphql -f query='
  query {
    repository(owner: "OWNER", name: "REPO") {
      issue(number: ISSUE_NUMBER) { id }
    }
  }
' --jq '.data.repository.issue.id')

# Get Copilot agent user ID
COPILOT_ID=$(GH_TOKEN=$TOKEN gh api graphql -f query='
  query { user(login: "copilot-swe-agent") { id } }
' --jq '.data.user.id')

# Assign
GH_TOKEN=$TOKEN gh api graphql -f query='
  mutation {
    addAssigneesToAssignable(input: {
      assignableId: "'"$ISSUE_ID"'",
      assigneeIds: ["'"$COPILOT_ID"'"]
    }) {
      assignable { ... on Issue { number title } }
    }
  }
'
```

**Batch assignment:**

```bash
for ISSUE in 10 11 12 13; do
  GH_TOKEN=$TOKEN gh issue edit $ISSUE \
    --repo $REPO \
    --add-assignee "@copilot"
  echo "Assigned Copilot to issue #$ISSUE"
  sleep 2
done
```

### Step 6: Report Back

After creating issues, send the user:
- Issue numbers and titles
- Links to each issue
- Which issues can run in parallel vs sequential
- Estimated complexity per issue

## Label Conventions

| Label | Usage |
|-------|-------|
| `feature` | New functionality |
| `bugfix` | Bug fixes |
| `refactor` | Code improvement, no behavior change |
| `security` | Security-related changes |
| `testing` | Test additions or improvements |
| `docs` | Documentation updates |
| `priority:high` | Do first |
| `priority:medium` | Do after high priority |
| `priority:low` | Nice to have |
| `agent-ready` | Structured for autonomous agent execution |
| `blocked` | Depends on another issue |

## Issue Quality Checklist

Before creating any issue, verify:
- [ ] Title is a clear action (verb + noun)
- [ ] Scope lists specific files — no vague descriptions
- [ ] Tasks are concrete steps, not hand-wavy goals
- [ ] Acceptance criteria are testable
- [ ] No file overlap with other issues in the batch
- [ ] Agent notes specify branch strategy and constraints
