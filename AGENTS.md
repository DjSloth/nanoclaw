# AGENTS.md — NanoClaw AI Agent Reference

NanoClaw is a personal AI assistant that receives messages from WhatsApp (or other channels) and routes them to Claude Agent SDK instances running in isolated Linux containers. It is a single Node.js process with minimal glue code — small enough to read in full.

---

## Architecture

```
WhatsApp (baileys) --> SQLite --> Polling loop --> Container (Claude Agent SDK) --> Response
```

- One Node.js host process handles all routing, scheduling, and container lifecycle.
- Each agent invocation spawns a fresh container with only explicitly mounted directories visible.
- Per-group isolation: each group has its own folder, memory (`CLAUDE.md`), and session state.
- IPC between agents and the host is file-based (watched directories).

---

## Key Files

| Path | Purpose |
|------|---------|
| `src/index.ts` | Orchestrator: state, message loop, agent invocation |
| `src/channels/whatsapp.ts` | WhatsApp connection, auth, send/receive |
| `src/ipc.ts` | IPC watcher and task processing |
| `src/router.ts` | Message formatting and outbound routing |
| `src/config.ts` | Trigger pattern, paths, intervals |
| `src/container-runner.ts` | Spawns streaming agent containers with mounts |
| `src/task-scheduler.ts` | Runs scheduled tasks via SQLite |
| `src/group-queue.ts` | Per-group queue with global concurrency limit |
| `src/db.ts` | SQLite operations (messages, groups, sessions, tasks) |
| `container/Dockerfile` | Agent container image definition |
| `container/build.sh` | Container image build script |
| `container/skills/` | Skill markdown files available inside containers |
| `container/skills/agent-browser/` | Browser automation tool (Chromium, available via Bash) |
| `groups/{name}/CLAUDE.md` | Per-group persistent memory |
| `groups/CLAUDE.md` | Global memory (read by all groups, writable only from main) |
| `.claude/skills/` | Host-side Claude Code skills (setup, customize, debug, etc.) |
| `docs/REQUIREMENTS.md` | Architecture decisions and design rationale |
| `docs/SECURITY.md` | Full security model |

---

## Development Commands

```bash
npm run build          # Compile TypeScript (run after changes)
npm run dev            # Run with hot reload (tsx watch)
npx vitest             # Run tests
./container/build.sh   # Rebuild agent container image
```

**Container build note:** BuildKit caches aggressively. `--no-cache` alone does not invalidate COPY steps. To force a clean rebuild, prune the builder volume first, then re-run `./container/build.sh`.

TypeScript strict mode is enabled. All modified files must pass `tsc` with zero errors.

---

## Contribution Rules

**Only these PRs are accepted to the base codebase:**
- Security fixes
- Bug fixes
- Clear simplifications

**Everything else must be a skill.** New channels, integrations, and features belong in `.claude/skills/{skill-name}/SKILL.md`. Users run the skill on their fork to transform their installation. This keeps the base system minimal.

Do not add abstractions, configuration files, or new dependencies without a compelling reason. If a change requires explaining its purpose in comments, reconsider whether it belongs in the codebase at all.

---

## Security Boundaries — What Agents Must NOT Do

Agents run inside containers and cannot directly affect the host. The host process enforces these boundaries — do not weaken them:

- **Mount allowlist** lives at `~/.config/nanoclaw/mount-allowlist.json` (outside project root, never mounted into containers). Do not move it or make it accessible to agents.
- **Blocked mount patterns** (enforced in `src/container-runner.ts`): `.ssh`, `.gnupg`, `.aws`, `.azure`, `.gcloud`, `.kube`, `.docker`, `credentials`, `.env`, `.netrc`, `.npmrc`, `id_rsa`, `id_ed25519`, `private_key`, `.secret`. Do not add exceptions without explicit user instruction.
- **Project root is mounted read-only** for the main group. Do not change this — agents modifying `src/` or `dist/` on the host would bypass the sandbox on next restart.
- **Environment variable filtering**: only `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` are passed to containers. Do not expand this list.
- **IPC authorization**: non-main groups cannot send messages to other groups or manage other groups' tasks. Do not relax group identity checks.
- **WhatsApp auth** (`store/auth/`) is never mounted into containers.

---

## Container Context

When an agent runs, it executes inside a Linux container (Docker or Apple Container on macOS) as an unprivileged user (`node`, uid 1000). Containers are ephemeral (`--rm`). The agent sees only what is explicitly mounted:

| Mount path (inside container) | What it is |
|-------------------------------|------------|
| `/workspace/project` | Project root (read-only, main group only) |
| `/workspace/group` | This group's folder (read-write) |
| `/workspace/global` | Global memory dir (read-only for non-main) |
| `/workspace/shared` | Shared data directory (read-only for all groups) |
| `/workspace/extra/shared` | Shared data directory (read-write, main group only) |
| `/home/node/.claude/skills` | Container skills (read-only bind mount, non-main groups only) |
| Additional paths | Configured per-group via `containerConfig`, validated against allowlist |

Bash commands the agent runs execute inside the container — they cannot affect the host system directly.

---

## Skills System

Skills are markdown instruction files, not pre-built code. A skill at `.claude/skills/{name}/SKILL.md` is loaded by Claude Code when the user runs `/{name}`. The skill instructs Claude Code how to transform the local installation (install deps, modify source files, configure services, etc.).

Container-side skills live in `container/skills/` and are available to agents running inside containers.

To contribute a new capability, write a skill — not a PR that modifies `src/`.

---

## Testing

```bash
npm run build          # Must pass with zero TypeScript errors
npx vitest             # Unit tests
```

There is no integration test suite. For runtime verification, check logs or ask Claude Code to inspect the running process state.
