#!/bin/bash
# Generate GWS credential files from Doppler environment variables.
# Runs inside the container at startup when DOPPLER_TOKEN is set.
# Idempotent — safe to re-run.

set -e

GWS_CONFIG_BASE="/home/node/.config/gws"

write_creds() {
  local account="$1"
  local refresh_token="$2"

  local dir="$GWS_CONFIG_BASE/$account/gws"
  mkdir -p "$dir"
  cat > "$dir/credentials.json" <<EOF
{
  "client_id": "$GWS_CLIENT_ID",
  "client_secret": "$GWS_CLIENT_SECRET",
  "refresh_token": "$refresh_token",
  "type": "authorized_user"
}
EOF
}

if [ -n "$GWS_REFRESH_TOKEN_GMAIL" ]; then
  write_creds "gmail" "$GWS_REFRESH_TOKEN_GMAIL"
fi

if [ -n "$GWS_REFRESH_TOKEN_SLOTHLABS" ]; then
  write_creds "slothlabs" "$GWS_REFRESH_TOKEN_SLOTHLABS"
fi

if [ -n "$GWS_REFRESH_TOKEN_INVOCAP" ]; then
  write_creds "invocap" "$GWS_REFRESH_TOKEN_INVOCAP"
fi
