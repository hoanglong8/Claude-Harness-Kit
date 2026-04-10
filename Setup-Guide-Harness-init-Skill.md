# harness-init Skill

**Setup Harness Engineering (5 layers) for new Claude Code projects in one command.**

## Status: ✅ Production Ready

- **Test Results:** 3/3 passed (100% pass rate)
- **Coverage:** Startup, mid-size team, enterprise scenarios
- **Ready to:** Use in projects immediately

## What is Harness Engineering?

A 5-layer framework for Claude Code projects:

1. **Layer 1 (Memory)** — Persistent knowledge: CLAUDE.md, MEMORY.md, slash commands
2. **Layer 2 (Tools)** — Extended capabilities: MCP servers, APIs, integrations
3. **Layer 3 (Permissions)** — Authorization: allowlist/denylist, controlled access
4. **Layer 4 (Hooks)** — Deterministic enforcement: pre/post-tool checks, no bypass
5. **Layer 5 (Observability)** — Monitoring: audit logs, cost tracking, anomaly detection

## Quick Start

```bash
# From your project directory
cd ~/projects/my-new-project
/harness-init

# Answer 5 interactive questions:
# → Project name?
# → Team size (1-5, 5-20, 20+)?
# → Production database (Y/N)?
# → Obsidian vault URL (or SKIP)?
# → Commit to git (Y/N)?

# ✅ Done! .claude/ folder created and customized
```

## What Gets Installed

```
.claude/
├── CLAUDE.md                    Project config
├── MEMORY.md                    Knowledge index
├── settings.json                Permissions + hooks
├── .github/workflows/           Layer 4: Enforcement
│   ├── pre-tool-guardrails.sh   SQL/git/delete safety
│   └── post-tool-audit.sh       Logging + secret detection
├── memory/                      Layer 1: Knowledge
├── commands/                    Slash commands (/setup-vault, /deploy, /standup)
├── observability/               Layer 5: Cost tracking
└── logs/                        Audit trails
```

## Customization by Team Size

| Size | Focus | Guardrails |
|:---:|:---|:---|
| **1-5** | Flexibility | Lenient — focus on getting things done |
| **5-20** | Balancing | Moderate — team needs, safety important |
| **20+** | Compliance | Strict — audit trails, permissions critical |

## Test Results

### Eval 1: Startup Project
- ✅ 11/11 assertions passed
- Settings customized for 1-5 team size
- No prod guardrails (correct for startup)
- Vault skipped (not needed)

### Eval 2: Production Team
- ✅ 12/12 assertions passed
- Prod guardrails enabled (DROP TABLE, migrations)
- Vault URL injected
- Team size 5-20 (moderate strictness)

### Eval 3: Enterprise
- ✅ 14/14 assertions passed
- Strict permissions for 20+ org
- Audit logging enabled
- Enterprise vault integrated

## Next Steps After Running harness-init

1. **Edit .claude/CLAUDE.md** with your tech stack
2. **Add team info** to .claude/memory/user-profile.md
3. **Run /setup-vault** to verify Obsidian connection
4. **Push to GitHub** and you're ready

## Files Included

- **SKILL.md** — Full documentation and usage guide
- **scripts/harness_init.py** — Implementation script (interactive, robust)
- **evals/evals.json** — Test cases for skill validation
- **benchmark.json** — Test results and performance metrics

## How to Install

The skill is ready to use. Install via Claude Code or copy the folder to your skills directory.

## Contact & Feedback

This skill was created to establish Claude Code best practices across teams. All 5 layers have been tested and verified. Ready for production use.

---

### Nghiên cứu mở rộng thêm các skill features khác

```bash
/harness-validate       # Kiểm tra layers hoàn chỉnh
/harness-update         # Sync template lên version mới
/harness-audit          # Xem audit trail từ logs/
/harness-cost           # Xem cost tracking (Layer 5)
```
