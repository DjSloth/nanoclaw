---
name: gws-renew
description: Renew Google Workspace OAuth refresh tokens and push them to Doppler (nanoclaw-ai/prd). Opens a fresh Chrome window per account so OAuth sessions don't bleed. Triggers on "/gws-renew", "renew gws tokens", "renew google workspace tokens".
version: 1.0.0
allowed-tools: Bash, Read
invocation: /gws-renew
---

Renew Google Workspace OAuth refresh tokens for all 3 accounts (or only the ones passed as arguments) and push them to Doppler so the container picks them up on next restart.

## What this skill does

Runs `scripts/renew-gws-tokens.sh`, which for each target account:

1. Spawns `gws auth login` and captures the OAuth URL it prints
2. Opens a fresh Chrome window with a throwaway profile dir pointed at that URL (so the account picker isn't pre-filled and sessions don't bleed)
3. Waits for the user to complete OAuth in the browser
4. Writes `credentials.json` via `gws auth export`
5. Reads the new `refresh_token` via `gws auth export --unmasked` + `jq`
6. Pushes it to Doppler (`nanoclaw-ai` / `prd`) as `GWS_REFRESH_TOKEN_<GMAIL|INVOCAP|SLOTHLABS>`

## Steps

### 1. Parse arguments

The user may pass account names: `gmail`, `invocap`, `slothlabs`. If none, all three are renewed sequentially.

Examples the user might type:
- `/gws-renew` → all three
- `/gws-renew gmail` → just gmail
- `/gws-renew invocap slothlabs` → those two

### 2. Run the script

```bash
./scripts/renew-gws-tokens.sh <args>
```

Use the Bash tool with `timeout: 1800000` (30 minutes), since the user has to click through an OAuth flow per account in the browser.

If the script fails because `DOPPLER_TOKEN` isn't set and isn't in `.env`, tell the user to set it and re-run.

### 3. Confirm and remind to restart

After the script finishes successfully, remind the user to restart NanoClaw so the container picks up the new tokens:

```bash
systemctl --user restart nanoclaw
```

Offer to run it for them.

## Guard rails

- Do not modify the script's hard-coded Doppler project/config (`nanoclaw-ai` / `prd`) without explicit user instruction — those are the production secrets the container reads.
- Do not run `gws auth login` more than once per account in a single run — each login burns one of the 50 refresh tokens Google allows per OAuth client.
- If the OAuth flow times out (10 min per account), the script will abort and report which account failed; do not retry silently — tell the user.
