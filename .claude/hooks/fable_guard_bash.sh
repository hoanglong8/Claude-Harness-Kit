#!/usr/bin/env bash
#
# fable_guard_bash.sh — PreToolUse(Bash) hook (fable-harness)
# Đọc tool input JSON từ stdin; nếu lệnh khớp pattern nguy hiểm thì trả
# permissionDecision=ask để Claude Code hỏi người dùng trước khi chạy.
# Mặc định (không output, exit 0) = cho phép bình thường.
# Muốn chặn hẳn thay vì hỏi: đổi "ask" thành "deny" ở pattern tương ứng.

set -uo pipefail

# Không có jq thì fail-open (không chặn) — rules layer vẫn còn hiệu lực
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -z "$cmd" ] && exit 0

ask() {
  jq -cn --arg reason "[fable-guard] $1 — cần xác nhận của người dùng trước khi chạy." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
  exit 0
}

m() { printf '%s' "$cmd" | grep -Eiq "$1"; }

# --- Git: mất lịch sử / mất thay đổi ---
m 'git[[:space:]]+push[^|;&]*([[:space:]]--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$)|--force-with-lease)' \
  && ask "git push --force: ghi đè lịch sử trên remote"
m 'git[[:space:]]+reset[[:space:]]+--hard' \
  && ask "git reset --hard: mất mọi thay đổi chưa commit"
m 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' \
  && ask "git clean -f: xóa vĩnh viễn file chưa track"
m 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]' \
  && ask "git branch -D: xóa branch chưa merge"

# --- Xóa file đệ quy ---
m 'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*(rf|fr)[a-zA-Z]*([[:space:]]|$)' \
  && ask "rm -rf: xóa đệ quy không hỏi lại"
m 'rm[[:space:]]+.*-r([[:space:]]+.*)?[[:space:]]-f([[:space:]]|$)|rm[[:space:]]+.*-f([[:space:]]+.*)?[[:space:]]-r([[:space:]]|$)' \
  && ask "rm -r -f: xóa đệ quy không hỏi lại"

# --- SQL phá hủy ---
m '(^|[^a-zA-Z])drop[[:space:]]+(table|database|schema)' \
  && ask "DROP: xóa cấu trúc dữ liệu"
m '(^|[^a-zA-Z])truncate([[:space:]]+table)?[[:space:]]' \
  && ask "TRUNCATE: xóa toàn bộ dữ liệu bảng"
if m '(^|[^a-zA-Z])delete[[:space:]]+from[[:space:]]' && ! m '[[:space:]]where[[:space:]]'; then
  ask "DELETE FROM không có WHERE: xóa toàn bộ dữ liệu bảng"
fi

# --- Hạ tầng ---
m 'terraform[[:space:]]+destroy'            && ask "terraform destroy: hủy hạ tầng"
m 'kubectl[[:space:]]+delete'               && ask "kubectl delete: xóa tài nguyên cluster"
m 'docker[[:space:]]+(system|volume)[[:space:]]+prune' && ask "docker prune: xóa dữ liệu Docker"

exit 0
