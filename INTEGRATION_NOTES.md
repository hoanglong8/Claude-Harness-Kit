# Integration Notes: harness-experimental → Claude-Harness-Kit

**Ngày tích hợp:** 2026-05-08  
**Harness version:** v0 → v1 (enriched)

---

## I. TỔNG QUAN

### Nguồn gốc

- **harness-experimental (CE):** Theoretical framework cho human-agent collaboration
  - Repository: https://github.com/hoangnb24/harness-experimental
  - Scope: Process definitions, templates, operating rules
  - Audience: Agents nhận task

- **Claude-Harness-Kit (CHK):** Practical harness initialization tool
  - Repository: https://github.com/hoanglong8/Claude-Harness-Kit
  - Scope: Setup scripts, scaffolding, Claude Code integration
  - Audience: Humans + Agents dùng tool

### Quan hệ

```
harness-experimental (CE)     Claude-Harness-Kit (CHK)
        ↓                              ↓
    RULES                           TOOLS
    PROCESS                    IMPLEMENTATION
    TEMPLATES                   SCAFFOLDING
        └──────── COMPLEMENTARY ─────────┘
```

**Không mâu thuẫn — bổ sung lẫn nhau.**

---

## II. FILES ĐÃ TÍCH HỢP

### Sync trực tiếp từ CE (copy nguyên bản)

| File từ CE | Vị trí trong CHK | Status | Notes |
|-----------|-----------------|--------|-------|
| `docs/FEATURE_INTAKE.md` | `docs/FEATURE_INTAKE.md` | ✅ | Intake flow + lanes + risk checklist |
| `docs/ARCHITECTURE.md` | `docs/ARCHITECTURE.md` | ✅ | Layering + dependency rules + boundaries |
| `docs/HARNESS.md` | `docs/HARNESS.md` | ✅ | Mental model + spec lifecycle |
| `docs/templates/story.md` | `docs/templates/story.md` | ✅ | Normal story template |
| `docs/templates/decision.md` | `docs/templates/decision.md` | ✅ | ADR template |
| `docs/templates/high-risk-story/*` | `docs/templates/high-risk-story/*` | ✅ | 4 files: overview, design, execplan, validation |
| `docs/templates/spec-intake.md` | `docs/templates/spec-intake.md` | ✅ | Spec intake template |
| `docs/templates/validation-report.md` | `docs/templates/validation-report.md` | ✅ | Validation report template |

### Adapted từ CE (modified cho CHK)

| Concept từ CE | Implementation trong CHK | Changes |
|--------------|-------------------------|---------|
| `AGENTS.md` (task loop) | `AGENTS.md` | + Reference CLAUDE.md, + CHK-specific workflow |
| Source of Truth hierarchy | `AGENTS.md` section | + Thêm CLAUDE.md vào hierarchy |
| Done definition | `AGENTS.md` section | Giữ nguyên CE |

### Tạo mới cho CHK (dựa trên CE concepts)

| File | Purpose | Inspired by CE |
|------|---------|---------------|
| `docs/TEST_MATRIX.md` | Behavior-to-proof tracking | CE's validation expectations |
| `docs/HARNESS_BACKLOG.md` | Harness improvement proposals | CE's harness growth rule |
| `docs/GLOSSARY.md` | Ubiquitous language | CE's product domain modeling |
| `docs/stories/README.md` | Story structure guide | CE's story workflow |
| `docs/decisions/README.md` | ADR guide | CE's decision log |
| `docs/product/README.md` | Product contract guide | CE's living contract concept |

---

## III. FOLDER STRUCTURE SYNC

### Before (CHK original)
```
Claude-Harness-Kit/
├── CLAUDE.md
├── MEMORY.md
├── README.md
├── settings.json
├── harness-init.skill
└── setup-template.sh
```

### After (CHK + CE integrated)
```
Claude-Harness-Kit/
├── AGENTS.md                    ★ NEW (adapted from CE)
├── CLAUDE.md                    (existing)
├── MEMORY.md                    (existing)
├── README.md                    (updated)
├── settings.json                (existing)
├── harness-init.skill           (existing, TODO: update)
├── setup-template.sh            (existing)
│
└── docs/                        ★ NEW folder structure from CE
    ├── HARNESS.md              ★ (from CE)
    ├── FEATURE_INTAKE.md       ★ (from CE)
    ├── ARCHITECTURE.md         ★ (from CE)
    ├── TEST_MATRIX.md          ★ (new, based on CE)
    ├── GLOSSARY.md             ★ (new, based on CE)
    ├── HARNESS_BACKLOG.md      ★ (new, based on CE)
    │
    ├── templates/              ★ (from CE)
    │   ├── story.md
    │   ├── decision.md
    │   ├── spec-intake.md
    │   ├── validation-report.md
    │   └── high-risk-story/
    │       ├── overview.md
    │       ├── design.md
    │       ├── execplan.md
    │       └── validation.md
    │
    ├── product/                ★ (empty, user populates)
    │   └── README.md
    ├── stories/                ★ (empty, user populates)
    │   └── epics/
    │       └── README.md
    └── decisions/              ★ (empty, user populates)
        └── README.md
```

---

## IV. WORKFLOW CHANGES

### Old CHK Workflow (before integration)
```
User → harness-init.skill → CLAUDE.md + settings.json → start coding
```

