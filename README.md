# 🤖 Claude-Harness-Kit

**Claude-Harness-Kit** là bộ khung (framework) chuẩn hóa dành cho **Claude Code**, được xây dựng dựa trên triết lý **Harness Engineering 5 lớp**. Bộ công cụ này giúp tối ưu hóa khả năng ghi nhớ, tính an toàn và hiệu suất làm việc của AI Agent trong các dự án phần mềm thực tế.

[](https://opensource.org/licenses/MIT)
[](https://anthropic.com)
[](https://github.com/hoanglong8/Claude-Harness-Kit)

-----

## 🌟 Tại sao nên dùng Claude-Harness-Kit?

Việc sử dụng AI Agent trong terminal (Claude Code) đòi hỏi sự kiểm soát chặt chẽ để tránh các sai lầm nguy hiểm và mất ngữ cảnh. **Claude-Harness-Kit** giải quyết các vấn đề:

  - **Mất trí nhớ:** Duy trì ngữ cảnh xuyên suốt các session với Layer 1 (Memory).
  - **Nguy cơ bảo mật:** Chặn các lệnh nguy hiểm (rm, force push) bằng Layer 4 (Hooks).
  - **Mất kiểm soát chi phí:** Theo dõi chi phí API theo thời gian thực với Layer 5 (Observability).
  - **Thiếu quy chuẩn:** Áp dụng Code Style và Workflow đồng nhất cho cả team.

-----

## 🏗️ Kiến trúc 5 Lớp (5-Layer Architecture)

Dự án được cấu trúc chặt chẽ theo mô hình Harness Engineering:

| Layer | Thành phần | Mục tiêu |
|:---:|:---|:---|
| **1** | **Memory** | Lưu trữ tri thức bền vững (`CLAUDE.md`, `MEMORY.md`, `memory/`) |
| **2** | **Tools** | Mở rộng năng lực AI qua MCP servers (Obsidian, GitHub, Slack) |
| **3** | **Permissions** | Phân quyền hoạt động thông qua `settings.json` |
| **4** | **Hooks** | Cưỡng chế an toàn (Deterministic Enforcement) bằng script bảo vệ |
| **5** | **Observability** | Giám sát hành vi, nhật ký (Audit trail) và chi phí (Cost tracking) |

-----

## 📁 Cấu trúc thư mục

```text
Claude-Harness-Kit/
├── 📄 AGENTS.md                    # [Harness v0] Agent Operating Guide
├── 📄 CLAUDE.md                    # [Layer 1] Cấu hình chính (Tech stack, Code style)
├── 📄 MEMORY.md                    # [Layer 1] Index tra cứu tri thức dự án
├── 📄 settings.json                # [Layer 3] Cấp quyền & cấu hình MCP
├── 📄 README.md                    # Tài liệu chính
│
├── 📁 .claude/                     # Local config
│   └── settings.local.json
│
├── 📁 docs/                        # [Harness v0] Documentation & Process
│   ├── 📄 HARNESS.md              # Human-agent collaboration model
│   ├── 📄 FEATURE_INTAKE.md       # Classification & risk framework
│   ├── 📄 ARCHITECTURE.md         # Layering, dependencies, boundaries
│   ├── 📄 TEST_MATRIX.md          # Behavior-to-proof tracking
│   ├── 📄 GLOSSARY.md             # Ubiquitous language
│   ├── 📄 HARNESS_BACKLOG.md      # Proposed harness improvements
│   │
│   ├── 📁 templates/              # Reusable templates
│   │   ├── story.md
│   │   ├── decision.md
│   │   ├── spec-intake.md
│   │   ├── validation-report.md
│   │   └── high-risk-story/
│   │       ├── overview.md
│   │       ├── design.md
│   │       ├── execplan.md
│   │       └── validation.md
│   │
│   ├── 📁 product/                # Current product contracts
│   ├── 📁 stories/                # Story-sized work packets
│   │   └── epics/
│   └── 📁 decisions/              # Architecture Decision Records (ADR)
│
└── 📁 Downloads/                   # Project data (nếu có)
```

-----

## 🚀 Hướng dẫn cài đặt

### 1\. Clone Repository

```bash
git clone https://github.com/hoanglong8/Claude-Harness-Kit.git
cd Claude-Harness-Kit
```

### 2\. Hiểu Harness v0

**Harness v0** = collaboration framework, **KHÔNG có application code**.

Mục tiêu hiện tại: **preserve and grow the harness** trước khi viết code.

**Source of Truth:** Read theo thứ tự:
1. `README.md` → hiểu project status
2. `AGENTS.md` → hiểu agent workflow
3. `docs/FEATURE_INTAKE.md` → phân loại work
4. `docs/ARCHITECTURE.md` → layering rules
5. Các docs khác theo cần thiết

### 3\. Khởi tạo cho Project Mới

**Option A: Manual Setup**
```bash
cd /path/to/your-project/
cp -r ~/Claude-Harness-Kit/docs ./docs
cp ~/Claude-Harness-Kit/AGENTS.md ./
cp ~/Claude-Harness-Kit/CLAUDE-TEMPLATE.md ./CLAUDE.md

# Tùy chỉnh
vim CLAUDE.md           # Tech stack, team info
vim docs/GLOSSARY.md    # Domain terms (nếu có spec)
```

**Option B: Harness Init Skill** (Recommended)
```bash
# Trong Claude Code:
# Dùng harness-init.skill để auto-generate structure
```

### 3\. Kích hoạt bảo vệ (Hooks)

Đảm bảo các script bảo vệ có quyền thực thi:

```bash
chmod +x .claude/.github/workflows/*.sh
```

-----

## 🎯 Harness Workflow

### Feature Intake Process

Mọi work phải qua **intake gate** (xem `docs/FEATURE_INTAKE.md`):

1. **Classify input type:**
   - New spec / Spec slice / Change request / New initiative / Maintenance / Harness improvement

2. **Run risk checklist** (10 flags):
   - Auth, Authorization, Data model, Audit/security, External systems, Public contracts, Cross-platform, Existing behavior, Weak proof, Multi-domain

3. **Choose lane:**
   - **Tiny:** 0-1 flags → patch directly
   - **Normal:** 2-3 flags → create story file
   - **High-risk:** 4+ flags hoặc hard gate → multi-file story packet

4. **Execute + Update:**
   - Implement change
   - Update `docs/TEST_MATRIX.md`
   - Update product docs + decision log nếu cần
   - Add harness friction vào `docs/HARNESS_BACKLOG.md`

### Hard Gates (Require high-risk flow)
  - ❌ Auth changes (login, sessions, JWT)
  - ❌ Authorization (roles, permissions)
  - ❌ Data loss hoặc migration
  - ❌ Audit/security changes
  - ❌ External provider behavior
  - ❌ Removing/weakening validation

-----

## 📐 Architecture Rules

Chi tiết trong `docs/ARCHITECTURE.md`:

### Default Layering
```
domain
  ← application
      ← infrastructure
          ← interface
              ← app surfaces
```

### Dependency Rule
- Inner layers không được depend on outer layers
- Domain layer: pure, không depend framework/database/UI
- Parse unknown data tại boundaries trước khi vào inner code

### Observability Contract
Canonical JSON log format (khi implementation bắt đầu):
```json
{
  "timestamp": "2026-05-08T10:30:00Z",
  "level": "info",
  "request_id": "abc123",
  "user_id": "user_456",
  "action": "user.login",
  "duration_ms": 120,
  "status_code": 200,
  "message": "Login successful"
}
```

-----

## 🧩 Harness Growth

**"Harness grows from friction."**

Khi agent gặp:
- Confusion → improve instruction
- Repeated manual reasoning → add template
- Missing validation → add test command
- Recurring failure → add checklist

→ **Update harness trực tiếp** HOẶC add proposal vào `docs/HARNESS_BACKLOG.md`

---

## 🔗 Tích hợp harness-experimental

Harness này được build dựa trên [harness-experimental](https://github.com/hoangnb24/harness-experimental):

- **CE (harness-experimental)** = theoretical framework (rules, process)
- **CHK (Claude-Harness-Kit)** = practical implementation (tools, templates)

Files được sync từ CE:
- `docs/FEATURE_INTAKE.md`
- `docs/ARCHITECTURE.md`
- `docs/HARNESS.md`
- `docs/templates/*`

-----

## 🤝 Đóng góp

Mọi đóng góp nhằm cải thiện bộ khung Harness Engineering đều được trân trọng. Vui lòng mở `Issue` hoặc gửi `Pull Request`.

-----

## 📄 License

Bản quyền thuộc về **hoanglong8**. Phát hành dưới giấy phép [MIT License](https://www.google.com/search?q=LICENSE).

-----

💡 *“Hãy để AI làm việc hiệu quả, nhưng luôn trong tầm kiểm soát của bạn.”*
