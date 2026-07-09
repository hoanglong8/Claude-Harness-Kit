#!/usr/bin/env bash
# fable-harness | PreToolUse hook (matcher: Bash|PowerShell)
# Buộc hỏi xác nhận người dùng (permissionDecision=ask) trước các lệnh có khả năng phá hủy.
# Yêu cầu: jq. Thiếu jq → tự chuyển sang bản PowerShell (fable_guard.ps1) trên Windows;
# không có cả hai mới thoát êm (exit 0) để không chặn công việc.

if ! command -v jq >/dev/null 2>&1; then
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if command -v powershell.exe >/dev/null 2>&1 && [ -f "$DIR/fable_guard.ps1" ]; then
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$DIR/fable_guard.ps1" 2>/dev/null || echo "$DIR/fable_guard.ps1")"
  fi
  exit 0
fi

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

ask() {
  jq -cn --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: ("[fable-guard] " + $reason)
    }
  }'
  exit 0
}

# 1) rm đệ quy + force (bỏ qua nếu mục tiêu nằm trong /tmp hoặc $TMPDIR)
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'; then
  if ! printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[^[:space:]]+[[:space:]]+("?/tmp|\$TMPDIR)'; then
    ask "Lệnh xóa đệ quy (rm -rf) — xác nhận trước khi chạy."
  fi
fi

# 2) Git phá hủy lịch sử / working tree
#    Lưu ý: --force-with-lease được cho qua có chủ đích (đây là phương án force an toàn).
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]]+(.*[[:space:]])?(-f|--force)([[:space:]]|$)' && \
  ask "git push --force có thể ghi đè lịch sử trên remote."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' && \
  ask "git reset --hard xóa toàn bộ thay đổi chưa commit."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[^[:space:]]*f' && \
  ask "git clean -f xóa các file chưa được track."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]' && \
  ask "Xóa branch cưỡng bức (git branch -D)."

# 3) SQL phá hủy — chỉ xét khi lệnh gọi tới một DB client thực thi,
#    để grep/cat/echo về SQL không bị chặn nhầm.
if printf '%s' "$cmd" | grep -Eiq '(^|[[:space:]/])(psql|mysql|mariadb|sqlite3|sqlcmd|clickhouse|mongosh|snowsql|beeline|trino|bq)([[:space:]]|$)'; then
  printf '%s' "$cmd" | grep -Eiq 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]' && \
    ask "Lệnh SQL phá hủy (DROP/TRUNCATE)."
  if printf '%s' "$cmd" | grep -Eiq 'DELETE[[:space:]]+FROM' && ! printf '%s' "$cmd" | grep -Eiq 'WHERE'; then
    ask "DELETE FROM không có WHERE — sẽ xóa toàn bộ dữ liệu bảng."
  fi
fi

# 4) Pipe-to-shell và phân quyền nguy hiểm
printf '%s' "$cmd" | grep -Eq '(curl|wget)[^|;]*\|[[:space:]]*(ba|z)?sh' && \
  ask "Tải script từ internet và chạy trực tiếp (pipe-to-shell)."
printf '%s' "$cmd" | grep -Eq 'chmod[[:space:]]+-R[[:space:]]+777' && \
  ask "chmod -R 777 mở toàn quyền cho mọi user."

exit 0