### New CHK Workflow (after CE integration)
```
User → harness-init.skill → CLAUDE.md + AGENTS.md + docs/ structure
  ↓
Agent reads AGENTS.md → follows Source of Truth
  ↓
User provides spec OR task
  ↓
Agent classifies via FEATURE_INTAKE.md
  ↓
Agent chooses lane: tiny / normal / high-risk
  ↓
Agent executes + updates (product docs, stories, TEST_MATRIX, decisions)
  ↓
Agent updates harness (friction → HARNESS_BACKLOG)
```

---

## V. AGENT OPERATING CHANGES

### Before (CHK original)
- Agent đọc CLAUDE.md (personal config)
- Không có formal task classification
- Không có risk framework
- Story templates không tồn tại

### After (CE integrated)
- Agent đọc **Source of Truth hierarchy** (AGENTS.md)
- Mọi task qua **intake gate** (FEATURE_INTAKE.md)
- Risk checklist: 10 flags + 5 hard gates
- 3 lanes: tiny / normal / high-risk
- Story templates rõ ràng
- Done definition chuẩn

---

## VI. NHỮNG GÌ CHƯA TÍCH HỢP

### Từ CE (chưa copy sang CHK)

1. **Decision examples:**
   - `docs/decisions/0001-harness-first-development.md`
   - `docs/decisions/0002-post-spec-product-lifecycle.md`
   - `docs/decisions/0003-generic-spec-intake-harness.md`
   - **Reason:** Template đã có, examples để user tự tạo

2. **Scripts folder:**
   - `scripts/README.md` (placeholder)
   - **Reason:** CHK đã có `setup-template.sh`, sẽ thêm scripts sau

### Từ CHK (unique, không có trong CE)

1. **harness-init.skill** — auto-generate harness structure
2. **setup-template.sh** — install template globally
3. **CLAUDE-TEMPLATE.md** — personal config template
4. **Setup guides** — Vietnamese docs

---

## VII. ROADMAP TIẾP THEO

### Phase 1: Completed ✅
- Copy 8 files từ CE
- Tạo 6 files mới (TEST_MATRIX, GLOSSARY, HARNESS_BACKLOG, 3 READMEs)
- Adapt AGENTS.md
- Update README.md
- Create INTEGRATION_NOTES.md

### Phase 2: Enhance Tools (Next)
- [ ] Update `harness-init.skill`:
  - Reference FEATURE_INTAKE.md
  - Offer "Use CE harness rules?" (Y/N)
  - Generate docs/ structure
  - Generate AGENTS.md
- [ ] Create `scripts/scaffold-story.sh`:
  - Auto-create story file từ template
  - Usage: `./scripts/scaffold-story.sh "US-001" "User login" normal`
- [ ] Create `scripts/validate-harness.sh`:
  - Check docs consistency
  - Verify links trong stories → product docs
  - Check TEST_MATRIX completeness

### Phase 3: CI/CD & Automation
- [ ] `.github/workflows/harness-check.yml` — CI validation
- [ ] `scripts/generate-test-matrix.sh` — auto-update TEST_MATRIX

### Phase 4: Stack-Specific Templates
- [ ] `docs/stacks/NODEJS_EXPRESS.md`
- [ ] `docs/stacks/PYTHON_FASTAPI.md`
- [ ] `docs/stacks/GO_FIBER.md`

### Phase 5: Domain Guides
- [ ] `docs/API_DESIGN.md`
- [ ] `docs/OBSERVABILITY.md`
- [ ] `docs/SECURITY_POLICY.md`
- [ ] `docs/DATA_MIGRATIONS.md`
- [ ] `docs/INCIDENT_RESPONSE.md`

---

## VIII. MIGRATION GUIDE (For Old Projects)

Nếu bạn đang dùng CHK cũ (trước integration):

```bash
cd your-old-project/

# Backup old structure
mv .claude .claude.backup

# Copy new harness
cp -r ~/Claude-Harness-Kit/.claude ./
cp -r ~/Claude-Harness-Kit/docs ./
cp ~/Claude-Harness-Kit/AGENTS.md ./

# Merge old CLAUDE.md vào new
cat .claude.backup/CLAUDE.md >> CLAUDE.md

# Review changes
git status
```

---

## IX. REFERENCES

- **harness-experimental:** https://github.com/hoangnb24/harness-experimental
- **Claude-Harness-Kit:** https://github.com/hoanglong8/Claude-Harness-Kit
- **Anthropic Docs:** https://docs.anthropic.com/

---

## X. FAQ

**Q: CE vs CHK - nên dùng cái nào?**  
A: Dùng cả hai. CE = rules, CHK = tool. CHK đã integrate CE rules.

**Q: Có bị duplicate không?**  
A: Không. Files từ CE được copy vào CHK/docs/, không conflict với CHK files (CLAUDE.md, settings.json, harness-init.skill).

**Q: Khi nào update từ CE?**  
A: Khi CE release new templates hoặc process changes → manually sync vào CHK/docs/

**Q: CHK có thể hoạt động standalone không?**  
A: Có. CHK bây giờ self-contained với tất cả CE rules được copy vào.

**Q: harness-init.skill có tự động generate docs/ không?**  
A: Chưa (TODO Phase 2). Hiện tại phải manual copy từ CHK template.

---

**✅ Tích hợp hoàn tất. CHK bây giờ là full-featured harness với CE rules embedded.**
