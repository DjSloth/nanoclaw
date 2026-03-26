<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# .claude/rules

## Purpose
Coding rules and security constraints that Claude Code loads automatically for every session in this project. These rules are always active and override default behavior.

## Key Files

| File | Description |
|------|-------------|
| `contributions.md` | Contribution policy: features via skills, source PRs for bugs/security/simplification only |
| `container-security.md` | Security boundaries: never weaken mount filtering, env var allowlist, project root read-only |
| `typescript.md` | TypeScript standards: strict mode, no `any`, no default exports, explicit error handling |

## For AI Agents

### Working In This Directory
- These rules are always enforced — never override them for convenience
- Container security rules (`container-security.md`) protect against agent sandbox escapes — treat violations as critical bugs
- If a task seems to require violating these rules, stop and ask the user instead

<!-- MANUAL: -->
