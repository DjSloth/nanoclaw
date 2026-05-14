---
name: claude-renew
description: Renew the Claude Code OAuth subscription token (CLAUDE_CODE_OAUTH_TOKEN) and push it to Doppler (nanoclaw-ai/prd). Use when the agent container fails with a 401 authentication error from the Anthropic API. Triggers on "/claude-renew", "renew claude token", "claude oauth expired", "DRN authentication error".
version: 1.0.0
allowed-tools: Bash, Read
invocation: /claude-renew
---

Renew the Claude Code subscription OAuth token used by the agent container and push it to Doppler so a service restart picks it up.

## When to use

The container runs `claude` (Claude Code CLI) with `CLAUDE_CODE_OAUTH_TOKEN` set from Doppler. If that token expires or is revoked, every agent invocation fails with:

```
API Error: 401 {"type":"error","error":{"type":"authentication_error","message":"Invalid authentication credentials"}}
```

This skill regenerates the token.

## What this skill does

Runs `scripts/renew-claude-token.sh`, which:

1. Spawns a fresh `gnome-terminal` running `claude setup-token` (which needs a real TTY for the device-code paste step)
2. Tees the terminal's output to a tempfile so the new token can be captured
3. Waits for the user to close the terminal once the OAuth flow completes
4. Extracts the `sk-ant-oat01-…` token from the captured output
5. Pushes it to Doppler (`nanoclaw-ai` / `prd`) as `CLAUDE_CODE_OAUTH_TOKEN`

## Steps

### 1. Run the script

```bash
./scripts/renew-claude-token.sh
```

Use the Bash tool with `timeout: 1800000` (30 minutes), since the user has to complete the OAuth flow in the spawned terminal.

If the script fails because the Doppler CLI has no write-capable session, tell the user to set one up (see `project_doppler_token_split.md` memory).

### 2. Offer to restart NanoClaw

After the script reports success, offer to run:

```bash
systemctl --user restart nanoclaw
```

The agent won't pick up the new token until the container is restarted.

## Guard rails

- Do not print the captured token in chat output — it's a long-lived subscription credential.
- Do not bypass `gnome-terminal` by trying to run `claude setup-token` directly via the Bash tool — it requires a real TTY and will fail.
- The script only updates `CLAUDE_CODE_OAUTH_TOKEN` in Doppler `nanoclaw-ai/prd`. Do not change the project/config without explicit user instruction.
