# 🚀 Harness Engineering Template — Setup Guide

Bạn vừa tạo template folder hoàn chỉnh cho 5 layers. Đây là hướng dẫn setup cho toàn team.

---

## 📋 Cấu trúc Template

```
template/
├── 📄 CLAUDE.md                    [Layer 1] Main config
├── 📄 MEMORY.md                    [Layer 1] Learning index
├── 📄 settings.json                [Layer 3+4] Permissions & hooks
├── 📁 .github/workflows/           [Layer 4] Enforcement
│   ├── pre-tool-guardrails.sh      (chặn dangerous actions)
│   └── post-tool-audit.sh          (log & verify)
├── 📁 memory/                      [Layer 1] Knowledge base
│   ├── user-profile.md
│   └── reference-vault.md
├── 📁 commands/                    [Layer 1+2] Reusable workflows
│   ├── setup-vault.md
│   ├── deploy.md
│   └── standup.md
├── 📁 observability/               [Layer 5] Monitoring
│   └── cost-tracker.sh
├── 📁 logs/                        [Layer 5] Audit trails
│   └── .gitkeep
└── 📄 .gitignore                   Protect secrets & logs
```

---

## ✅ Step 1: Setup template globally (run ONCE)

```bash
# Navigate to workspace
cd /path/to/workspace

# Make script executable
chmod +x setup-template.sh

# Run setup (copies template to ~/.claude/.template/)
./setup-template.sh
```

**Output:**
```
✅ Template copied to ~/.claude/.template/
✅ Shell scripts are executable
✅ Setup complete!
```

---

## 🎁 Step 2: Create Skill (harness-init) — FOR NEXT PHASE

Trong phần tiếp theo, bạn sẽ tạo skill để:
- Hỏi câu hỏi interactive (project name, team size, prod DB?)
- Copy & customize template
- Commit vào git
- Generate setup report

```bash
/harness-init
# → Automatically setup .claude/ folder cho project mới
```

---

## 👥 Step 3: Sử dụng template cho các project mới

### Manual (cần làm trước khi có skill)
```bash
# Project mới
cd ~/projects/customer-abc/

# Copy template
cp -r ~/.claude/.template/ .claude/

# Customize
vim .claude/CLAUDE.md              # Tech stack, constraints
vim .claude/settings.json          # PROJECT_NAME, permissions
vim .claude/MEMORY.md              # Vault URL, team links

# Commit
git add .claude/
git commit -m "init: setup Harness Engineering 5 layers"
```

### Automatic (sau khi có harness-init skill)
```bash
cd ~/projects/customer-abc/
/harness-init  # 2 phút, interactive setup
```

---

## 🔍 Mỗi Layer là gì?

### **Layer 1: Memory** — Agent luôn biết gì?
- `CLAUDE.md` — Main config (< 60 lines)
- `MEMORY.md` — Learning index, references
- `memory/` — User profile, vault location
- `commands/` — Reusable workflows

**Output:** Persistent knowledge across sessions

---

### **Layer 2: Tools** — Agent làm được gì?
- Built-in: Read, Write, Edit, Bash, Grep, Glob
- MCP servers: Obsidian, GitHub, Slack, v.v.
- Config: `.mcp.json`

**Output:** Extended capabilities (out of filesystem)

---

### **Layer 3: Permissions** — Agent được phép làm gì?
- `settings.json` → Allowlist/denylist
- Pre-approval vs override
- Example: Allow bash, but deny `rm -rf .git`

**Output:** Authorization gates (can be overridden by user)

---

### **Layer 4: Hooks** — Agent không thể phá được gì?
- `.github/workflows/pre-tool-guardrails.sh` — Chặn trước (exit code 2)
- `.github/workflows/post-tool-audit.sh` — Verify sau + log
- No override, deterministic enforcement

**Guardrails:**
- ❌ `DROP TABLE` — SQL safety
- ❌ `git push --force` — Git safety
- ❌ `rm -rf .claude` — Directory safety
- ❌ Credential files — Secrets protection

