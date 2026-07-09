# fable-harness | Stop hook — PowerShell, khong can jq
# Cuong che rule 30: neu message cuoi cua luot tuyen bo hoan thanh ("hoàn thành", "tests pass",
# "đã chạy được"...) ma trong luot khong co tool call nao tao ra bang chung (Bash/PowerShell/Read/
# Agent/Skill) → block voi ly do, buoc model kiem chung hoac ha trang thai xuong "Đã viết, chưa chạy".
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $json = $raw | ConvertFrom-Json } catch { exit 0 }

# Chong vong lap: neu hook nay da block mot lan trong luot, cho qua
if ($json.stop_hook_active) { exit 0 }

$transcript = $json.transcript_path
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }

# Chi doc phan duoi transcript — du de phu mot luot, khong ton thoi gian voi phien dai
$lines = Get-Content -LiteralPath $transcript -Encoding UTF8 -Tail 400
if (-not $lines) { exit 0 }

# Tim ranh gioi luot hien tai: entry user cuoi cung KHONG phai tool_result
$turnStart = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
  $e = $null
  try { $e = $lines[$i] | ConvertFrom-Json } catch { continue }
  if ($e.type -ne 'user') { continue }
  $content = $e.message.content
  $isToolResult = $false
  if ($content -isnot [string]) {
    foreach ($block in $content) { if ($block.type -eq 'tool_result') { $isToolResult = $true; break } }
  }
  if (-not $isToolResult) { $turnStart = $i; break }
}
if ($turnStart -lt 0) { $turnStart = 0 }

# Quet luot: gom text assistant cuoi cung + kiem tra co tool_use tao bang chung khong
$evidenceTools = '^(Bash|PowerShell|Read|Agent|Skill|Workflow)$'
$hasEvidence = $false
$lastText = ''
for ($i = $turnStart; $i -lt $lines.Count; $i++) {
  $e = $null
  try { $e = $lines[$i] | ConvertFrom-Json } catch { continue }
  if ($e.type -ne 'assistant') { continue }
  foreach ($block in $e.message.content) {
    if ($block.type -eq 'tool_use' -and $block.name -match $evidenceTools) { $hasEvidence = $true }
    if ($block.type -eq 'text' -and $block.text) { $lastText = $block.text }
  }
}
if (-not $lastText) { exit 0 }

# Claim hoan thanh — loai tru cac dang phu dinh ("chưa hoàn thành", "không hoàn thành")
$claimPattern = '(?i)(?<!(chưa|chua|không|khong)\s)(hoàn thành|hoan thanh|đã chạy được|da chay duoc|chạy thành công|tests?\s+pass(ed)?|đã kiểm chứng|da kiem chung)'
if (($lastText -match $claimPattern) -and (-not $hasEvidence)) {
  $reason = '[fable-verify] Message cuối tuyên bố hoàn thành/chạy được nhưng lượt này không có tool call nào tạo ra bằng chứng (Bash/PowerShell/Read/Agent). Theo rule 30: hoặc chạy kiểm chứng ngay bây giờ và trích kết quả thực, hoặc hạ trạng thái xuống "Đã viết, chưa chạy" kèm mục "Chưa kiểm chứng:".'
  Write-Output (@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress)
  exit 0
}
exit 0
