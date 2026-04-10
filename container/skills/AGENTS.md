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
| `gws-calendar/` | Google Workspace Calendar — read/query events |
| `gws-calendar-agenda/` | Structured daily/weekly agenda from Google Calendar |
| `gws-calendar-insert/` | Create/update Google Calendar events |
| `gws-docs/` | Read Google Docs documents |
| `gws-docs-write/` | Write and update Google Docs |
| `gws-drive/` | Browse and read Google Drive files |
| `gws-drive-upload/` | Upload files to Google Drive |
| `gws-gmail/` | Read Gmail messages and threads |
| `gws-gmail-reply/` | Reply to Gmail threads |
| `gws-gmail-send/` | Compose and send Gmail messages |
| `gws-gmail-triage/` | Batch email triage workflow |
| `gws-people/` | Google Contacts / People API lookup |
| `gws-shared/` | Shared Google Workspace authentication helpers |
| `gws-sheets/` | Read Google Sheets data |
| `gws-sheets-append/` | Append rows to Google Sheets |
| `gws-sheets-read/` | Structured data extraction from Sheets |
| `gws-tasks/` | Google Tasks management |
| `gws-workflow-meeting-prep/` | Compound workflow: calendar + docs + email for meeting prep |
| `gws-workflow-standup-report/` | Compound workflow: generate standup report from calendar/tasks |
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

### Common Patterns
- Google Workspace skills share authentication via `gws-shared.md`
- Compound workflow skills (meeting-prep, standup-report) compose multiple atomic skills

<!-- MANUAL: co-architect, github-issue-creator, merge-manager, places, pr-reviewer, and surfline are Darren's protected skills — never delete or update without explicit request -->
