<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-03-26 | Updated: 2026-03-26 -->

# container

## Purpose
Everything needed to build and run the agent container image. The container is an ephemeral Linux environment where Claude Agent SDK instances execute. It is isolated from the host except for explicitly mounted paths.

## Key Files

| File | Description |
|------|-------------|
| `Dockerfile` | Agent container image definition — Node.js base, Claude Code CLI install, user setup |
| `build.sh` | Container image build script (calls docker/container build with correct tags) |
| `entrypoint.sh` | Container entrypoint — sets up environment and launches agent-runner |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `agent-runner/` | Node.js script that runs inside the container, wraps Claude Agent SDK (see `agent-runner/AGENTS.md`) |
| `scripts/` | Helper shell scripts for container credential initialization (see `scripts/AGENTS.md`) |
| `skills/` | Markdown skill files available to agents inside containers (see `skills/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- After modifying the Dockerfile or any container source, rebuild with `./container/build.sh`
- BuildKit caches aggressively — `--no-cache` alone does NOT invalidate COPY steps. To force a clean rebuild, prune the builder volume first: `docker builder prune` then `./container/build.sh`
- The container runs as unprivileged user `node` (uid 1000) — do not add `--privileged` or extra capabilities
- Do not add new env vars to the container without updating the credential proxy allowlist in `src/container-runner.ts`

### Testing Requirements
- Build the image and run a test invocation manually
- Check `docker logs <container>` for runtime errors

### Common Patterns
- Containers are ephemeral (`--rm`) — state must be written to mounted paths to persist
- Only `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` are injected as env vars (via credential proxy)

## Dependencies

### External
- Docker or Apple Container runtime
- `nanoclaw-agent:latest` image tag (produced by `build.sh`)

<!-- MANUAL: -->
