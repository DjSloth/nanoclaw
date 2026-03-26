# Contribution Rules

- New features, channels, and integrations belong in `.claude/skills/` as SKILL.md files — not in src/
- Source code PRs are accepted only for: bug fixes, security fixes, clear simplifications
- Do not add abstractions or new dependencies without a compelling reason
- Skills must have complete YAML frontmatter: name, description, version, allowed-tools, invocation
- Never add configuration sprawl — if it needs explaining in comments, reconsider it
