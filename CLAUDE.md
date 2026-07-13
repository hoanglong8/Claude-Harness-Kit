# Global Claude Code Rules
> Áp dụng cho MỌI project trên máy PC này
> Cập nhật: 2026-07-12 | Nguồn: Tài liệu chính thức Anthropic + kinh nghiệm thực tế

---

## 1. THÔNG TIN CÁ NHÂN

- **Tên:** Nguyễn Hoàng Long | Delivery Center Director | FOXAI, JSC (fox.ai.vn)
- **Ngôn ngữ:** Luôn trả lời tiếng Việt, thuật ngữ kỹ thuật gốc thì giữ nguyên tiếng Anh (trong dấu ngoặc đơn là dịch)
- **Trình độ kỹ thuật:** PM/PO/BA/Solution Architect — không lập trình trực tiếp
- **Phong cách làm việc:**
  - Giải thích kỹ thuật dễ hiểu cho quản lý
  - Nêu rõ trade-off: chi phí, rủi ro, thời gian
  - Ưu tiên giải pháp thực tế với team FOXAI (nhân sự mới, kiêm nhiệm)
  - Thẳng thắn chỉ ra vấn đề

---

## 2. QUY TẮC CONTEXT & SESSION

- Mỗi session = **1 mục tiêu cụ thể** → xong việc mở session mới
- Compact **chủ động** khi context ~70%: `/compact "focus on [X]"`
- Tiếp tục session cũ: `claude -c` (thay vì bắt đầu lại)
- **CLAUDE.md sống sót qua compaction** → ghi rule vào đây, không chỉ nói trong chat

---

## 3. QUY TẮC TOOL & WORKFLOW

- Gọi **tên tool cụ thể**: `"Dùng Grep để tìm X"` (không mơ hồ)
- Workflow chuẩn: **Explore → Plan → Execute** (không bỏ bước Plan)
- Continue giữa chừng: `"Continue từ [điểm X]"` (không hỏi lại từ đầu)
- Reference file: đường dẫn (không paste nội dung vào chat)

**Token-saving tool rules:**
- PDF: dùng `pdftotext` CLI, **không** dùng `Read` (Read load PDF như ảnh = tốn x5 token)
- Web fetch: ưu tiên `WebFetch` (free, text-only) → `agent-browser` CLI khi cần dynamic page/auth wall (~82% ít token hơn screenshot tools) → nếu cùng fetch pattern xuất hiện >1 lần, propose wrap thành dedicated tool
- Subagent model: Haiku (bulk/cơ học) · Sonnet (research có scope) · Opus (planning/trade-off phức tạp)
- Spawn subagent khi: isolate context, parallelize, bulk tasks — KHÔNG spawn khi parent cần reasoning
- Subagent escalation: nếu subagent nhận ra cần tier cao hơn → return về parent, không tự upgrade

**Patterns lặp lại — bake in từ session analysis (2026-05-19):**
- Request "đọc repo / rà soát / bổ sung": **Explore README + cấu trúc thư mục trước** — không skip dù repo quen
- Request "viết tài liệu" cho dự án: hỏi rõ **đối tượng đọc + format output** trước khi viết
- Khi làm việc với Claude repo cá nhân: đọc CLAUDE.md + memory hiện tại trước khi thay đổi

**Slash Commands thường dùng:**
- `/task-list`, `/task-create`, `/task-update <id>` — Quản lý tasks
- `/memory` — Duyệt & quản lý auto-memory
- `/compact "focus on [X]"` — Nén context khi ~70%
- `/review`, `/security-review` — Review PR/branch
- `/intake` — Khai thác yêu cầu trước deliverable lớn (bắt buộc theo rule 20)
- `/model <opus|sonnet|haiku>` — Đổi model (mặc định: Fable 5)
- `/update-config`, `/loop`, `/schedule` — Config & automation

**Auto-Memory:** lệnh `stats / init / list-projects` — chi tiết đã tách ra `.claude/rules/auto-memory.md` (tự nạp)

---

## 4. NỘI DUNG ĐÃ TÁCH RA `~/.claude/rules/` (tự nạp mỗi phiên — không dùng `@import` vì sẽ nạp trùng)

- `claude-code-architecture.md` — kiến trúc Claude Code (QueryEngine, tools, compaction...)
- `bmad-survey.md` — BMAD Quick Survey 30s; bản đầy đủ: `~/.claude/guides/BMAD-SURVEY-FRAMEWORK.md`; deliverable lớn vẫn bắt buộc `/intake`
- `auto-memory.md` — lệnh auto-memory system
- `fable/` (10 file) — chuẩn hành vi Fable (xem section 9)

---

## 5. BEST PRACTICES ĐÃ KIỂM CHỨNG

**CLAUDE.md:**
- Giữ < 150 dòng — ngắn gọn tuân thủ tốt hơn dài
- Dùng `@.claude/rules/file.md` để import chi tiết, tránh phình file chính
- 3 cấp: `~/.claude/CLAUDE.md` (global) · `./CLAUDE.md` (project, commit) · `CLAUDE.local.md` (cá nhân, không commit)
- Tạo project-level CLAUDE.md khi: tech stack riêng, linting rules, naming conventions, deploy process cần ghi lại
- **Linux case-sensitive:** luôn đặt tên `CLAUDE.md` (all-caps), không dùng `Claude.md`

