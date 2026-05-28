# Global Claude Code Rules
> Áp dụng cho MỌI project trên máy PC này
> Cập nhật: 2026-05-19 | Nguồn: Tài liệu chính thức Anthropic + kinh nghiệm thực tế

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
- `/model <opus|sonnet|haiku>` — Đổi model
- `/update-config`, `/loop`, `/schedule` — Config & automation

**Auto-Memory Commands:**
```bash
# Xem stats của project hiện tại
bash ~/.claude/bin/auto-memory-system.sh stats

# Khởi tạo memory cho project mới
bash ~/.claude/bin/auto-memory-system.sh init

# Liệt kê tất cả projects có memory
bash ~/.claude/bin/auto-memory-system.sh list-projects
```

---

## 4. KIẾN TRÚC CLAUDE CODE (verified 31/3/2026)

| Thành phần | Chi tiết |
|-----------|---------|
| **QueryEngine** | ~46K LOC — xử lý API calls, streaming, caching |
| **Tool System** | 60+ tools; ~18 ẩn — chỉ xuất hiện khi gọi đúng tên |
| **Multi-agent** | COORDINATOR_MODE: 1 orchestrator điều phối N Claude workers |
| **Output retry** | Auto-inject "Resume directly" — max 3 lần, sau đó dừng |
| **Compaction** | Kích hoạt ~83.5% context; giữ code/task, mất convention |

**Tính năng chưa release (feature-flagged):**
KAIROS · ULTRAPLAN · VOICE_MODE · WEB_BROWSER_TOOL · COORDINATOR_MODE · WORKFLOW_SCRIPTS · PROACTIVE · SSH_REMOTE · MONITOR_TOOL · AGENT_TRIGGERS

---

## 5. BEST PRACTICES ĐÃ KIỂM CHỨNG

**CLAUDE.md:**
- Giữ < 150 dòng — ngắn gọn tuân thủ tốt hơn dài
- 3 cấp: `~/.claude/CLAUDE.md` (global) · `./CLAUDE.md` (project, commit) · `CLAUDE.local.md` (cá nhân, không commit)
- Tạo project-level CLAUDE.md khi: tech stack riêng, linting rules, naming conventions, deploy process cần ghi lại

**Memory:**
- Lưu tại: `~/.claude/projects/<project>/memory/MEMORY.md`
- Chỉ 200 dòng đầu auto-load → giữ index ngắn gọn
- Dùng `/memory` để browse, edit, xóa sai trong session

**Hooks:**
- Hooks > CLAUDE.md cho rule phải thực thi 100%
- Hook quan trọng: **PreCompact** — snapshot state trước nén context
- Config tại: `.claude/settings.json` (pattern: Event → Matcher → Command)

---

## 6. BA & DOCUMENTATION FRAMEWORK

**Auto-Reminder khi nói keywords:**
- "viết tài liệu" / "BA" / "framework" / "glossary" / "specification"
- Tôi auto-suggest 4 câu hỏi + template phù hợp

**Templates:**
- Business Vision / Business Model Canvas
- Ubiquitous Language Glossary
- Event Storming Results
- Implementation Roadmap
- Bounded Context Canvas
- Process Flow / Use Case

**Guide:** `~/.claude/guides/BA-DOCUMENT-FRAMEWORK.md`

---

## 7. RESOURCES & INTEGRATIONS

**MCP Servers:**
- **Hugging Face Hub** — tìm models, datasets, papers (user: hoanglong208)
- **Gmail, Google Calendar** — OAuth authenticate lần đầu
- **Notion, Slack** — đọc/viết pages, messages

**Recommended Skills:**
- `/update-config` — settings.json, hooks, permissions
- `/loop <interval> <cmd>` — chạy lặp lại (monitoring)
- `/schedule` — scheduled remote agents
- `/simplify` — review code quality
- `/security-review` — kiểm tra bảo mật
- `/claude-api` — build/debug Claude API apps

---

## 8. BMAD SURVEY FRAMEWORK

**BMAD = Breakthrough Method of Agile AI-driven Development**

Mỗi request mới: dùng **BMAD Survey Checklist** để khảo sát context trước execute:

**Quick Survey (30s):**
```
1. Type? (Feature / Bug / Refactor / Architecture / Analysis)
2. Complexity? (Simple / Complex / Enterprise)
3. Phase? (Analysis / Planning / Solutioning / Implementation / Retrospective)
4. Requirements rõ? (FRs/NFRs/Scope/Timeline định nghĩa)
5. Stakeholders/Context? (Biết ai approve, ai implement, tech stack)
```

**Nếu ≥1 không rõ:**
→ Suggest Analysis workflow (Brainstorm / Research / Brief / PRFAQ)
→ Hoặc trigger Planning phase trước Implementation

Full framework: `~/.claude/guides/BMAD-SURVEY-FRAMEWORK.md`

---

## 9. DANH SÁCH PROJECTS & FILES THAM KHẢO

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
