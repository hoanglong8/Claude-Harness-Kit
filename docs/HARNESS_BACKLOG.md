# Harness Backlog

Proposed improvements cho harness infrastructure.

## Format

```markdown
### [Proposal Title]
- **Status:** proposed | in-progress | done | declined
- **Reason:** Why this harness change is needed
- **Impact:** What changes when this is done
- **Effort:** Estimate (tiny, normal, high)
```

---

## Proposals

_(Empty - agents add proposals khi phát hiện friction)_

---

**Examples:**

### Add `scripts/scaffold-story.sh`
- **Status:** proposed
- **Reason:** Manual story creation is repetitive, agents keep regenerating template
- **Impact:** One command creates story file from template
- **Effort:** tiny (1 bash script)

### Add CI harness validation
- **Status:** proposed
- **Reason:** Docs drift out of sync, no automated check
- **Impact:** `.github/workflows/harness-check.yml` validates docs consistency
- **Effort:** normal (workflow + validation script)