**Memory:**
- Lưu tại: `~/.claude/projects/<project>/memory/MEMORY.md`
- Chỉ 200 dòng đầu auto-load → giữ index ngắn gọn
- Dùng `/memory` để browse, edit, xóa sai trong session

**Hooks:**
- Hooks > CLAUDE.md cho rule phải thực thi 100%
- Đang chạy global (fable-harness): SessionStart (neo chuẩn), PreToolUse guard (chặn lệnh phá hủy Bash/PowerShell), Stop verify (chặn claim "hoàn thành" không bằng chứng), PreCompact checkpoint (snapshot vào `.claude/checkpoints/`)
- Config tại: `.claude/settings.json` (pattern: Event → Matcher → Command); hooks .sh tự fallback sang .ps1 khi thiếu jq

---

## 6. BA & DOCUMENTATION FRAMEWORK

Keywords "viết tài liệu / BA / framework / glossary / specification" → auto-suggest 4 câu hỏi + template phù hợp (Business Vision, BMC, Glossary, Event Storming, Roadmap, Bounded Context Canvas, Process Flow / Use Case). Chi tiết: `~/.claude/guides/BA-DOCUMENT-FRAMEWORK.md`

---

## 7. RESOURCES & INTEGRATIONS

**MCP Servers:**
- **Hugging Face Hub** — tìm models, datasets, papers (user: hoanglong208)
- **Gmail, Google Calendar** — OAuth authenticate lần đầu
- **Notion, Slack** — đọc/viết pages, messages
- **GitHub** — xem PR, issues, CI status, tạo PR (scoped per session)

**Recommended Skills:** `/update-config` · `/loop` · `/schedule` · `/simplify` · `/security-review` · `/claude-api` · `/run` · `/verify` · `/code-review` · `/dataviz`

---

## 8. DANH SÁCH PROJECTS & FILES THAM KHẢO

**Projects (14 items):**
- Dự án Triển khai VN: Sở KHCN HN, Lào Cai, VPCP, Công An, Bệnh viện A, Agribank, Việt Hưng, Văn Định
- Dự án Lào: TPLUS, LaoVietBank
- Cơ hội KD: Vân Đồn, LDBank, APBank

**Files Tham Khảo:**
- `~/.claude/guides/BMAD-SURVEY-FRAMEWORK.md` — BMAD survey & workflows
- `~/.claude/guides/BA-DOCUMENT-FRAMEWORK.md` — BA document templates
- `~/.claude/CLAUDE_QUICK_COMMANDS.md` — Quick reference
- `./CLAUDE.md` — Project-level rules (nếu có)
- `./CLAUDE.local.md` — Personal config (không commit)

---

## 9. CHUẨN HÀNH VI FABLE (fable-harness — đã cài global, EVAL 12/12)

10 rules trong `~/.claude/rules/fable/` TỰ ĐỘNG NẠP mọi phiên — không cần nhắc lại ở đây. Điểm neo bắt buộc theo loại việc:

| Tình huống | Hành động |
|---|---|
| Deliverable lớn (>5 trang, cost model, slide deck) | Chạy `/intake` trước khi viết |
| Trước khi bàn giao sản phẩm quan trọng | Chạy skill `fable-review` |
| Deliverable gửi khách / trình lãnh đạo | Gọi subagent `fable-critic` phản biện |
| Trước khi báo "hoàn thành" task nhiều bước | Gọi subagent `fable-verifier` kiểm chứng |
| Kiểm số liệu trong văn bản | Viết phép tính tường minh, cấm kiểm nhẩm (rule 20) |

Nguồn chuẩn: `C:\Users\Admin\fable-harness\` (canonical) · Đo lường: `fable-harness/EVAL-canary-prompts.md` · Skill dạy (on-demand, không nạp thường trực): `/fable-mindset`

---

## 10. GIT TRÊN MÁY NÀY — QUY TẮC AN TOÀN BẮT BUỘC

- **Repo root là CẢ home directory `C:\Users\Admin`**, remote = github.com/hoanglong8/Claude-Harness-Kit (public). Hệ quả:
  - **TUYỆT ĐỐI KHÔNG `git add .` / `git add -A` từ home** — sẽ kéo file cá nhân (Downloads, Documents, .ssh...) lên repo public. Luôn `git add` đích danh từng path.
  - Sửa fable-harness: sửa tại `fable-harness/` (canonical, tracked) → đồng bộ sang `~/.claude/` (bản chạy) và `~\.claude\Claude-Harness-Kit\` (working copy, đã gitignore — không commit lại)
  - File `.ps1` của harness phải giữ UTF-8 BOM (PowerShell 5.1 đọc không BOM sẽ vỡ tiếng Việt)
- Secrets: không set `ANTHROPIC_API_KEY` trong env (đè lên login claude.ai); key 9router nằm trong Windows Credential Manager (resource `9router`, user `api`) — không tạo lại file key plaintext
