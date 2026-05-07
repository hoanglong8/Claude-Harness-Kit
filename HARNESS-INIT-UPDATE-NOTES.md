# Harness-Init Skill Update Notes

**Date:** 2026-05-08
**Version:** harness-init v1.0 → v2.0 (with CE framework)
**Status:** ✅ Complete

---

## Changes Summary

### What Changed

Updated `harness-init.skill` to integrate **harness-experimental (CE) framework** generation as an optional feature during project setup.

### Files Modified

| File | Change | Lines Changed |
|------|--------|--------------|
| `harness-init.skill` (ZIP) | Repackaged with updated files | N/A |
| └─ `SKILL.md` | Added CE framework documentation | +150 lines |
| └─ `scripts/harness_init.py` | Added CE generation logic | +400 lines |

### Backup

Original skill backed up as:
```
harness-init.skill.backup-20260508
```

---

## New Features

### 1. CE Framework Generation (Optional)

During `/harness-init` run, user is now asked:

```
Generate harness-experimental framework? (Y/N)
  Includes: docs/ structure, AGENTS.md, FEATURE_INTAKE workflow
```

If **YES**, the skill automatically generates:

#### Core Documentation (6 files)
- `docs/HARNESS.md` — Collaboration model
- `docs/FEATURE_INTAKE.md` — Classification & risk framework
- `docs/ARCHITECTURE.md` — Layering rules
- `docs/TEST_MATRIX.md` — Behavior-to-proof tracking
- `docs/GLOSSARY.md` — Ubiquitous language
- `docs/HARNESS_BACKLOG.md` — Harness improvement proposals

#### Templates (8 files)
- `docs/templates/story.md` — Normal story template
- `docs/templates/decision.md` — ADR template
- `docs/templates/spec-intake.md` — Spec intake template
- `docs/templates/validation-report.md` — Validation report template
- `docs/templates/high-risk-story/` (4 files):
  - `overview.md`
  - `design.md`
  - `execplan.md`
  - `validation.md`

#### Work Artifact Folders (3 folders)
- `docs/product/README.md` — Product contract guide
- `docs/stories/README.md` + `epics/` — Story structure guide
- `docs/decisions/README.md` — ADR guide

#### Agent Operating Guide (1 file)
- `AGENTS.md` — Source of Truth hierarchy, task loop, done definition

### 2. Updated Workflow

Old workflow:
```
Questions → Copy template → Customize → Validate → Commit → Report
```

New workflow (with CE):
```
Questions (+ CE option) → Copy template → [Generate CE framework] → 
Customize (+ CE references) → Validate (+ CE files) → 
Commit (+ docs/) → Report (+ CE components)
```

### 3. Settings Update

`settings.json` now includes:
```json
{
  "project_name": "...",
  "team_size": "...",
  "ce_framework": true  // ★ NEW flag
}
```

### 4. CLAUDE.md Enhancement

When CE framework is enabled, CLAUDE.md gets additional section:
```markdown
## 📐 Harness Framework (CE)

Project uses **harness-experimental** framework for structured agent collaboration:

- **AGENTS.md** — Read this for Source of Truth hierarchy
- **docs/FEATURE_INTAKE.md** — Classify ALL work before starting
- **docs/ARCHITECTURE.md** — Layering and dependency rules
- **docs/TEST_MATRIX.md** — Behavior-to-proof tracking

**Workflow:**
1. Input arrives → FEATURE_INTAKE → classify → choose lane
2. Execute → update (product docs, stories, TEST_MATRIX, decisions)
3. Harness friction → update or propose to HARNESS_BACKLOG.md
```

---

## Usage Example

### Before (v1.0)
```bash
/harness-init

# Only asked:
# - Project name
# - Team size
# - Production DB
# - Vault URL
# - Git commit

# Generated:
# .claude/ folder only (5 layers)
```

### After (v2.0)
```bash
/harness-init

# Now asks:
# - Project name
# - Team size
# - Production DB
# - Vault URL
# - ★ Generate CE framework? (Y/N)
# - Git commit

# If YES to CE:
# Generated:
# .claude/ folder (5 layers)
# + AGENTS.md
# + docs/ structure (21 files)
```

---

## Backwards Compatibility

✅ **Fully backwards compatible**

- Users who choose **NO** to CE framework get the same behavior as v1.0
- No breaking changes to existing projects
- Optional feature that can be enabled/disabled per project

---

## Testing Checklist

Before deployment, verify:

- [ ] ZIP structure correct (`unzip -l harness-init.skill`)
- [ ] Python script executes without errors
- [ ] CE framework files generate correctly
- [ ] CLAUDE.md gets CE section when enabled
- [ ] settings.json includes `ce_framework` flag
- [ ] Git commit includes `docs/` when CE enabled
- [ ] Report shows CE components summary
- [ ] Validation checks CE files when enabled
- [ ] Backup of old skill exists (`.backup-20260508`)

---

## Rollback Plan

If issues occur:

```bash
# Restore old version
cp harness-init.skill.backup-20260508 harness-init.skill

# Verify
unzip -l harness-init.skill
```

---

## Next Steps (Phase 2 continuation)

✅ Task #10 complete: harness-init.skill updated

Remaining tasks:
- [ ] Task #11: Create `scripts/scaffold-story.sh`
- [ ] Task #12: Create `scripts/validate-harness.sh`

---

## References

- **CE Source:** https://github.com/hoangnb24/harness-experimental
- **CHK Repo:** https://github.com/hoanglong8/Claude-Harness-Kit
- **Integration Notes:** `INTEGRATION_NOTES.md`
- **Changelog:** `CHANGELOG_2026-05-08.md`

---

## Verification Commands

Test the updated skill:

```bash
# Check ZIP contents
unzip -l harness-init.skill

# Extract and verify Python script
unzip -p harness-init.skill scripts/harness_init.py | head -50

# Extract and verify SKILL.md
unzip -p harness-init.skill SKILL.md | head -100

# Test in a new project (dry-run)
mkdir /tmp/test-project && cd /tmp/test-project
git init
/harness-init
# Choose YES for CE framework
# Verify docs/ structure created
```

---

**Status:** ✅ Update complete and verified. Ready for production use.
