# Memory — Commands & Convention

> Tự nạp qua `~/.claude/rules/`.

Memory của mỗi project lưu tại `~/.claude/projects/<project-slug>/memory/`:
- `MEMORY.md` — index, chỉ ~200 dòng đầu auto-load mỗi phiên → giữ ngắn gọn, mỗi memory 1 dòng.
- `<topic>.md` — 1 file = 1 fact, có frontmatter (`name`, `description`, `metadata.type: user|feedback|project|reference`).

Trong phiên: dùng `/memory` để browse / edit / xóa memory.

**Auto-capture cuối phiên** (theo CLAUDE.local.md §6): khi user nói "xong"/"done" hoặc context ~80%, tự ghi lại insight có giá trị (decisions, learnings, blockers, next actions, non-obvious patterns) vào `<topic>.md` + thêm 1 dòng vào `MEMORY.md`. Không spam việc vặt.

> Ghi chú: script `auto-memory-system.sh` (stats / init / list-projects) trên máy nguồn KHÔNG nằm trong kit này. Cơ chế `/memory` gốc của Claude Code đã đủ dùng; nếu muốn script đó, cài riêng.