**Output:** Deterministic enforcement, cannot be bypassed

---

### **Layer 5: Observability** — Bạn có biết agent đang làm gì?
- `logs/audit.jsonl` — Mỗi tool call ghi lại
- `logs/cost.jsonl` — Chi phí per session
- `logs/alerts.jsonl` — Anomalies (high cost, secrets)
- `observability/cost-tracker.sh` — Theo dõi spending

**Output:** Visibility into agent behavior, cost tracking, anomaly detection

---

## 🛠️ Customize per Project

### Minimum (5 phút)
```
CLAUDE.md:
  - Change tech stack (Python/Go/TypeScript)
  - Add team lead name

settings.json:
  - Set PROJECT_NAME
  - Set MCP_SERVER_NAME (obsidian-mcp)

MEMORY.md:
  - Update Obsidian vault URL
  - Add team Slack channel
```

### Recommended (15 phút)
```
Plus above:
  - Add project constraints (no prod delete without backup)
  - Customize guardrails (if project has special rules)
  - Add team communication links
  - Configure cost threshold alert
```

### Complete (30 phút)
```
Plus above:
  - Document all 9 team members
  - Add project-specific commands
  - Configure permissions per role
  - Setup cost tracking budget
```

---

## 📊 Files trong mỗi layer

| Layer | Files | Purpose |
|:---:|:---|:---|
| **1** | CLAUDE.md, MEMORY.md, commands/, memory/ | Knowledge |
| **2** | .mcp.json config | Tools |
| **3** | settings.json (permissions) | Authorization |
| **4** | .github/workflows/ | Enforcement |
| **5** | logs/, observability/ | Observability |

---

## ⚠️ Important Notes

### Never commit to git:
- `.credentials.json` — API keys
- `.env*` files — Environment secrets
- `logs/*.jsonl` — Audit trails (local only)
- `*.key`, `*.pem` — Private keys

Tất cả này được bảo vệ bởi `.gitignore` ✅

### Always enable:
- Layer 4 hooks (deterministic enforcement) — ✅
- Layer 5 logging (observability) — ✅

### Keep CLAUDE.md clean:
- < 60 lines (optimal according to research)
- Move longer docs to MEMORY.md
- Use commands/ for complex workflows

---

## 🚦 Checklist khi setup project mới

- [ ] Copied template từ `~/.claude/.template/`
- [ ] Customized CLAUDE.md (tech stack)
- [ ] Updated settings.json (PROJECT_NAME, permissions)
- [ ] Updated MEMORY.md (vault URL, team links)
- [ ] Made hooks executable (`chmod +x .github/workflows/*.sh`)
- [ ] Committed `.claude/` folder to git
- [ ] Tested: `/setup-vault` works
- [ ] Tested: Pre-tool guardrails catch dangerous commands
- [ ] Tested: Post-tool logging records actions

---

## 📞 Support & Troubleshooting

### Template not copied?
```bash
# Verify template source exists
ls ~/.claude/.template/

# If missing, re-run setup
./setup-template.sh
```

### Hooks not executing?
```bash
# Check if executable
ls -la ~/.claude/.template/.github/workflows/

# Make executable
chmod +x ~/.claude/.template/.github/workflows/*.sh
```

### MCP connection fails?
```bash
# Run validation
/setup-vault

# Check Obsidian running?
# Check .mcp.json API key?
# Check localhost:27123 reachable?
```

---

## 🎯 Next: Create harness-init Skill

**Phase 2:** Tạo skill để automate setup:

```bash
/harness-init
# ↓
# Interactive: project name, team size, prod DB?
# ↓
# Auto: copy template + customize
# ↓
# Auto: commit to git
# ↓
# Report: setup summary + next steps
```

---

**Ready to setup Harness Engineering for your team?** 🚀

Next step: [Coming] Create harness-init skill for automation
