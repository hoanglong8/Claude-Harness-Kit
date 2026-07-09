# GitHub Actions Workflows

Automation workflows for Claude-Harness-Kit CI/CD pipeline.

---

## Available Workflows

### 1. harness-check.yml

**Purpose:** Validate harness consistency and completeness on every PR and push

**Trigger Events:**
- `pull_request` — On PRs to main/develop branches
- `push` — On commits to main branch
- `workflow_dispatch` — Manual trigger via GitHub UI

**Paths Trigger:**
Only runs when these paths are modified:
```
docs/**
scripts/**
AGENTS.md
CLAUDE.md
.github/workflows/harness-check.yml
```

**Checks Performed:**
1. ✅ Harness exists (AGENTS.md, docs/, CLAUDE.md)
2. ✅ Core documentation files (6 required docs)
3. ✅ Templates structure (8 templates)
4. ✅ Folder structure & README files
5. ✅ Story file naming convention
6. ✅ TEST_MATRIX.md content validation
7. ✅ AGENTS.md & CLAUDE.md presence
8. ✅ Git status check
9. ✅ Story files inventory (regular + high-risk)

**Output:**
- ✅ GitHub Actions summary report
- ⚠️ Warnings for issues (non-blocking)
- ❌ Errors for failures (blocking)
- 📊 Story count and TEST_MATRIX stats

**Exit Codes:**
- `0` — All checks passed or warnings only
- `1` — Critical validation failed

---

## Usage

### Manual Trigger

```bash
# Via GitHub CLI
gh workflow run harness-check.yml

# Via GitHub UI
1. Go to Actions tab
2. Select "Harness Validation"
3. Click "Run workflow" → Choose branch
```

### Monitor Workflow

```bash
# Watch workflow status
gh workflow view harness-check.yml --log

# List recent runs
gh run list --workflow harness-check.yml --limit 10

# View specific run details
gh run view <RUN_ID>
```

### Debugging Failed Workflow

If workflow fails:

1. **Check workflow logs** in GitHub UI or:
   ```bash
   gh run view <RUN_ID> --log
   ```

2. **Reproduce locally**:
   ```bash
   bash scripts/validate-harness.sh
   ```

3. **Fix issues**:
   - Use `--fix` flag for auto-corrections:
     ```bash
     bash scripts/validate-harness.sh --fix
     ```
   - Commit fixes and push again

---

## Integration with Development

### Before Pushing

```bash
# Run harness check locally
bash scripts/validate-harness.sh

# If issues found, auto-fix
bash scripts/validate-harness.sh --fix

# Commit and push
git add docs/
git commit -m "chore: fix harness issues"
git push origin feature-branch
```

### PR Review

GitHub Actions will automatically:
1. Run harness validation
2. Report status as check
3. Block merge if critical issues found
4. Add summary to PR details

---

## Configuration

Workflow is configured in `.github/workflows/harness-check.yml`.

### To Modify Trigger Paths

Edit the `on.pull_request.paths` and `on.push.paths` sections:

```yaml
on:
  pull_request:
    paths:
      - 'docs/**'              # Changed files in docs/
      - 'scripts/**'           # Changed files in scripts/
      - 'AGENTS.md'            # Harness documents
      - 'CLAUDE.md'
      - '.github/workflows/harness-check.yml'  # This file itself
```

### To Add More Checks

Add new steps in the `harness-validation` job:

```yaml
- name: Your new check
  if: steps.harness_check.outputs.is_harness == 'true'
  run: |
    # Your validation command
    bash scripts/your-check.sh
```

---

## Benefits

1. **Automated Validation** — No manual harness checks needed
2. **Early Detection** — Catch issues before merge
3. **Consistency** — Same rules for all contributors
4. **Audit Trail** — All validations logged in GitHub
5. **Non-Breaking** — Warnings don't block, errors do

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Workflow not triggering | Check paths—if changed files don't match paths filter, workflow won't run |
| Validation always fails | Run `scripts/validate-harness.sh` locally to debug |
| False positives | Check git status; uncommitted changes may cause issues |
| Need to skip check | Use `skip-ci` in commit message (GitHub default) |

---

## References

- **Harness Validator:** `scripts/validate-harness.sh`
- **Workflow Syntax:** [GitHub Actions Documentation](https://docs.github.com/en/actions)
- **Status Checks:** PR branch protection settings

---

**Status:** ✅ Complete (Phase 3, Task #13)

