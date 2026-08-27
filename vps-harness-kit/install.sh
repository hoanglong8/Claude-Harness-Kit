#!/usr/bin/env bash
#
# install.sh — dựng Claude Harness + Hermes Harness trên VPS Linux.
# Idempotent: chạy lại nhiều lần an toàn; luôn backup cấu hình hiện có trước khi ghi đè.
#
# Dùng: bash install.sh            (cài cả Claude + Hermes)
#       bash install.sh claude     (chỉ Claude)
#       bash install.sh hermes     (chỉ Hermes)

set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.harness-backup-$STAMP"
TARGET="${1:-all}"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
say()  { echo -e "${BLUE}▸${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

# --- 0. kiểm tra phụ thuộc -------------------------------------------------
say "Kiểm tra phụ thuộc"
command -v bash >/dev/null || { err "cần bash"; exit 1; }
if command -v jq >/dev/null 2>&1; then
  ok "jq $(jq --version)"
else
  warn "THIẾU jq — các hook guard/verify/checkpoint sẽ tự thoát êm (không chặn lệnh phá hủy)."
  warn "  Cài: sudo apt update && sudo apt install -y jq"
fi

backup_one() {
  local src="$1"
  if [ -e "$src" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$src" "$BACKUP_DIR/" && ok "backup $src → $BACKUP_DIR/"
  fi
}

# --- 1. Claude Harness ---------------------------------------------------
install_claude() {
  say "Cài Claude Harness vào ~/.claude/"
  backup_one "$HOME/.claude/CLAUDE.md"
  backup_one "$HOME/.claude/CLAUDE.local.md"
  backup_one "$HOME/.claude/settings.json"
  backup_one "$HOME/.claude/rules"
  backup_one "$HOME/.claude/hooks"
  backup_one "$HOME/.claude/agents"
  backup_one "$HOME/.claude/skills"
  backup_one "$HOME/.claude/commands"

  mkdir -p "$HOME/.claude"
  # -n: không đè file đã có ở lần copy này KHÔNG dùng — ta muốn cập nhật harness.
  cp -a "$KIT_DIR/claude/CLAUDE.md"                "$HOME/.claude/CLAUDE.md"
  # CLAUDE.local.md không commit (bị .gitignore chặn ở mọi cấp) — kit chứa bản .example.
  # Chỉ tạo nếu chưa có, để không đè preference bạn đã chỉnh trên VPS.
  if [ ! -e "$HOME/.claude/CLAUDE.local.md" ]; then
    cp -a "$KIT_DIR/claude/CLAUDE.local.md.example" "$HOME/.claude/CLAUDE.local.md"
    ok "CLAUDE.local.md tạo mới từ .example"
  else
    warn "CLAUDE.local.md đã tồn tại — giữ nguyên (xem .example nếu muốn đối chiếu)"
  fi
  cp -a "$KIT_DIR/claude/settings.json"    "$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude/rules" "$HOME/.claude/hooks" "$HOME/.claude/agents" \
           "$HOME/.claude/skills" "$HOME/.claude/commands"
  cp -a "$KIT_DIR/claude/rules/."    "$HOME/.claude/rules/"
  cp -a "$KIT_DIR/claude/hooks/."    "$HOME/.claude/hooks/"
  cp -a "$KIT_DIR/claude/agents/."   "$HOME/.claude/agents/"
  cp -a "$KIT_DIR/claude/skills/."   "$HOME/.claude/skills/"
  cp -a "$KIT_DIR/claude/commands/." "$HOME/.claude/commands/"
  chmod +x "$HOME/.claude/hooks/"*.sh
  ok "rules/ agents/ skills/ commands/ hooks/ đã copy; hooks +x"

  # memory seeds
  local seeddir="$HOME/.claude/projects/_seed_/memory"
  mkdir -p "$seeddir"
  cp -a "$KIT_DIR/claude/memory-seeds/." "$seeddir/"
  ok "memory seeds → $seeddir (đổi tên _seed_ thành slug project thật)"
}

# --- 2. Hermes Harness -------------------------------------------------
install_hermes() {
  say "Cài Hermes Harness vào ~/.hermes/"
  if [ ! -d "$HOME/.hermes" ] && ! command -v hermes >/dev/null 2>&1; then
    warn "Chưa thấy Hermes. Cài trước: curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
  fi
  mkdir -p "$HOME/.hermes"
  backup_one "$HOME/.hermes/SOUL.md"
  backup_one "$HOME/.hermes/AGENTS.md"
  cp -a "$KIT_DIR/hermes/SOUL.md"   "$HOME/.hermes/SOUL.md"
  cp -a "$KIT_DIR/hermes/AGENTS.md" "$HOME/.hermes/AGENTS.md"
  ok "SOUL.md + AGENTS.md đã copy"
  warn "config.yaml / .env: KHÔNG tự ghi. Dùng 'hermes setup' hoặc xem $KIT_DIR/hermes/PROFILE-SETUP.md."
}

case "$TARGET" in
  all)    install_claude; install_hermes ;;
  claude) install_claude ;;
  hermes) install_hermes ;;
  *) err "tham số không hợp lệ: $TARGET (all|claude|hermes)"; exit 1 ;;
esac

# --- 3. checklist thủ công -------------------------------------------------
cat <<EOF

$(echo -e "${GREEN}━━━ Cài xong phần tự động ━━━${NC}")

Backup (nếu có) nằm ở: $BACKUP_DIR

Bước thủ công còn lại:
  1. claude            → đăng nhập claude.ai
  2. Mở 1 phiên claude → phải thấy dòng "[FABLE STANDARD ACTIVE]" ở đầu
  3. Thử guard         → gõ: rm -rf /tmp/harness-test   (phải bị hỏi xác nhận)
  4. /model            → đổi sang fable-5 / opus-5 nếu muốn (mặc định: sonnet)
  5. Hermes            → hermes setup  HOẶC  làm theo $KIT_DIR/hermes/PROFILE-SETUP.md
  6. API key Hermes    → thêm HERMES_CUSTOM_FOXAI_QWEN_API_KEY vào file .env
                         (\`hermes config env-path\` để biết đường dẫn) — KHÔNG commit, KHÔNG in ra chat

EOF
