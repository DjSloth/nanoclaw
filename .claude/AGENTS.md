<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# .claude

## Purpose
Claude Code host-side configuration directory. Contains skills (slash commands) for installation management, agents (sub-agent definitions), and rules (coding standards). This is the control plane for operators managing their NanoClaw installation.

## Key Files

| File | Description |
|------|-------------|
| `settings.json` | Project-level Claude Code settings (committed) |
| `settings.local.json` | Local Claude Code settings (not committed) |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `skills/` | Host-side slash command skills for installation management (see `skills/AGENTS.md`) |
| `agents/` | Sub-agent definitions for specialized tasks (see `agents/AGENTS.md`) |
| `rules/` | Coding rules and security constraints applied to all Claude sessions (see `rules/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Files in `skills/` are instruction files for Claude Code — they are not executed directly
- Rules in `rules/` are always loaded by Claude Code and override default behavior
- Do not commit `settings.local.json` — it contains local overrides and may have secrets

<!-- MANUAL: -->
