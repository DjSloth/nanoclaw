<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# container/skills

## Purpose
Markdown instruction files available to Claude agents running inside containers. These are loaded as Claude Code skills (slash commands) within the container environment. Unlike host-side skills in `.claude/skills/`, these run in the sandboxed container context.

## Skill Directories

Each skill is a directory containing a `SKILL.md` file (and optionally an executable).

| Directory | Description |
|-----------|-------------|
| `agent-browser/` | Browser automation tool — launches Chromium via Playwright-style Bash commands |
| `co-architect/` | Senior architect persona for design discussions |
| `gh-cli/` | GitHub CLI usage patterns for agents |
| `git-commit/` | Atomic git commit workflow with conventional commit format |
| `github-issue-creator/` | Creates GitHub issues from agent context |
| `merge-manager/` | Git merge conflict resolution workflow |
| `persona-exec-assistant/` | Executive assistant persona configuration |
| `places/` | Google Places / Maps lookup |
| `prd/` | Product Requirements Document generation |
| `pr-reviewer/` | Pull request review workflow |
| `receiving-code-review/` | Structured response to code review feedback |
| `red-alert/` | Israeli rocket alert monitoring (real-time data) |
| `requesting-code-review/` | Request structured code review |
| `supabase-postgres-best-practices/` | Supabase/Postgres patterns for agents |
| `surfline/` | Surf forecast data lookup |
| `typescript-advanced-types/` | Advanced TypeScript type patterns reference |
| `webapp-testing/` | Web application testing workflow |

## For AI Agents

### Working In This Directory
- Each skill is a directory with a `SKILL.md` instruction file (and optionally an executable with the same name)
- Main group: global skills are symlinked into the group's sessions dir at `/workspace/extra/skills/{name}` for live editing
- Non-main groups: global skills are copied into `groupSessionsDir/skills/` on each container startup (no overlay mount)
- Group-specific skills in `groups/{name}/skills/` are copied into `.claude/skills/` on startup for all groups, overriding globals of the same name
- To add a new container skill, create a new directory with a `SKILL.md` following the existing pattern
- Skills marked as protected (co-architect, github-issue-creator, merge-manager, places, pr-reviewer, surfline) must not be deleted or modified without explicit user request

<!-- MANUAL: co-architect, github-issue-creator, merge-manager, places, pr-reviewer, and surfline are Darren's protected skills — never delete or update without explicit request -->
