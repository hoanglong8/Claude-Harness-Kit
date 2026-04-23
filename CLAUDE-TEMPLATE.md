# 🤖 Claude Code — Project Harness Setup

Đây là file cấu hình chính cho Claude Code trong project này. Mọi agent session sẽ đọc file này trước khi bắt đầu.

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

- **Never** commit `.credentials.json`, `.env`, or API keys
- **Never** force push to main or develop branches
- **Never** delete data without backup (ask first)
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

## 📞 Escalation

- **Questions about requirements?** Ask in #[project-channel] on Slack
- **Blocker on dependencies?** Tag @[lead-name] in GitHub issue
- **Production incident?** Trigger `/incident-response` skill

---

## 🔗 Quick Links

- **Obsidian Vault:** [URL from MEMORY.md]
- **Monitoring:** [Grafana/DataDog link]
- **Team Docs:** [Confluence/Notion link]
- **Support:** [Project email or Slack channel]

---

⚠️ **This file should be < 60 lines.** If adding more, move to MEMORY.md, `.claude/commands/`, or Layer 4 hooks instead.
