# Template Usage Guide

Đây là template folder cho Claude Code Harness Engineering 5 layers.

## 📁 Cấu trúc

```
.template/
├── CLAUDE.md                    ← Main config (read by Claude Code)
├── MEMORY.md                    ← Learning & reference index
├── settings.json                ← Permissions & hooks config
├── .gitignore                   ← Protect logs & credentials
│
├── .github/workflows/           ← Layer 4: Hooks (enforcement)
│   ├── pre-tool-guardrails.sh   (chặn dangerous actions)
│   └── post-tool-audit.sh       (log & verify)
│
├── memory/                      ← Layer 1: Persistent knowledge
│   ├── user-profile.md.template
│   └── reference-vault.md.template
│
├── commands/                    ← Layer 2: Reusable workflows
│   ├── setup-vault.md
│   ├── deploy.md
│   └── standup.md
│
├── observability/               ← Layer 5: Monitoring
│   └── cost-tracker.sh          (track spending & anomalies)
│
└── logs/                        ← Layer 5: Audit trails (git-ignored)
    └── .gitkeep
```

## 🚀 Cách sử dụng

### 1. Copy template vào project mới
```bash
# Copy toàn bộ template
cp -r ~/.claude/.template/ /path/to/new-project/.claude/

# Hoặc dùng skill (recommended)
/harness-init  # Interactive setup + customize
```

### 2. Customize cho project
File cần chỉnh sửa:
- **CLAUDE.md** → Thêm tech stack, constraints cho project
- **settings.json** → Set `{{ PROJECT_NAME }}`, `{{ MCP_SERVER_NAME }}`
- **MEMORY.md** → Update links đến Obsidian vault, team docs
- **Hooks** → Tùy chỉnh guardrails nếu project có rules riêng

### 3. Commit vào git
```bash
cd /path/to/new-project
git add .claude/
git commit -m "init: setup Harness Engineering 5 layers"
```

### 4. Verify setup
```bash
# Chạy validation (optional, sau khi có skill)
/harness-validate

# Hoặc manual check:
• .claude/CLAUDE.md exists & < 60 lines
• .claude/settings.json valid JSON
• .claude/.github/workflows/*.sh files are executable
• .claude/logs/ exists
```

## 📚 Mỗi Layer là gì?

| Layer | File | Purpose |
|:---:|:---|:---|
| **1** | CLAUDE.md, MEMORY.md, commands/ | Agent luôn biết gì (persistent knowledge) |
| **2** | settings.json, tools config | Agent làm được gì (capabilities) |
| **3** | settings.json permissions | Agent được phép làm gì (authorization) |
| **4** | .github/workflows/ hooks | Agent không thể phá được gì (enforcement) |
| **5** | logs/, observability/ | Bạn có biết agent đang làm gì (monitoring) |

## ⚠️ Quan trọng

- **Never commit** `.credentials.json`, `.env`, logs
- **Always enable** `.github/workflows/` hooks (Layer 4)
- **Keep CLAUDE.md < 60 lines** — use MEMORY.md for longer docs
- **Run `/setup-vault`** in new project to test MCP connection

## 📞 Support

- **Questions about template?** Check memory/ folder for references
- **Need to customize hooks?** Edit `.github/workflows/*.sh` directly
- **Want to extend?** Add new commands in `commands/` folder

---

Happy automating! 🚀
