# Changelog: Integration harness-experimental

**Date:** 2026-05-08  
**Version:** Harness v0 → v1 (enriched with CE framework)

---

## 🎯 Summary

Tích hợp framework từ [harness-experimental](https://github.com/hoangnb24/harness-experimental) vào Claude-Harness-Kit để tạo ra một **full-featured collaboration harness** cho human-agent software development.

**Kết quả:** 
- 15 files mới được tạo
- 1 file được update (README.md)
- Harness bây giờ self-contained với tất cả CE rules

---

## 📦 Files Added

### Core Harness (1 file)
- ✅ `AGENTS.md` — Agent Operating Guide (adapted from CE)

### Documentation Structure (6 files)
- ✅ `docs/HARNESS.md` — Collaboration model (from CE)
- ✅ `docs/FEATURE_INTAKE.md` — Classification & risk framework (from CE)
- ✅ `docs/ARCHITECTURE.md` — Layering rules (from CE)
- ✅ `docs/TEST_MATRIX.md` — Behavior-to-proof tracking (new)
- ✅ `docs/GLOSSARY.md` — Ubiquitous language (new)
- ✅ `docs/HARNESS_BACKLOG.md` — Harness improvement proposals (new)

### Templates (8 files)
- ✅ `docs/templates/story.md` (from CE)
- ✅ `docs/templates/decision.md` (from CE)
- ✅ `docs/templates/spec-intake.md` (from CE)
- ✅ `docs/templates/validation-report.md` (from CE)
- ✅ `docs/templates/high-risk-story/overview.md` (from CE)
- ✅ `docs/templates/high-risk-story/design.md` (from CE)
- ✅ `docs/templates/high-risk-story/execplan.md` (from CE)
- ✅ `docs/templates/high-risk-story/validation.md` (from CE)

### Guide Files (3 files)
- ✅ `docs/product/README.md` — Product contract guide
- ✅ `docs/stories/README.md` — Story structure guide
- ✅ `docs/decisions/README.md` — ADR guide

### Integration Docs (1 file)
- ✅ `INTEGRATION_NOTES.md` — How CE integrated into CHK

---

## 📝 Files Updated

- ✅ `README.md`:
  - Updated folder structure section
  - Added "Harness Workflow" section
  - Added "Architecture Rules" section
  - Added "Harness Growth" section
  - Added reference to harness-experimental

---

## 🏗️ New Folder Structure

```
Claude-Harness-Kit/
├── AGENTS.md                    ★ NEW
├── INTEGRATION_NOTES.md         ★ NEW
├── CLAUDE.md
├── MEMORY.md
├── README.md                    ★ UPDATED
├── settings.json
├── harness-init.skill
│
└── docs/                        ★ NEW entire folder
    ├── HARNESS.md
    ├── FEATURE_INTAKE.md
    ├── ARCHITECTURE.md
    ├── TEST_MATRIX.md
    ├── GLOSSARY.md
    ├── HARNESS_BACKLOG.md
    │
    ├── templates/
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
    ├── product/
    │   └── README.md
    ├── stories/
    │   ├── README.md
    │   └── epics/
    └── decisions/
        └── README.md
```

---

## ✨ Key Features Added

### 1. Feature Intake Process
- Classification: 6 input types
- Risk framework: 10 flags + 5 hard gates
- 3 lanes: tiny / normal / high-risk

### 2. Story Templates
- Normal story: single-file format
- High-risk story: 4-file packet (overview, design, execplan, validation)

### 3. Architecture Rules
- Default layering (domain → application → infrastructure → interface)
- Dependency rule (inner ≠ depend outer)
- Parse-first boundary rule
- Observability contract

### 4. Source of Truth Hierarchy
1. README.md
2. AGENTS.md
3. docs/FEATURE_INTAKE.md
4. User-provided spec
5. docs/product/
6. docs/ARCHITECTURE.md
7. docs/stories/
8. docs/TEST_MATRIX.md
9. docs/decisions/

### 5. Harness Growth Rule
"Harness grows from friction" → update docs or add to HARNESS_BACKLOG.md

---

## 🔄 Workflow Changes

### Before
```
User → harness-init → CLAUDE.md → code
```

### After
```
User → harness-init → CLAUDE.md + AGENTS.md + docs/
  ↓
Agent follows Source of Truth
  ↓
Task → FEATURE_INTAKE.md → classify risk → choose lane
  ↓
Execute → update (product docs, stories, TEST_MATRIX, decisions)
  ↓
Update harness (friction → HARNESS_BACKLOG)
```

---

## 🚀 Next Steps (Roadmap)

### Phase 2: Enhance Tools
- [ ] Update `harness-init.skill` to auto-generate docs/
- [ ] Create `scripts/scaffold-story.sh`
- [ ] Create `scripts/validate-harness.sh`

### Phase 3: CI/CD
- [ ] `.github/workflows/harness-check.yml`
- [ ] `scripts/generate-test-matrix.sh`

### Phase 4: Stack Templates
- [ ] `docs/stacks/NODEJS_EXPRESS.md`
- [ ] `docs/stacks/PYTHON_FASTAPI.md`
- [ ] `docs/stacks/GO_FIBER.md`

### Phase 5: Domain Guides
- [ ] `docs/API_DESIGN.md`
- [ ] `docs/OBSERVABILITY.md`
- [ ] `docs/SECURITY_POLICY.md`

---

## 📚 References

- **harness-experimental:** https://github.com/hoangnb24/harness-experimental
- **INTEGRATION_NOTES.md:** Chi tiết về integration process
- **AGENTS.md:** Agent operating instructions
- **docs/FEATURE_INTAKE.md:** Risk classification framework

---

## ✅ Verification

Run these to verify integration:

```bash
# Check folder structure
ls -la docs/

# Check templates
ls -la docs/templates/
ls -la docs/templates/high-risk-story/

# Read key docs
cat AGENTS.md
cat docs/FEATURE_INTAKE.md
cat docs/ARCHITECTURE.md
```

---

**Status:** ✅ Integration complete. CHK is now a full-featured harness with CE framework embedded.
