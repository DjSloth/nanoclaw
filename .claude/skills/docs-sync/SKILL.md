---
name: docs-sync
description: Perform a repo-wide documentation sync for the NanoClaw project.
version: 1.0.0
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
invocation: /docs-sync
---

Perform a repo-wide documentation sync for the NanoClaw project.

## Scope

Sync the following docs against current code. Skip everything under `groups/main/nanoclaw-merge/` (upstream mirror, not ours) and `groups/main/conversations/` (chat logs).

**AGENTS.md hierarchy** — one per directory, linked by `<!-- Parent: -->` comments:
- `AGENTS.md` (root)
- `src/AGENTS.md`, `src/channels/AGENTS.md`
- `container/AGENTS.md`, `container/skills/AGENTS.md`, `container/agent-runner/AGENTS.md`, `container/scripts/AGENTS.md`
- `.claude/AGENTS.md`, `.claude/agents/AGENTS.md`, `.claude/rules/AGENTS.md`
- `docs/AGENTS.md`, `setup/AGENTS.md`, `skills-engine/AGENTS.md`

**Top-level docs:**
- `CLAUDE.md` — key files table, skills table, commands section
- `docs/REQUIREMENTS.md`, `docs/SKILLS_ARCHITECTURE.md`, `docs/SPEC.md`
- `docs/SECURITY.md`, `docs/DEBUG_CHECKLIST.md`
- `.claude/rules/contributions.md`, `.claude/rules/container-security.md`, `.claude/rules/typescript.md`

**Container skill docs** (only if a skill's bash/executable file changed recently):
- `container/skills/*/SKILL.md` — update invocation examples if paths changed

## What to do for each file

1. **Read the current doc** and the code it describes.
2. **Update stale content**: file paths, function names, mount paths, config keys, feature descriptions that no longer match the code.
3. **Remove redundant sections**: content duplicated verbatim in a parent AGENTS.md, outdated migration notes, references to removed features.
4. **Add missing entries**: new source files, new skills, new mounts, new config keys that exist in code but aren't documented.
5. **Keep it minimal**: these are reference docs, not tutorials. Prefer tables over prose. Don't add explanatory padding.

## What NOT to change

- Do not touch `groups/main/nanoclaw-merge/` — upstream mirror
- Do not touch `groups/main/conversations/` — conversation logs
- Do not touch `container/skills/*/SKILL.md` unless the skill's executable changed
- Do not rewrite working content just to rephrase it
- Do not add sections that aren't already present in the file's structure

## Process

Work directory by directory, starting at root. For each AGENTS.md, read the actual files in that directory before editing. After all edits, do a final pass to check that Parent links are consistent and no AGENTS.md references a file that no longer exists.

Report a summary at the end: files updated, sections removed, new entries added.
