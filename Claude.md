# Global Claude Code Rules
> Áp dụng cho MỌI project trên máy PC này
> Cập nhật: 2026-04-26 | Nguồn: Tài liệu chính thức Anthropic + kinh nghiệm thực tế

---

## 1. THÔNG TIN CÁ NHÂN

- **Tên:** Nguyễn Hoàng Long | Delivery Center Director | FOXAI,.JSC (fox.ai.vn)
- **Ngôn ngữ:** Luôn trả lời tiếng Việt, thuật ngữ kỹ thuật gốc thì giữ nguyên tiếng Anh và đặt thuật ngữ đã dịch ra tiếng Việt ở trong dấu ngoặc đơn.
- **Trình độ kỹ thuật:** Quản lý dự án (PM), Quản lý sản phẩm (PO), phân tích nghiệp vụ (BA), kỹ sư tư vấn giải pháp Solution Architect và không lập trình trực tiếp.
- **Phong cách làm việc:**
  - Giải thích kỹ thuật bằng ngôn ngữ dễ hiểu cho người quản lý
  - Khi có nhiều lựa chọn: nêu rõ trade-off về chi phí, rủi ro, thời gian
  - Ưu tiên giải pháp thực tế, triển khai được ngay với team hiện tại FOXAI (nhân sự mới, kiêm nhiệm nhiều)
  - Thẳng thắn chỉ ra vấn đề, không cần né tránh

---

## 2. QUY TẮC CONTEXT & SESSION

- Mỗi session = **1 mục tiêu cụ thể** — xong việc mở session mới
- Compact **chủ động** khi context ~70%: `/compact "focus on [X]"`
- Dùng `claude -c` để tiếp tục session cũ thay vì bắt đầu lại
- **CLAUDE.md sống sót qua compaction** — ghi rule vào đây, đừng chỉ nói trong chat

---

## 3. QUY TẮC TOOL & WORKFLOW

- Gọi **tên tool cụ thể** khi muốn dùng: `"Dùng LSP để tìm references của X"`
- Workflow chuẩn cho mọi task lớn: **Explore → Plan → Execute** (không bỏ bước Plan)
- Task bị dừng giữa chừng: prompt `"Continue từ [điểm X]"` — không hỏi lại từ đầu
- Reference file bằng đường dẫn, không paste nội dung vào chat

**Slash Commands hay dùng:**
- `/task-list` — Xem tasks hiện tại
- `/task-create` — Tạo task mới
- `/task-update <id>` — Cập nhật task
- `/compact "focus on [X]"` — Nén context khi ~70%
- `/memory` — Duyệt & quản lý memory
- `/review` — Review PR
- `/security-review` — Kiểm tra bảo mật
- `/help` — Hỏi trợ giúp
- `/model <name>` — Đổi model (opus, sonnet, haiku)

---

## 4. KIẾN TRÚC CLAUDE CODE (source leak 31/3/2026 — đã kiểm chứng)

| Thành phần | Chi tiết |
|-----------|---------|
| QueryEngine | ~46K dòng — xử lý toàn bộ API calls, streaming, caching |
| Tool System | 60+ tools; ~18 ẩn, chỉ xuất hiện qua ToolSearch khi gọi đúng tên |
| Multi-agent | COORDINATOR_MODE: 1 orchestrator điều phối N Claude worker |
| Output retry | Tự inject "Resume directly" — tối đa 3 lần, sau đó dừng hẳn (thiết kế, không phải bug) |
| Compaction | Kích hoạt ~83.5% context; giữ code/task, mất convention nói trong chat |

Tính năng chưa release (feature-flagged):
KAIROS · ULTRAPLAN · VOICE_MODE · WEB_BROWSER_TOOL · COORDINATOR_MODE
WORKFLOW_SCRIPTS · PROACTIVE · SSH_REMOTE · MONITOR_TOOL · AGENT_TRIGGERS

---

## 5. BEST PRACTICES ĐÃ KIỂM CHỨNG

**CLAUDE.md:**
- Giữ < 150 dòng — ngắn gọn tuân thủ tốt hơn dài
- Dùng @.claude/rules/file.md để import chi tiết, tránh phình file chính
- 3 cấp: ~/.claude/CLAUDE.md (global) · ./CLAUDE.md (project, commit git) · CLAUDE.local.md (cá nhân, không commit)
- **Tạo project-level CLAUDE.md khi:** project có tech stack riêng, linting rules, naming conventions, deploy process cần ghi lại

**Memory:**
- Auto memory lưu tại: ~/.claude/projects/<project>/memory/MEMORY.md
- Chỉ 200 dòng đầu được auto-load — giữ index ngắn gọn
- Dùng /memory để browse, edit, xóa memory sai trong session

