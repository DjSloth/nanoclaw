#!/bin/bash
# Generate GWS credential files from Doppler environment variables.
# Runs inside the container at startup when DOPPLER_TOKEN is set.
# Idempotent — safe to re-run.

set -e

GWS_DIR="/home/node/.config/gws"
mkdir -p "$GWS_DIR"

write_creds() {
  local file="$1"
  local client_id="$2"
  local client_secret="$3"
  local refresh_token="$4"

  cat > "$file" <<EOF
{
  "client_id": "$client_id",
  "client_secret": "$client_secret",
  "refresh_token": "$refresh_token",
  "type": "authorized_user"
}
EOF
}

if [ -n "$GWS_CLIENT_ID_SLOTHLABS" ]; then
  write_creds "$GWS_DIR/creds-slothlabs.json" \
    "$GWS_CLIENT_ID_SLOTHLABS" \
    "$GWS_CLIENT_SECRET_SLOTHLABS" \
    "$GWS_REFRESH_TOKEN_SLOTHLABS"
fi

if [ -n "$GWS_CLIENT_ID_GMAIL" ]; then
  write_creds "$GWS_DIR/creds-gmail.json" \
    "$GWS_CLIENT_ID_GMAIL" \
    "$GWS_CLIENT_SECRET_GMAIL" \
    "$GWS_REFRESH_TOKEN_GMAIL"
fi

if [ -n "$GWS_CLIENT_ID_INVOCAP" ]; then
  write_creds "$GWS_DIR/creds-invocap.json" \
    "$GWS_CLIENT_ID_INVOCAP" \
    "$GWS_CLIENT_SECRET_INVOCAP" \
    "$GWS_REFRESH_TOKEN_INVOCAP"
fi
