#!/bin/bash
set -e

# Compile agent-runner TypeScript from per-group source
cd /app && npx tsc --outDir /tmp/dist 2>&1 >&2
ln -s /app/node_modules /tmp/dist/node_modules
chmod -R a-w /tmp/dist

# Capture stdin (JSON input) before exec-ing into Doppler
cat > /tmp/input.json

# Run with Doppler if token is provided, otherwise run directly (local dev)
if [ -n "$DOPPLER_TOKEN" ]; then
  exec doppler run --token="$DOPPLER_TOKEN" -- bash -c \
    'bash /scripts/init-gws-creds.sh && bash /scripts/init-git-creds.sh && node /tmp/dist/index.js < /tmp/input.json'
else
  bash /scripts/init-git-creds.sh
  exec node /tmp/dist/index.js < /tmp/input.json
fi
