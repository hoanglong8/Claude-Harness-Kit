#!/usr/bin/env bash
# fable-harness — cài vào một project Claude Code
# Cách dùng:  bash INSTALL.sh /duong/dan/toi/project
# Yêu cầu:    bash 4+, jq
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Cách dùng: bash INSTALL.sh /duong/dan/toi/project" >&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || { echo "Thiếu jq — cài bằng: apt-get install jq / brew install jq" >&2; exit 1; }

TC="$TARGET/.claude"
mkdir -p "$TC/rules" "$TC/skills" "$TC/agents" "$TC/commands" "$TC/hooks"

copied=0; skipped=0
copy_no_clobber() { # copy_no_clobber <src> <dst>
  if [ -e "$2" ]; then
    echo "  BỎ QUA (đã tồn tại): ${2#"$TARGET"/}"; skipped=$((skipped+1))
  else
    mkdir -p "$(dirname "$2")"; cp "$1" "$2"; copied=$((copied+1))
  fi
}

echo "== Copy rules / skill / agents / command / hooks =="
for f in "$SRC_DIR"/.claude/rules/fable/*.md; do
  copy_no_clobber "$f" "$TC/rules/fable/$(basename "$f")"
done
copy_no_clobber "$SRC_DIR/.claude/skills/fable-review/SKILL.md" "$TC/skills/fable-review/SKILL.md"
copy_no_clobber "$SRC_DIR/.claude/agents/fable-critic.md"       "$TC/agents/fable-critic.md"
copy_no_clobber "$SRC_DIR/.claude/agents/fable-verifier.md"     "$TC/agents/fable-verifier.md"
copy_no_clobber "$SRC_DIR/.claude/commands/intake.md"           "$TC/commands/intake.md"
copy_no_clobber "$SRC_DIR/.claude/hooks/fable_session_context.sh" "$TC/hooks/fable_session_context.sh"
copy_no_clobber "$SRC_DIR/.claude/hooks/fable_guard_bash.sh"      "$TC/hooks/fable_guard_bash.sh"
chmod +x "$TC/hooks/fable_session_context.sh" "$TC/hooks/fable_guard_bash.sh"

echo "== Merge hooks vào settings.json =="
SETTINGS="$TC/settings.json"
FRAGMENT="$SRC_DIR/.claude/settings.fable.json"

if [ -f "$SETTINGS" ] && grep -q 'fable_guard_bash' "$SETTINGS"; then
  echo "  BỎ QUA: settings.json đã chứa hook fable (tránh trùng lặp)."
else
  if [ ! -f "$SETTINGS" ]; then
    cp "$FRAGMENT" "$SETTINGS"
    echo "  Đã tạo mới settings.json."
  else
    jq -e . "$SETTINGS" >/dev/null || { echo "LỖI: settings.json hiện tại không phải JSON hợp lệ — sửa trước rồi chạy lại." >&2; exit 1; }
    tmp=$(mktemp)
    jq -s '
      .[0] as $cur | .[1] as $fab |
      $cur
      | .hooks["SessionStart"] = ((.hooks["SessionStart"] // []) + $fab.hooks.SessionStart)
      | .hooks["PreToolUse"]  = ((.hooks["PreToolUse"]  // []) + $fab.hooks.PreToolUse)
    ' "$SETTINGS" "$FRAGMENT" > "$tmp"
    jq -e . "$tmp" >/dev/null
    mv "$tmp" "$SETTINGS"
    echo "  Đã append hook groups vào settings.json (giữ nguyên hooks hiện có)."
  fi
fi

echo "== Kiểm tra sau cài =="
ok=1
for p in "$TC/rules/fable/00-fable-core.md" "$TC/skills/fable-review/SKILL.md" \
         "$TC/agents/fable-critic.md" "$TC/agents/fable-verifier.md" \
         "$TC/commands/intake.md" "$TC/hooks/fable_guard_bash.sh"; do
  [ -f "$p" ] || { echo "  THIẾU: $p"; ok=0; }
done
[ -x "$TC/hooks/fable_guard_bash.sh" ] || { echo "  Hook chưa có quyền thực thi"; ok=0; }
jq -e . "$SETTINGS" >/dev/null 2>&1 || { echo "  settings.json không hợp lệ"; ok=0; }

echo ""
echo "Kết quả: copy $copied file, bỏ qua $skipped file."
if [ "$ok" -eq 1 ]; then
  echo "CÀI ĐẶT HOÀN TẤT. Bước tiếp theo:"
  echo "  1. (Tùy chọn) Ghép CLAUDE.md.fable-section.md vào CLAUDE.md của project."
  echo "  2. Khởi động lại phiên Claude Code, chạy /memory để xác nhận rules đã nạp."
  echo "  3. Chạy bộ kiểm thử trong EVAL-canary-prompts.md."
else
  echo "CÀI ĐẶT CHƯA HOÀN CHỈNH — xem các dòng THIẾU/LỖI phía trên."
  exit 1
fi
