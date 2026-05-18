#!/usr/bin/env bash
# Renew the Claude Code OAuth subscription token and push it to Doppler.
#
# Usage:
#   ./scripts/renew-claude-token.sh
#
# Spawns a fresh gnome-terminal running `claude setup-token` so the user can
# complete the device-code OAuth flow (which requires a real TTY). The token
# is tee'd to a tempfile; after the terminal closes, the script extracts the
# token and pushes it to Doppler as CLAUDE_CODE_OAUTH_TOKEN.

set -euo pipefail

DOPPLER_PROJECT="nanoclaw-ai"
DOPPLER_CONFIG="prd"
DOPPLER_KEY="CLAUDE_CODE_OAUTH_TOKEN"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
die()    { red "ERROR: $*" >&2; exit 1; }

for bin in claude doppler gnome-terminal; do
  command -v "$bin" >/dev/null 2>&1 || die "$bin not found on PATH"
done

unset DOPPLER_TOKEN
if ! doppler me --scope "$PROJECT_ROOT" >/dev/null 2>&1; then
  die "doppler CLI has no write-capable session for $PROJECT_ROOT. Run: doppler login  (or 'doppler configure set token <personal-token> --scope $PROJECT_ROOT')"
fi

token_file=$(mktemp -t claude-token-XXXXXX)
trap "rm -f '$token_file'" EXIT INT TERM

bold "════════════════════════════════════════"
bold "  Renewing Claude Code OAuth token"
bold "════════════════════════════════════════"
yellow "→ Opening a new terminal window to run 'claude setup-token'."
yellow "  Complete the OAuth flow there, then close the window when prompted."

gnome-terminal --wait --title="Claude OAuth token renewal" -- bash -c "
  echo '=== claude setup-token ==='
  echo 'Complete the OAuth flow below. When done, the token will be captured.'
  echo
  claude setup-token 2>&1 | tee '$token_file'
  echo
  echo 'Press Enter to close this window…'
  read -r _
" || die "Failed to launch gnome-terminal"

yellow "→ Extracting token from output…"
TOKEN=$(grep -oE 'sk-ant-oat01-[A-Za-z0-9_-]+' "$token_file" | tail -1 || true)
[[ -n "$TOKEN" ]] || die "no Claude OAuth token (sk-ant-oat01-…) found in the terminal output"

yellow "→ Pushing $DOPPLER_KEY to Doppler ($DOPPLER_PROJECT/$DOPPLER_CONFIG)…"
doppler secrets set "$DOPPLER_KEY=$TOKEN" \
  --project "$DOPPLER_PROJECT" \
  --config "$DOPPLER_CONFIG" \
  --no-interactive >/dev/null

green "✓ Token renewed and pushed to Doppler."
echo
echo "  Restart NanoClaw to pick up the new token:"
echo "    systemctl --user restart nanoclaw"
