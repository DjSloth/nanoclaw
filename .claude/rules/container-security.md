---
paths:
  - src/container-runner.ts
  - src/**
---
# Container Security Rules

- Never weaken mount filtering — blocked patterns (.ssh, .gnupg, .aws, .env, etc.) are security boundaries
- Never expand the env var allowlist beyond CLAUDE_CODE_OAUTH_TOKEN and ANTHROPIC_API_KEY
- Never make the mount allowlist (~/.config/nanoclaw/mount-allowlist.json) accessible inside containers
- Project root must remain read-only for non-main groups
- Non-main groups must not be able to send cross-group IPC messages
- Do not add --privileged or capability grants to container runs
