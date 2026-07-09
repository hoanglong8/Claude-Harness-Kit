# fable-harness | PreCompact hook — PowerShell
# Snapshot transcript truoc khi nen context, de rule 60/75 co cho khoi phuc state sau compaction.
# Luu vao $CLAUDE_PROJECT_DIR/.claude/checkpoints/ (hoac ~/.claude/checkpoints/ neu chay global).
# Giu toi da 5 checkpoint gan nhat.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $json = $raw | ConvertFrom-Json } catch { exit 0 }

$transcript = $json.transcript_path
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }

$base = $env:CLAUDE_PROJECT_DIR
if ($base) { $dir = Join-Path $base '.claude\checkpoints' }
else       { $dir = Join-Path $HOME '.claude\checkpoints' }
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$sid   = if ($json.session_id) { $json.session_id } else { 'unknown' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Copy-Item -LiteralPath $transcript -Destination (Join-Path $dir "precompact-$stamp-$sid.jsonl")

# Prune: giu 5 file moi nhat
Get-ChildItem -Path $dir -Filter 'precompact-*.jsonl' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -Skip 5 |
  Remove-Item -Force -Confirm:$false

exit 0
