#!/usr/bin/env bash
# fable-harness | PreCompact hook — snapshot transcript truoc khi nen context,
# de rule 60/75 co cho khoi phuc state sau compaction. Giu toi da 5 checkpoint.
# Can jq de doc transcript_path; thieu jq thi chuyen sang ban PowerShell (Windows).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  if command -v powershell.exe >/dev/null 2>&1; then
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$DIR/fable_precompact_checkpoint.ps1" 2>/dev/null || echo "$DIR/fable_precompact_checkpoint.ps1")"
  fi
  exit 0
fi

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -z "$transcript" ] || [ ! -f "$transcript" ] && exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // "unknown"')

base="${CLAUDE_PROJECT_DIR:-$HOME}"
ckdir="$base/.claude/checkpoints"
mkdir -p "$ckdir"

cp "$transcript" "$ckdir/precompact-$(date +%Y%m%d-%H%M%S)-$sid.jsonl"

# Prune: giu 5 file moi nhat
ls -1t "$ckdir"/precompact-*.jsonl 2>/dev/null | tail -n +6 | while IFS= read -r f; do rm -f "$f"; done

exit 0
