# Doppler Secret Management

NanoClaw uses [Doppler](https://doppler.com) to centralise secrets. The only value stored on the host is a single **service token** — everything else lives in Doppler and is injected at runtime.

## Setup

1. Create a Doppler account at doppler.com
2. Create a project called `nanoclaw` with environment `production`
3. Add all secrets listed in `data/main-container-config.json`
4. Generate a **Service Token**: project → production → Access → Service Tokens → Generate
5. Set `DOPPLER_TOKEN` in your `.env` (or directly in the systemd unit)
6. Start NanoClaw via Doppler so the host process also gets secrets:
   ```bash
   doppler run --token=$DOPPLER_TOKEN -- npm start
   # or update your systemd ExecStart to use doppler run
   ```

## Rotating a Secret

1. Open doppler.com → nanoclaw → production
2. Update the secret value
3. Restart the container (no code change needed):
   ```bash
   systemctl --user restart nanoclaw
   ```

## Adding a New Secret

1. Add the key/value in Doppler UI
2. Reference it inside the container via `process.env.MY_KEY` — it's automatically available

## Rotating the Service Token

1. Doppler UI → Access → Service Tokens → Revoke old → Generate new
2. Update `DOPPLER_TOKEN` in `.env` on the host
3. Restart NanoClaw

## GWS Re-auth Flow

When a Google Workspace OAuth refresh token expires:

1. On the host, re-authenticate:
   ```bash
   gws auth login --account raz@slothlabs.dev
   ```
2. Export the new credentials:
   ```bash
   gws auth export --unmasked --account raz@slothlabs.dev
   ```
3. Copy `refresh_token` (and `client_id`/`client_secret` if rotated) into Doppler:
   - `GWS_REFRESH_TOKEN_SLOTHLABS`, `GWS_CLIENT_ID_SLOTHLABS`, `GWS_CLIENT_SECRET_SLOTHLABS`
4. Restart NanoClaw — the init script regenerates the credential files on next container start

## How It Works

- **Host**: Only `DOPPLER_TOKEN` is on disk. When NanoClaw starts via `doppler run`, all secrets are in `process.env`.
- **Containers**: The host passes `DOPPLER_TOKEN` as a single env var. The container entrypoint runs `doppler run --token=$DOPPLER_TOKEN` which injects all secrets, then runs `init-gws-creds.sh` to write GWS JSON files, then starts the agent.
- **Local dev (no Doppler)**: If `DOPPLER_TOKEN` is not set, NanoClaw falls back to reading `.env` and mounting `~/.config/gws/` directly.
