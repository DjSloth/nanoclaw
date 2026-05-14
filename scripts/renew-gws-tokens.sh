#!/usr/bin/env bash
# Renew Google Workspace refresh tokens and push them to Doppler.
#
# Usage:
#   ./scripts/renew-gws-tokens.sh                  # renew all 3 accounts
#   ./scripts/renew-gws-tokens.sh gmail            # renew only gmail
#   ./scripts/renew-gws-tokens.sh invocap slothlabs
#
# For each account: spawns gws auth login, captures the OAuth URL, opens a
# fresh Chrome window with a throwaway profile, waits for the callback, then
# exports the unmasked refresh_token and pushes it to Doppler.

set -euo pipefail

DOPPLER_PROJECT="nanoclaw-ai"
DOPPLER_CONFIG="prd"
GWS_BASE="$HOME/.config/gws"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ACCOUNTS=("gmail" "invocap" "slothlabs")
declare -A DOPPLER_KEY=(
  [gmail]="GWS_REFRESH_TOKEN_GMAIL"
  [invocap]="GWS_REFRESH_TOKEN_INVOCAP"
  [slothlabs]="GWS_REFRESH_TOKEN_SLOTHLABS"
)

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }

die() { red "ERROR: $*" >&2; exit 1; }

for bin in gws doppler jq google-chrome; do
  command -v "$bin" >/dev/null 2>&1 || die "$bin not found on PATH"
done

# Writes require a personal token / write-capable service token via `doppler configure`.
# The DOPPLER_TOKEN in .env is the runtime service token (read-only) — unset it so the
# CLI uses the configured session instead.
unset DOPPLER_TOKEN
if ! doppler me --scope "$PROJECT_ROOT" >/dev/null 2>&1; then
  die "doppler CLI has no write-capable session for $PROJECT_ROOT. Run: doppler login  (or set a personal token via 'doppler configure set token <token> --scope $PROJECT_ROOT')"
fi

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=("${ACCOUNTS[@]}")
fi

for a in "${TARGETS[@]}"; do
  [[ -n "${DOPPLER_KEY[$a]:-}" ]] || die "unknown account '$a'. Valid: ${ACCOUNTS[*]}"
done

cleanup_pid=""
cleanup_profile=""
cleanup() {
  if [[ -n "$cleanup_pid" ]]; then
    kill "$cleanup_pid" 2>/dev/null || true
  fi
  if [[ -n "$cleanup_profile" && -d "$cleanup_profile" ]]; then
    rm -rf "$cleanup_profile"
  fi
  return 0
}
trap cleanup EXIT INT TERM

renew_one() {
  local account="$1"
  local xdg="$GWS_BASE/$account"
  local creds_path="$xdg/gws/credentials.json"
  local doppler_key="${DOPPLER_KEY[$account]}"

  echo
  bold "════════════════════════════════════════"
  bold "  Renewing: $account → $doppler_key"
  bold "════════════════════════════════════════"

  mkdir -p "$xdg/gws"

  local login_log
  login_log=$(mktemp)
  cleanup_profile=$(mktemp -d -t chrome-gws-XXXXXX)

  yellow "→ Starting gws auth login (XDG_CONFIG_HOME=$xdg)…"
  XDG_CONFIG_HOME="$xdg" gws auth login >"$login_log" 2>&1 &
  cleanup_pid=$!

  local url=""
  local waited=0
  while [[ -z "$url" && $waited -lt 30 ]]; do
    sleep 1
    waited=$((waited + 1))
    url=$(grep -oE 'https://accounts.google.com/[^ ]+' "$login_log" | head -1 || true)
  done
  [[ -n "$url" ]] || { cat "$login_log" >&2; die "gws did not print an OAuth URL within 30s"; }

  yellow "→ Opening fresh Chrome window. Sign in with the '$account' account."
  google-chrome \
    --user-data-dir="$cleanup_profile" \
    --new-window \
    --no-first-run \
    --no-default-browser-check \
    "$url" >/dev/null 2>&1 &
  disown

  yellow "→ Waiting for OAuth callback (10 min timeout)…"
  local timeout=600
  while kill -0 "$cleanup_pid" 2>/dev/null && [[ $timeout -gt 0 ]]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  if kill -0 "$cleanup_pid" 2>/dev/null; then
    kill "$cleanup_pid" 2>/dev/null || true
    die "OAuth flow timed out for $account"
  fi

  if ! wait "$cleanup_pid"; then
    cat "$login_log" >&2
    cleanup_pid=""
    die "gws auth login failed for $account"
  fi
  cleanup_pid=""

  rm -rf "$cleanup_profile"
  cleanup_profile=""
  rm -f "$login_log"

  yellow "→ Writing credentials.json…"
  XDG_CONFIG_HOME="$xdg" gws auth export "$creds_path" >/dev/null

  yellow "→ Extracting refresh_token…"
  local refresh_token
  refresh_token=$(XDG_CONFIG_HOME="$xdg" gws auth export --unmasked | jq -r .refresh_token)
  [[ -n "$refresh_token" && "$refresh_token" != "null" ]] || die "failed to parse refresh_token from gws output"

  yellow "→ Pushing $doppler_key to Doppler ($DOPPLER_PROJECT/$DOPPLER_CONFIG)…"
  doppler secrets set "$doppler_key=$refresh_token" \
    --project "$DOPPLER_PROJECT" \
    --config "$DOPPLER_CONFIG" \
    --no-interactive >/dev/null

  green "✓ $account renewed"
}

for a in "${TARGETS[@]}"; do
  renew_one "$a"
done

echo
bold "════════════════════════════════════════"
green "  All done."
echo "  Restart NanoClaw to pick up the new tokens:"
echo "    systemctl --user restart nanoclaw"
bold "════════════════════════════════════════"
