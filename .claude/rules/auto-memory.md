# Auto-Memory System — Commands

> Tách từ CLAUDE.md section 3 (2026-07-11) — tự nạp qua `~/.claude/rules/`.

```bash
# Xem stats của project hiện tại
bash ~/.claude/bin/auto-memory-system.sh stats

# Khởi tạo memory cho project mới
bash ~/.claude/bin/auto-memory-system.sh init

# Liệt kê tất cả projects có memory
bash ~/.claude/bin/auto-memory-system.sh list-projects
```

Memory lưu tại `~/.claude/projects/<project>/memory/MEMORY.md` — chỉ 200 dòng đầu auto-load; dùng `/memory` để browse/edit/xóa trong session.
