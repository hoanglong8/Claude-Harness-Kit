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
.claude/
├── 📄 CLAUDE.md                # [Layer 1] Cấu hình chính (Tech stack, Code style)
├── 📄 MEMORY.md                # [Layer 1] Index tra cứu tri thức dự án
├── 📄 settings.json            # [Layer 3] Cấp quyền & cấu hình MCP
├── 📁 memory/                  # [Layer 1] Chi tiết về team và project context
├── 📁 commands/                # [Layer 1+2] Các workflow tự động hóa (setup, deploy)
├── 📁 .github/workflows/       # [Layer 4] Guardrails (chặn lệnh nguy hiểm)
├── 📁 observability/           # [Layer 5] Tool theo dõi chi phí
└── 📁 logs/                    # [Layer 5] Nhật ký hoạt động & Audit trail
```

-----

## 🚀 Hướng dẫn cài đặt

### 1\. Cài đặt Template toàn cục (Chỉ chạy một lần)

Clone repo này và chạy script setup để lưu template vào máy:

```bash
git clone https://github.com/hoanglong8/Claude-Harness-Kit.git
cd Claude-Harness-Kit
chmod +x setup-template.sh
./setup-template.sh
```

### 2\. Áp dụng cho Dự án mới

Để tích hợp bộ khung này vào dự án của bạn:

```bash
cd /path/to/your-project/
cp -r ~/.claude/.template/ .claude/

# Cấu hình nhanh các thông tin quan trọng
vim .claude/CLAUDE.md    # Thay đổi Tech stack, Lead name
vim .claude/settings.json # Đặt tên Project
vim .claude/MEMORY.md    # Cập nhật link Obsidian/Docs
```

### 3\. Kích hoạt bảo vệ (Hooks)

Đảm bảo các script bảo vệ có quyền thực thi:

```bash
chmod +x .claude/.github/workflows/*.sh
```

-----

## 🛡️ Cơ chế Bảo vệ (Guardrails)

Layer 4 (Hooks) sẽ tự động ngăn chặn AI thực hiện các hành động sau nếu không có sự cho phép đặc biệt:

  - ❌ `DROP TABLE` hoặc các lệnh SQL nguy hiểm.
  - ❌ `git push --force` lên các nhánh chính.
  - ❌ Xóa thư mục cấu hình `.claude`.
  - ❌ Vô tình commit file chứa credentials (`.env`, `.credentials.json`).

-----

## 📈 Observability & Cost Tracking

Hệ thống tự động ghi lại:

  - **Audit Logs:** Mọi tool call mà AI thực hiện tại `logs/audit.jsonl`.
  - **Cost Tracker:** Theo dõi số tiền đã chi tiêu trong session hiện tại để tránh vượt ngân sách.

-----

## 🛠️ Tùy chỉnh (Customization)

  - **CLAUDE.md:** Giữ file này **dưới 60 dòng**. Nếu thông tin quá dài, hãy chuyển sang `MEMORY.md`.
  - **Conventional Commits:** AI sẽ tự động tuân thủ định dạng commit của dự án khi được cấu hình trong Layer 1.

-----

## 🤝 Đóng góp

Mọi đóng góp nhằm cải thiện bộ khung Harness Engineering đều được trân trọng. Vui lòng mở `Issue` hoặc gửi `Pull Request`.

-----

## 📄 License

Bản quyền thuộc về **hoanglong8**. Phát hành dưới giấy phép [MIT License](https://www.google.com/search?q=LICENSE).

-----

💡 *“Hãy để AI làm việc hiệu quả, nhưng luôn trong tầm kiểm soát của bạn.”*
