<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# container/skills

## Purpose
Markdown instruction files available to Claude agents running inside containers. These are loaded as Claude Code skills (slash commands) within the container environment. Unlike host-side skills in `.claude/skills/`, these run in the sandboxed container context.

## Key Files

| File | Description |
|------|-------------|
| `agent-browser.md` | Browser automation tool — launches Chromium via Playwright-style Bash commands |
| `co-architect.md` | Senior architect persona for design discussions |
| `gh-cli.md` | GitHub CLI usage patterns for agents |
| `git-commit.md` | Atomic git commit workflow with conventional commit format |
| `github-issue-creator.md` | Creates GitHub issues from agent context |
| `gws-calendar.md` | Google Workspace Calendar — read/query events |
| `gws-calendar-agenda.md` | Structured daily/weekly agenda from Google Calendar |
| `gws-calendar-insert.md` | Create/update Google Calendar events |
| `gws-docs.md` | Read Google Docs documents |
| `gws-docs-write.md` | Write and update Google Docs |
| `gws-drive.md` | Browse and read Google Drive files |
| `gws-drive-upload.md` | Upload files to Google Drive |
| `gws-gmail.md` | Read Gmail messages and threads |
| `gws-gmail-reply.md` | Reply to Gmail threads |
| `gws-gmail-send.md` | Compose and send Gmail messages |
| `gws-gmail-triage.md` | Batch email triage workflow |
| `gws-people.md` | Google Contacts / People API lookup |
| `gws-shared.md` | Shared Google Workspace authentication helpers |
| `gws-sheets.md` | Read Google Sheets data |
| `gws-sheets-append.md` | Append rows to Google Sheets |
| `gws-sheets-read.md` | Structured data extraction from Sheets |
| `gws-tasks.md` | Google Tasks management |
| `gws-workflow-meeting-prep.md` | Compound workflow: calendar + docs + email for meeting prep |
| `gws-workflow-standup-report.md` | Compound workflow: generate standup report from calendar/tasks |
| `merge-manager.md` | Git merge conflict resolution workflow |
| `persona-exec-assistant.md` | Executive assistant persona configuration |
| `places.md` | Google Places / Maps lookup |
| `prd.md` | Product Requirements Document generation |
| `pr-reviewer.md` | Pull request review workflow |
| `receiving-code-review.md` | Structured response to code review feedback |
| `red-alert.md` | Israeli rocket alert monitoring (real-time data) |
| `requesting-code-review.md` | Request structured code review |
| `supabase-postgres-best-practices.md` | Supabase/Postgres patterns for agents |
| `surfline.md` | Surf forecast data lookup |
| `typescript-advanced-types.md` | Advanced TypeScript type patterns reference |
| `webapp-testing.md` | Web application testing workflow |

## For AI Agents

### Working In This Directory
- These files are SKILL.md-style instruction files, not executable code
- Skills are mounted read-only into containers at `/workspace/project/container/skills/` (main group) or via the base image
- To add a new container skill, create a new `.md` file following the existing pattern (frontmatter + instructions)
- Skills marked as protected (co-architect, github-issue-creator, merge-manager, places, pr-reviewer, surfline) must not be deleted or modified without explicit user request

### Common Patterns
- Google Workspace skills share authentication via `gws-shared.md`
- Compound workflow skills (meeting-prep, standup-report) compose multiple atomic skills

<!-- MANUAL: co-architect, github-issue-creator, merge-manager, places, pr-reviewer, and surfline are Darren's protected skills — never delete or update without explicit request -->
