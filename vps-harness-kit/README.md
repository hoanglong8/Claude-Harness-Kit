# VPS Harness Kit — Claude Code + Hermes Agent

Bộ file cấu hình để dựng **Claude Harness** (chuẩn hành vi Fable cho Claude Code) và
**Hermes Harness** (chuẩn hành vi tương đương cho Hermes Agent) trên một VPS Linux mới,
cá nhân hoá cho **Nguyễn Hoàng Long — Delivery Center Director, FOXAI JSC**.

Trạng thái: **Đã viết, chưa chạy trên VPS thật** (soạn trên máy Windows nguồn ngày 2026-08-27).
Các script bash trong kit chưa được thực thi end-to-end — xem mục "Chưa kiểm chứng" cuối file.

---

## 1. Yêu cầu VPS

| Thành phần | Bắt buộc | Ghi chú |
|---|---|---|
| OS | Ubuntu/Debian x64 (bash) | Kit chỉ có hook `.sh` |
| `git`, `curl`, `bash` | Có | thường sẵn |
| `jq` | Có | các hook guard/verify/checkpoint cần `jq`; thiếu `jq` hook tự thoát êm (không chặn) |
| Claude Code CLI | Có | `curl -fsSL https://claude.ai/install.sh \| bash` rồi `claude` để đăng nhập claude.ai |
| Hermes Agent (tùy chọn) | Nếu dùng phần Hermes | `curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \| bash` |

---

## 2. Cây thư mục kit

```
vps-harness-kit/
├── README.md                 ← file này
├── install.sh                ← script cài đặt idempotent (có backup)
├── claude/                   → copy vào ~/.claude/
│   ├── CLAUDE.md                 global rules, đã cá nhân hoá + Linux paths
│   ├── CLAUDE.local.md.example   preference cá nhân — install.sh copy sang CLAUDE.local.md nếu chưa có
│   ├── settings.json             chỉ đăng ký 4 hook Fable + permissions read-only
│   ├── rules/
│   │   ├── fable/00..75 (10 file)   chuẩn hành vi Fable — auto-load mọi phiên
│   │   ├── bmad-survey.md
│   │   └── claude-code-architecture.md
│   ├── agents/                   fable-critic, fable-verifier, opus-as-fable
│   ├── skills/                   fable-review/, fable-mindset/
│   ├── commands/intake.md
│   ├── hooks/                    4 hook Fable + session-start.sh
│   └── memory-seeds/             copy vào ~/.claude/projects/<proj>/memory/
├── hermes/                   → copy vào ~/.hermes/
│   ├── SOUL.md                   identity + chuẩn Fable (bản gốc chỉ 1 dòng generic)
│   ├── AGENTS.md                 neo rule cho mọi workdir Hermes
│   ├── PROFILE-SETUP.md          các lệnh tái tạo profile foxai-qwen
│   ├── config.yaml.example       tham khảo (ưu tiên dùng `hermes setup`)
│   └── env.example              tên biến môi trường, KHÔNG chứa key thật
└── (không có file secret nào — mọi API key đều là placeholder)
```

---

## 3. Cài đặt nhanh

```bash
# trên VPS, sau khi scp/git kit về
cd ~/vps-harness-kit
bash install.sh
```

`install.sh` sẽ:
1. Kiểm tra `jq` (cảnh báo nếu thiếu, gợi ý `sudo apt install jq`).
2. Backup `~/.claude/` và `~/.hermes/` hiện có (nếu có) sang `~/.harness-backup-<timestamp>/`.
3. Copy `claude/*` → `~/.claude/` và `hermes/{SOUL.md,AGENTS.md}` → `~/.hermes/`.
4. `chmod +x ~/.claude/hooks/*.sh`.
5. Copy `claude/memory-seeds/*` → `~/.claude/projects/_seed_/memory/` để bạn đổi tên theo project.
6. In ra checklist các bước thủ công còn lại.

### Bước thủ công sau khi chạy install.sh

- **Claude Code:** chạy `claude`, đăng nhập claude.ai. Kiểm tra hook nạp đúng: đầu phiên phải thấy dòng `[FABLE STANDARD ACTIVE]`.
- **Model:** mặc định trong `settings.json` là `sonnet`. Đổi bằng `/model` trong phiên hoặc sửa key `"model"`.
- **Hermes:** chạy `hermes setup` (wizard) hoặc theo `hermes/PROFILE-SETUP.md` để tạo profile `foxai-qwen`. Key thật thêm vào file `.env` (`hermes config env-path` để biết đường dẫn) dưới tên `HERMES_CUSTOM_FOXAI_QWEN_API_KEY` — **không** commit, **không** in ra chat.
- **Memory:** đổi tên `~/.claude/projects/_seed_/` thành slug project thật (Claude Code sẽ tự tạo thư mục project khi bạn mở; copy các seed `.md` vào `memory/` của nó).

---

## 4. Cách hoạt động của Claude Harness

| Cơ chế | File | Tác dụng |
|---|---|---|
| Auto-load rules | `~/.claude/rules/**/*.md` | mọi file `.md` ở đây tự vào context đầu phiên — **không** thêm `@import` (sẽ nạp trùng) |
| SessionStart anchor | `hooks/fable_session_context.sh` | in `[FABLE STANDARD ACTIVE]` neo 5 non-negotiable, sống sót qua `/clear` |
| PreToolUse guard | `hooks/fable_guard_bash.sh` | buộc hỏi xác nhận trước `rm -rf`, `git push --force`, `git reset --hard`, `DROP/TRUNCATE`, pipe-to-shell… |
| Stop verify | `hooks/fable_stop_verify.sh` | chặn khi message cuối tuyên bố "hoàn thành/chạy được" nhưng lượt không có tool call tạo bằng chứng |
| PreCompact checkpoint | `hooks/fable_precompact_checkpoint.sh` | snapshot transcript vào `<project>/.claude/checkpoints/` (giữ 5 bản) trước khi nén context |

Neo bắt buộc theo loại việc (nhắc trong `CLAUDE.md` §9):
deliverable lớn → `/intake` trước · trước bàn giao → skill `fable-review` ·
tài liệu gửi khách → subagent `fable-critic` · trước khi báo "hoàn thành" việc nhiều bước → subagent `fable-verifier`.

---

## 5. Chưa kiểm chứng

- `install.sh` và 4 hook `.sh` **chưa chạy trên Linux thật** trong lần soạn này. Cần chạy thử `bash install.sh` trên VPS rồi mở một phiên `claude` để xác nhận: (a) dòng anchor xuất hiện, (b) `rm -rf /tmp/x` bị hook hỏi xác nhận, (c) `/intake` gọi được.
- Schema `hermes/config.yaml.example` trích từ `config.yaml` thật của profile `foxai-qwen` trên máy nguồn (schema `_config_version 35`), **chưa đối chiếu với bản Hermes cài trên VPS**. Ưu tiên `hermes setup` / `hermes setup model` làm nguồn chuẩn; file example chỉ để tham khảo.
- Endpoint FOXAI Qwen (`222.252.99.27:8035`) lấy từ memory ngày 2026-08-17 — xác nhận còn sống trước khi tin.
- Các file rule/agent/skill/command là bản sao từ máy nguồn (fable-harness EVAL 12/12 trên Sonnet); EVAL **chưa chạy lại** trên VPS.