**Hooks:**
- Hooks > CLAUDE.md cho rule phải thực thi 100%, không có ngoại lệ
- Hook quan trọng nhất: PreCompact — snapshot trạng thái trước khi nén context
- Cấu hình tại: .claude/settings.json theo pattern Event → Matcher → Command

---

## 6. RESOURCES & INTEGRATIONS

**MCP Servers khả dụng:**
- **GitHub** — Quản lý PR, issues, commits, branches, CI status trên GitHub
  - Repo scope: hoanglong8/claude-harness-kit
  - Dùng khi: tạo PR, review code, xem CI, tạo issue
- **Hugging Face Hub** — Tìm models, datasets, papers trên huggingface.co
  - User: hoanglong208
  - Dùng khi: tìm model AI, dataset, hoặc paper research
- **Gmail, Google Calendar** — Cần OAuth authenticate lần đầu
- **Notion, Slack** — Đọc/viết pages, messages, threads

**Recommended Skills:**
- `/update-config` — Cấu hình settings.json, hooks, permissions
- `/loop <interval> <cmd>` — Chạy lặp lại (monitoring, polling)
- `/simplify` — Review code quality sau khi thay đổi
- `/security-review` — Kiểm tra bảo mật branch hiện tại
- `/init` — Khởi tạo CLAUDE.md mới cho project
- `/keybindings-help` — Tùy chỉnh keyboard shortcuts (`~/.claude/keybindings.json`)
- `/fewer-permission-prompts` — Tối ưu allowlist, giảm popup phê duyệt
- `/claude-api` — Build/debug apps với Claude API & Anthropic SDK (caching, tools, batch)

---

## 7. DANH SÁCH PROJECTS & OPPORTUNITIES (14 items)

### **Dự án Triển khai tại Việt Nam (8)**
| # | Project | Client | Folder | Status |
|---|---------|--------|--------|--------|
| 1 | AI Agent cho Sở KHCN Hà Nội | Sở Khoa học & Công nghệ Hà Nội | D:\FoxAI\Dự án Sở KHCN HN | 🔄 |
| 2 | AI Agent cho Sở KHCN Lào Cai | Sở Khoa học & Công nghệ Lào Cai | TBD | 🔄 |
| 3 | AI Agent cho Văn phòng Chính phủ | Văn phòng Chính phủ VPCP | D:\FoxAI\Dự án VPCP | 🔄 |
| 4 | AI Agent cho H05 cục CNTT | H05 Cục CNTT - Bộ Công An | TBD | 🔄 |
| 5 | AI Agent cho Bệnh viện A | Bệnh viện A Thái Nguyên | TBD | 🔄 |
| 6 | Big Data cho TTDL Agribank | Ngân hàng Agribank | TBD | 🔄 |
| 7 | AI Agent cho Đảng ủy Việt Hưng | Đảng ủy phường Việt Hưng | TBD | 🔄 |
| 8 | Big Data cho Bệnh viện Văn Định | Bệnh viện Văn Định | TBD | 🔄 |

### **Dự án Triển khai tại Lào (2)**
| # | Project | Client | Folder | Status |
|---|---------|--------|--------|--------|
| 9 | Chatbot Agent TPLUS | TPLUS Laos | D:\FoxAI\SRC Chatbot Agent TPLUS Laos\ | 🚀 |
| 10 | Chatbot Agent cho LaoVietBank | LaoVietBank | TBD | 🔄 |
| 11 | KPI CRM cho LaoVietBank | LaoVietBank | TBD | 🔄 |

### **Cơ hội Kinh doanh (3) 💼**
| # | Project | Client | Folder | Status |
|---|---------|--------|--------|--------|
| 12 | Big Data cho Đảng ủy Vân Đồn | Đảng ủy phường Vân Đồn | TBD | 💼 Opportunity |
| 13 | Big Data cho LDBank | LDBank (Laos) | TBD | 💼 Opportunity |
| 14 | Big Data cho APBank | APBank (Laos) | TBD | 💼 Opportunity |

> Cập nhật: 2026-04-26 | **11 dự án triển khai + 3 cơ hội kinh doanh**

---

## 8. FILES THAM KHẢO

- **CLI Cheatsheet:** `~/.claude/CLAUDE_CLI_CHEATSHEET.md` — Quick reference cho lệnh & shortcuts
- **Project-level:** `./CLAUDE.md` — Rules cụ thể cho từng project
- **Local-only:** `./CLAUDE.local.md` — Config cá nhân (không commit)
