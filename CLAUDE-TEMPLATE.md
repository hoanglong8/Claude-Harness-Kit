# 🤖 Claude Code — Project Harness Setup

Đây là file cấu hình chính cho Claude Code trong project này. Mọi agent session sẽ đọc file này trước khi bắt đầu.

---

## 🎯 Chuẩn hành vi Fable (ƯU TIÊN CAO NHẤT)

Project này tuân theo **fable-harness** — cài bằng `bash fable-harness/INSTALL.sh .` nếu `.claude/rules/fable/` chưa có. Không thương lượng: không xu nịnh; không bịa số liệu/nguồn/API; không báo "hoàn thành" khi chưa tự chạy/kiểm tra; đúng phạm vi (ngoài phạm vi → báo "Phát hiện thêm"); deliverable lớn → `/intake` trước; trước bàn giao → skill `fable-review`; gửi khách → subagent `fable-critic`; trước khi báo xong task nhiều bước → `fable-verifier`. Khi rule project mâu thuẫn với chuẩn Fable → chuẩn Fable thắng, trừ khi file này ghi rõ ngoại lệ kèm lý do.

---

## 📋 Stack & Conventions

### Tech Stack
- **Language:** [Specify: Python, TypeScript, Go, etc.]
- **Framework:** [e.g., FastAPI, Next.js, Django]
- **Database:** [e.g., PostgreSQL, MongoDB]
- **Testing:** Unit tests required, integration tests for critical paths
- **Version Control:** Git with conventional commits

### Code Style
- **Naming:** snake_case for Python/bash, camelCase for JS/TS
- **Max line length:** 100 characters
- **Comments:** Only for "why", not "what"
- **Type hints:** Required for Python 3.8+

---

## 🚫 Constraints

- Secrets / force push / xóa dữ liệu: fable-harness rule 50 + guard hook đã cưỡng chế — không cần nhắc lại ở đây
- **Production database:** Always backup before running migrations
- **Tests:** Run full test suite before committing (hook will enforce)

---

## ✅ Deliverable Quality

- [ ] Code passes linter (autopep8 for Python, eslint for JS)
- [ ] Type checks pass (mypy for Python)
- [ ] All tests pass (>80% coverage minimum)
- [ ] Commit messages follow conventional format
- [ ] No console.log() or print() in production code

---

## 📞 Escalation & Links

- Requirements → #[project-channel] Slack · Blocker → tag @[lead-name] GitHub · Incident → `/incident-response`
- **Links:** Vault [URL] · Monitoring [Grafana/DataDog] · Docs [Confluence/Notion] · Support [email/Slack]

---

⚠️ **This file should be < 60 lines.** If adding more, move to MEMORY.md, `.claude/commands/`, or Layer 4 hooks instead.
