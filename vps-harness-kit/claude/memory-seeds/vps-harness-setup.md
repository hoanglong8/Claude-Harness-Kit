---
name: vps-harness-setup
description: VPS mới dựng Claude Harness + Hermes Harness từ vps-harness-kit ngày 2026-08-27 — trạng thái cài đặt và việc cần kiểm chứng
metadata:
  type: project
---

VPS Linux (Ubuntu/Debian) dựng harness từ bộ `vps-harness-kit` ngày 2026-08-27 (soạn trên máy Windows nguồn của anh Long).

Cài bằng `bash install.sh` — copy `claude/*` → `~/.claude/`, `hermes/{SOUL.md,AGENTS.md}` → `~/.hermes/`, backup cấu hình cũ sang `~/.harness-backup-<timestamp>/`.

**Nội dung:** fable-harness đầy đủ (10 rule auto-load, 4 hook Fable, /intake, fable-review, fable-mindset, 3 agent) + Hermes SOUL.md/AGENTS.md viết theo chuẩn Fable. KHÔNG gồm skill nghiệp vụ FOXAI (agent-factory, book-writer, llm-wiki, learning-portal).

**Cần kiểm chứng trên VPS:**
- `install.sh` + 4 hook `.sh` chưa chạy trên Linux thật — xác nhận dòng `[FABLE STANDARD ACTIVE]` xuất hiện đầu phiên; `rm -rf /tmp/x` bị hook hỏi xác nhận.
- Hook cần `jq` — thiếu `jq` là hook thoát êm, không enforce.
- Hermes profile `foxai-qwen`: endpoint `http://222.252.99.27:8035/v1`, model `qwen3.6-35b-a3b` — lấy từ memory 2026-08-17, xác nhận còn sống. Dựng bằng `hermes setup` hoặc `hermes/PROFILE-SETUP.md`. Key đặt qua `hermes auth`, không ghi file.
- `settings.json` để `"model": "sonnet"`.
