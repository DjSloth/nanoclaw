#!/bin/bash
# Configure git credentials using GITHUB_PAT_DJSLOTH if available.
# Run after secrets are injected (after doppler run in Doppler mode).
# GIT_DIR/GIT_WORK_TREE let agents commit to the nanoclaw repo:
#   GIT_DIR=/workspace/extra/nanoclaw-git GIT_WORK_TREE=/workspace/project git ...
if [ -n "$GITHUB_PAT_DJSLOTH" ]; then
  git config --global credential.helper \
    "!f() { echo 'username=djsloth'; echo \"password=$GITHUB_PAT_DJSLOTH\"; }; f"
  git config --global user.name "Darren (NanoClaw)"
  git config --global user.email "darren@slothlabs.io"
  git config --global safe.directory '*'
fi
