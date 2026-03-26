<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# .claude/skills

## Purpose
Host-side Claude Code skills (slash commands) for managing the NanoClaw installation. Each subdirectory contains a `SKILL.md` that instructs Claude Code how to perform that operation. Skills are the correct mechanism for adding new features — not source code PRs.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `setup/` | First-time installation, WhatsApp authentication, service registration |
| `customize/` | Add channels, integrations, and behavioral changes |
| `debug/` | Container diagnostics, log inspection, troubleshooting |
| `update/` | Pull upstream changes, merge customizations, run migrations |
| `add-discord/` | Install Discord channel integration |
| `add-gmail/` | Install Gmail integration |
| `add-parallel/` | Add Parallel AI web research MCP |
| `add-pdf-reader/` | Add PDF reading capability |
| `add-reactions/` | Add WhatsApp emoji reaction support |
| `add-telegram/` | Install Telegram channel |
| `add-telegram-swarm/` | Add Agent Swarm support for Telegram |
| `add-voice-transcription/` | Add voice message transcription via Whisper |
| `add-compact/` | Add /compact context compaction command |
| `convert-to-apple-container/` | Switch from Docker to Apple Container runtime |
| `x-integration/` | X (Twitter) posting integration |
| `qodo-pr-resolver/` | Fetch and fix Qodo PR review issues |
| `get-qodo-rules/` | Load org/repo coding rules from Qodo |

## For AI Agents

### Working In This Directory
- Every skill directory must contain a `SKILL.md` with complete YAML frontmatter: `name`, `description`, `version`, `allowed-tools`, `invocation`
- Skills transform the local installation — they can modify `src/`, install npm packages, create config files, etc.
- To add a new feature: create a new skill directory here, not a PR to `src/`
- Skills are the only acceptable mechanism for adding channels, integrations, and new behavior

### Common Patterns
- Skills use the `skills-engine` package to apply/track their transformations
- Skills that add channels create files in `src/channels/` and register via the channel registry

<!-- MANUAL: -->
