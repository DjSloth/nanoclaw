<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# .claude/agents

## Purpose
Sub-agent definitions for Claude Code. These define specialized agent personas that can be invoked during Claude Code sessions for specific tasks like container debugging, skill development, and PR review.

## Key Files

| File | Description |
|------|-------------|
| `container-debugger.md` | Diagnoses container startup failures, mount errors, agent timeouts, and IPC issues |
| `skill-developer.md` | Helps create new `.claude/skills/` entries — writes SKILL.md instruction files, not source code |
| `pr-reviewer.md` | Reviews pull requests against NanoClaw contribution rules — skills must not touch source code, source PRs must be bug/security/simplification only |

## For AI Agents

### Working In This Directory
- Agent files define specialized sub-agent roles with specific tool access and behavioral constraints
- The `pr-reviewer` agent enforces the contribution rules: skills-only for features, source PRs for bugs/security/simplification only
- The `skill-developer` agent knows not to write source code — it only creates SKILL.md files

<!-- MANUAL: -->
