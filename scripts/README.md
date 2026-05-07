# Scripts

Automation scripts for Harness Engineering workflow.

---

## Available Scripts

### 1. scaffold-story.sh

**Purpose:** Auto-create story files from templates

**Usage:**
```bash
./scripts/scaffold-story.sh STORY-ID "Story Title" [lane]
```

**Arguments:**
- `STORY-ID` — Story identifier (e.g., STORY-001, US-042)
- `Story Title` — Human-readable title (use quotes)
- `lane` — tiny | normal | high-risk (default: normal)

**Examples:**
```bash
# Normal story (2-3 risk flags)
./scripts/scaffold-story.sh "STORY-001" "User login" normal

# High-risk story (4+ flags or hard gate)
./scripts/scaffold-story.sh "STORY-002" "Payment integration" high-risk

# Tiny story (0-1 flags, no file created)
./scripts/scaffold-story.sh "STORY-003" "Fix typo" tiny
```

**Output:**
- **tiny:** No file (reminder message only)
- **normal:** `docs/stories/STORY-ID-title.md`
- **high-risk:** `docs/stories/STORY-ID-title/` (4 files: overview, design, execplan, validation)

**Prerequisites:**
- `docs/templates/` folder must exist
- Run from project root

---

### 2. validate-harness.sh

**Purpose:** Check harness consistency and completeness

**Usage:**
```bash
./scripts/validate-harness.sh [OPTIONS]
```

**Options:**
- `--fix` — Auto-fix issues where possible
- `--strict` — Fail on warnings (not just errors)
- `-h, --help` — Show help message

**Checks performed:**
1. Core docs exist (HARNESS, FEATURE_INTAKE, ARCHITECTURE, etc.)
2. All templates present (story, decision, high-risk-story/)
3. Required folders exist (product/, stories/, decisions/, scripts/)
4. README files in key folders
5. Story file naming convention (STORY-001-title format)
6. TEST_MATRIX.md has content
7. AGENTS.md has required sections
8. CLAUDE.md has tech stack info
9. Git status (bonus check)

**Output:**
```
✅ All checks passed! Harness is healthy.

OR

⚠️  Harness has 3 issue(s) but no failures.

Recommendations:
  1. Review warnings above
  2. Run with --fix to auto-correct
  3. Run with --strict to fail on warnings
```

**Examples:**
```bash
# Run validation
./scripts/validate-harness.sh

# Auto-fix issues
./scripts/validate-harness.sh --fix

# Strict mode (fail on warnings)
./scripts/validate-harness.sh --strict
```

**Status:** ✅ Complete (Task #12)

---

## Common Workflows

### Create a new story

```bash
# 1. Classify work via FEATURE_INTAKE.md
#    → Identify risk flags
#    → Choose lane

# 2. Run scaffold script
./scripts/scaffold-story.sh "STORY-042" "Add OAuth provider" normal

# 3. Edit generated file
vim docs/stories/STORY-042-add-oauth-provider.md

# 4. Execute story
#    → Implement feature
#    → Update product docs
#    → Update TEST_MATRIX.md

# 5. Validate harness (when available)
./scripts/validate-harness.sh

# 6. Commit
git add docs/
git commit -m "feat(STORY-042): add OAuth provider"
```

### Create a high-risk story

```bash
# 1. Trigger: 4+ risk flags or hard gate detected

# 2. Run scaffold script
./scripts/scaffold-story.sh "STORY-099" "Migrate to new auth system" high-risk

# 3. Fill in 4-file packet
cd docs/stories/STORY-099-migrate-to-new-auth-system/
vim overview.md   # Problem, impact, constraints
vim design.md     # Architecture, data model, API, security
vim execplan.md   # Phases, rollback, deployment
vim validation.md # Test strategy, proof, acceptance

# 4. Review with team

# 5. Execute phases incrementally

# 6. Create decision record
cp docs/templates/decision.md docs/decisions/0042-new-auth-system.md
vim docs/decisions/0042-new-auth-system.md

# 7. Validate and commit
./scripts/validate-harness.sh
git add docs/
git commit -m "feat(STORY-099): migrate to new auth system (phase 1)"
```

---

## Script Development

### Adding a new script

1. Create script file: `scripts/my-script.sh`
2. Add shebang: `#!/usr/bin/env bash`
3. Set executable: `chmod +x scripts/my-script.sh`
4. Add usage function with examples
5. Add to this README
6. Test in clean project
7. Commit with message: `feat(scripts): add my-script.sh`

### Script conventions

- **Bash compatibility:** Use `#!/usr/bin/env bash`, not `#!/bin/bash`
- **Error handling:** Use `set -euo pipefail` at top
- **Colors:** Use predefined color vars (GREEN, BLUE, YELLOW, RED, NC)
- **Logging:** Use log_info, log_success, log_warning, log_error functions
- **Validation:** Check prerequisites before running (folders exist, templates exist)
- **Dry-run:** Support `--dry-run` flag where applicable
- **Help:** Show usage when `-h` or `--help` passed

---

## Testing

### Test scaffold-story.sh

```bash
# Setup test project
mkdir -p /tmp/test-harness && cd /tmp/test-harness
git init
mkdir -p docs/{templates,stories,product,decisions}

# Copy templates (mock)
echo "# [STORY-ID] Story Title" > docs/templates/story.md
mkdir -p docs/templates/high-risk-story
echo "# [STORY-ID] Overview" > docs/templates/high-risk-story/overview.md
echo "# [STORY-ID] Design" > docs/templates/high-risk-story/design.md
echo "# [STORY-ID] Execution Plan" > docs/templates/high-risk-story/execplan.md
echo "# [STORY-ID] Validation" > docs/templates/high-risk-story/validation.md

# Test normal lane
~/Claude-Harness-Kit/scripts/scaffold-story.sh "TEST-001" "Test feature" normal
# Verify: docs/stories/TEST-001-test-feature.md exists

# Test high-risk lane
~/Claude-Harness-Kit/scripts/scaffold-story.sh "TEST-002" "Test high risk" high-risk
# Verify: docs/stories/TEST-002-test-high-risk/ folder with 4 files

# Test tiny lane
~/Claude-Harness-Kit/scripts/scaffold-story.sh "TEST-003" "Test tiny" tiny
# Verify: No file created, reminder shown

# Cleanup
cd ~ && rm -rf /tmp/test-harness
```

---

## Troubleshooting

**"docs/ folder not found"**
→ Run script from project root where docs/ exists

**"docs/templates/ not found"**
→ Initialize CE framework first: `/harness-init` with CE option

**"Story file already exists"**
→ Use a different story ID or delete existing file

**"Permission denied"**
→ Make script executable: `chmod +x scripts/scaffold-story.sh`

---

## References

- **FEATURE_INTAKE.md** — Risk classification framework
- **Story templates** — `docs/templates/story.md`, `docs/templates/high-risk-story/`
- **AGENTS.md** — Task loop workflow

---

**Status:** 🚧 Work in progress — scaffold-story.sh complete, validate-harness.sh coming soon
