#!/usr/bin/env bash
# Extract pending upstream commits as JSON.
# Usage: extract-pending.sh [--since <git-date-spec>]
# Output: JSON to stdout. Errors to stderr; exit non-zero on failure.
#
# Per-commit fields: sha, subject, author, date, files[], diffstat,
# diffPreview (first ~8 KB of the diff), diffTruncated (bool).
# Full diffs are intentionally omitted — they can balloon to hundreds
# of MB across hundreds of commits. Use `git show <sha>` for full diff
# of any single commit.

set -euo pipefail

SINCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null || { echo "jq required" >&2; exit 3; }
command -v git >/dev/null || { echo "git required" >&2; exit 3; }

if ! git rev-parse --verify upstream/main >/dev/null 2>&1; then
  echo "upstream/main not found — fetch upstream before running" >&2
  exit 4
fi

UPSTREAM_HEAD=$(git rev-parse upstream/main)

# git cherry main upstream/main marks pending commits with '+'.
# Already-cherry-picked commits (matching patch-id) get '-' and are skipped.
PENDING_SHAS=$(git cherry main upstream/main | awk '/^\+/ {print $2}')

if [[ -n "$SINCE" ]]; then
  # Translate short forms (7d, 2w, 1m) to git-friendly "N units ago".
  # Bare git treats "--since=7d" as an absolute date, not "7 days ago".
  if [[ "$SINCE" =~ ^([0-9]+)([hdwmy])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case "${BASH_REMATCH[2]}" in
      h) SINCE="$n hours ago" ;;
      d) SINCE="$n days ago" ;;
      w) SINCE="$n weeks ago" ;;
      m) SINCE="$n months ago" ;;
      y) SINCE="$n years ago" ;;
    esac
  fi
  RECENT_SHAS=$(git log --since="$SINCE" --format=%H upstream/main)
  FILTERED=""
  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    if grep -qx "$sha" <<< "$RECENT_SHAS"; then
      FILTERED+="$sha"$'\n'
    fi
  done <<< "$PENDING_SHAS"
  PENDING_SHAS="$FILTERED"
fi

PENDING_COUNT=$(printf '%s' "$PENDING_SHAS" | grep -c . || true)
if [[ "$PENDING_COUNT" -gt 100 ]]; then
  echo "warning: $PENDING_COUNT pending commits — consider --since 30d for a smaller window" >&2
fi

DIFF_FULL=$(mktemp)
DIFF_PREVIEW=$(mktemp)
COMMITS_NDJSON=$(mktemp)
trap 'rm -f "$DIFF_FULL" "$DIFF_PREVIEW" "$COMMITS_NDJSON"' EXIT

# 8 KB preview is enough to classify most commits without dragging the JSON
# into multi-megabyte territory across hundreds of commits.
PREVIEW_BYTES=8192

while IFS= read -r sha; do
  [[ -z "$sha" ]] && continue
  subject=$(git show --no-patch --format=%s "$sha")
  author=$(git show --no-patch --format=%an "$sha")
  date=$(git show --no-patch --format=%aI "$sha")
  files_json=$(git show --name-only --pretty=format: "$sha" | grep -v '^$' | jq -R . | jq -s .)
  diffstat=$(git log -1 --shortstat --format= "$sha" | tail -1 | sed 's/^[[:space:]]*//')

  git show --pretty=format: "$sha" > "$DIFF_FULL"
  full_bytes=$(wc -c < "$DIFF_FULL")
  head -c "$PREVIEW_BYTES" "$DIFF_FULL" > "$DIFF_PREVIEW"
  if [[ "$full_bytes" -gt "$PREVIEW_BYTES" ]]; then
    diff_truncated=true
  else
    diff_truncated=false
  fi

  jq -n -c \
    --arg sha "$sha" \
    --arg subject "$subject" \
    --arg author "$author" \
    --arg date "$date" \
    --argjson files "$files_json" \
    --arg diffstat "$diffstat" \
    --rawfile diffPreview "$DIFF_PREVIEW" \
    --argjson diffTruncated "$diff_truncated" \
    '{sha: $sha, subject: $subject, author: $author, date: $date, files: $files, diffstat: $diffstat, diffPreview: $diffPreview, diffTruncated: $diffTruncated}' \
    >> "$COMMITS_NDJSON"
done <<< "$PENDING_SHAS"

jq -n \
  --arg rangeBase "main" \
  --arg rangeTip "upstream/main" \
  --arg upstreamHead "$UPSTREAM_HEAD" \
  --slurpfile commits "$COMMITS_NDJSON" \
  '{rangeBase: $rangeBase, rangeTip: $rangeTip, upstreamHead: $upstreamHead, commits: $commits}'
