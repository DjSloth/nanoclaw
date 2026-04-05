<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-04-05 -->

# src

## Purpose
Main application source code for the NanoClaw host process. This single Node.js process handles all routing, scheduling, container lifecycle management, and channel communication. It is the only non-container code that runs on the host.

## Key Files

| File | Description |
|------|-------------|
| `index.ts` | Orchestrator: state management, message loop, agent invocation, startup/shutdown |
| `types.ts` | Shared TypeScript interfaces (Channel, RegisteredGroup, ScheduledTask, NewMessage, etc.) |
| `config.ts` | All configuration constants (paths, timeouts, trigger pattern, env var reads) |
| `db.ts` | SQLite operations — messages, groups, sessions, tasks, router state |
| `router.ts` | Message formatting for agents and outbound response formatting |
| `ipc.ts` | IPC file watcher — processes JSON command files dropped by agents |
| `container-runner.ts` | Spawns agent containers with correct mounts, handles streaming output |
| `container-runtime.ts` | Container runtime detection (Docker/Apple Container), orphan cleanup |
| `group-queue.ts` | Per-group FIFO queue with global concurrency cap; stdin piping for active containers |
| `task-scheduler.ts` | Polls SQLite for due scheduled tasks and invokes agents |
| `credential-proxy.ts` | HTTP proxy that injects API credentials for container requests |
| `sender-allowlist.ts` | Allowlist/blocklist logic for message senders |
| `mount-security.ts` | Validates additional mounts against allowlist, enforces blocked patterns |
| `group-folder.ts` | Resolves and validates group folder paths within `groups/` |
| `logger.ts` | Structured logger (pino) |
| `env.ts` | Safe .env file reader (non-secret values only) |
| `timezone.ts` | Timezone utilities for scheduled task cron parsing |
| `formatting.ts` | Text formatting helpers |
| `transcription.ts` | Voice message transcription integration |
| `whatsapp-auth.ts` | WhatsApp authentication helpers |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `channels/` | Channel implementations (WhatsApp, etc.) and registry (see `channels/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- TypeScript strict mode — zero `any`, use `unknown` + type guards
- No default exports
- All async functions must handle errors explicitly
- Run `npm run build` after every change to verify zero TypeScript errors
- Do not add new dependencies without a compelling reason

### Testing Requirements
- Most modules have a corresponding `.test.ts` file — run `npm test` after changes
- No integration test suite; use logs for runtime verification

### Common Patterns
- Configuration is centralized in `config.ts` — never hardcode paths or timeouts elsewhere
- State persisted via `db.ts` SQLite calls, not in-memory only
- Container lifecycle always goes through `container-runner.ts` — never spawn containers directly

## Dependencies

### Internal
- All modules import from `config.ts` for constants
- `index.ts` is the entrypoint that wires all modules together

### External
- `@ai-sdk/anthropic` / Claude Agent SDK — agent invocation inside containers
- `@whiskeysockets/baileys` — WhatsApp protocol (via `channels/whatsapp.ts`)
- `better-sqlite3` — synchronous SQLite driver
- `pino` — structured logging
- `cron-parser` — cron expression parsing for scheduler
- `sharp` — image resizing for WhatsApp image attachments
- `pdf-parse` — PDF text extraction for WhatsApp document attachments
- `mammoth` — DOCX text extraction for WhatsApp document attachments
- `qrcode-terminal` — QR code display for WhatsApp re-authentication

<!-- MANUAL: -->
