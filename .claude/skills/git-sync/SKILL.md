---
name: git-sync
description: Pull, commit pending changes with an auto-written message, and push — leaving a clean slate.
version: 1.0.0
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
invocation: /git-sync
---

Sync the local repo to a clean state: commit any pending changes, pull latest, push.

## Steps

### 1. Check status

```bash
git status --short
git log --oneline -5
```

If the working tree is already clean and the branch is up-to-date with remote, report that and stop — nothing to do.

### 2. Commit local changes (if any)

If there are staged or unstaged changes:

a. **Run `/docs-sync`** first — the pre-commit hook requires docs to be current before any commit. Invoke the docs-sync skill now.

b. **Stage all changes:**
```bash
git add -A
```

c. **Read the diff to write a commit message:**
```bash
git diff --staged --stat
git diff --staged
```

Write a conventional commit message that accurately describes the changes. Use the type that fits best (`feat`, `fix`, `chore`, `docs`, `refactor`). Keep it under 72 characters. If the diff is mixed (docs + code), use `chore:`.

d. **Commit:**
```bash
git commit -m "$(cat <<'EOF'
<your message here>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 3. Pull with rebase

```bash
git pull --rebase
```

If there are rebase conflicts, resolve them before continuing. After resolving:
```bash
git rebase --continue
```

### 4. Push

```bash
git push
```

### 5. Confirm clean slate

```bash
git status --short
git log --oneline -3
```

Report: commits pushed, current HEAD, and that the working tree is clean.

## Guard rails

- Never force-push (`--force`, `--force-with-lease`) without explicit user instruction
- Never push to a protected branch (main/master) if it requires a PR — check remote rules first
- If `git pull --rebase` produces conflicts you cannot resolve automatically, stop and report them to the user
- Do not `git add` files that look like secrets (`.env`, `credentials.*`, `*.pem`, `*.key`)
