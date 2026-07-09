# fable-harness | PreToolUse hook (matcher: Bash|PowerShell) — PowerShell port, khong can jq
# Buoc hoi xac nhan (permissionDecision=ask) truoc cac lenh co kha nang pha huy.
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $json = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = $json.tool_input.command
if (-not $cmd) { exit 0 }

function Ask([string]$Reason) {
  $obj = @{
    hookSpecificOutput = @{
      hookEventName            = 'PreToolUse'
      permissionDecision       = 'ask'
      permissionDecisionReason = "[fable-guard] $Reason"
    }
  }
  Write-Output ($obj | ConvertTo-Json -Compress -Depth 4)
  exit 0
}

# 1) Xoa de quy + force — ca dang POSIX lan dang Windows/PowerShell
if ($cmd -match 'rm\s+-\S*r\S*f|rm\s+-\S*f\S*r') {
  if ($cmd -notmatch 'rm\s+-\S+\s+("?/tmp|\$TMPDIR|\$env:TEMP)') {
    Ask 'Lenh xoa de quy (rm -rf) — xac nhan truoc khi chay.'
  }
}
if ($cmd -match '(?i)Remove-Item\b(?=[^|;]*-Recurse)(?=[^|;]*-Force)') {
  if ($cmd -notmatch '(?i)\$env:TE?MP|[\\/]Temp[\\/]|scratchpad') {
    Ask 'Remove-Item -Recurse -Force — xac nhan truoc khi chay.'
  }
}
if ($cmd -match '(?i)(^|[\s&|;])(rd|rmdir)\s+\/s\b') {
  Ask 'rd /s xoa de quy thu muc — xac nhan truoc khi chay.'
}

# 2) Git pha huy lich su / working tree (--force-with-lease duoc cho qua co chu dich)
if ($cmd -match 'git\s+push\s+(.*\s)?(-f|--force)(\s|$)') { Ask 'git push --force co the ghi de lich su tren remote.' }
if ($cmd -match 'git\s+reset\s+--hard')                    { Ask 'git reset --hard xoa toan bo thay doi chua commit.' }
if ($cmd -match 'git\s+clean\s+-\S*f')                     { Ask 'git clean -f xoa cac file chua duoc track.' }
if ($cmd -match 'git\s+branch\s+-D\s')                     { Ask 'Xoa branch cuong buc (git branch -D).' }

# 3) SQL pha huy — chi xet khi lenh goi toi mot DB client thuc thi
if ($cmd -match '(?i)(^|[\s/])(psql|mysql|mariadb|sqlite3|sqlcmd|clickhouse|mongosh|snowsql|beeline|trino|bq)(\s|$)') {
  if ($cmd -match '(?i)DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s') { Ask 'Lenh SQL pha huy (DROP/TRUNCATE).' }
  if ($cmd -match '(?i)DELETE\s+FROM' -and $cmd -notmatch '(?i)WHERE') { Ask 'DELETE FROM khong co WHERE — se xoa toan bo du lieu bang.' }
}

# 4) Pipe-to-shell va phan quyen nguy hiem — ca dang bash lan PowerShell (iwr | iex)
if ($cmd -match '(curl|wget)[^|;]*\|\s*(ba|z)?sh')                                            { Ask 'Tai script tu internet va chay truc tiep (pipe-to-shell).' }
if ($cmd -match '(?i)(iwr|irm|Invoke-WebRequest|Invoke-RestMethod)[^|;]*\|\s*(iex|Invoke-Expression)') { Ask 'Tai script tu internet va chay truc tiep (iwr | iex).' }
if ($cmd -match 'chmod\s+-R\s+777')                                                            { Ask 'chmod -R 777 mo toan quyen cho moi user.' }

exit 0
