# Agent Operating Guide

Harness này sử dụng framework từ [harness-experimental](https://github.com/hoangnb24/harness-experimental).

Repository này đang ở **Harness v0** — chưa có implementation code, tập trung vào collaboration harness.

Nhiệm vụ hiện tại của agents: **preserve and grow the collaboration harness** trước khi viết application code.

---

## Source of Truth

Đọc theo thứ tự này:

1. **README.md** — trạng thái project hiện tại
2. **CLAUDE.md** — personal config, global rules
3. **docs/HARNESS.md** — human-agent collaboration model (khi có)
4. **docs/FEATURE_INTAKE.md** — trước khi biến prompt thành work
5. **User-provided spec** (khi có) — input material cho buildout đầu tiên
6. **docs/product/** — current product contracts
7. **docs/ARCHITECTURE.md** — trước khi đề xuất implementation shape
8. **docs/stories/** — story packets + backlog
9. **docs/TEST_MATRIX.md** — proof status
10. **docs/decisions/** — why important choices were made

> **Lưu ý:** Harness này không ship với `SPEC.md` baked-in. Khi human cung cấp spec cho project mới:
> - Treat spec là **input material** cho first buildout
> - Derive: product docs, story packets, architecture decisions, validation expectations
> - Product docs + stories + tests + decisions = **living contract** cần update khi system evolves

---

## Task Loop

**Cho mỗi task:**

1. **Classify** request với `docs/FEATURE_INTAKE.md`
2. **Identify** input type:
   - New spec
   - Spec slice
   - Change request
   - New initiative
   - Maintenance request
   - Harness improvement
3. **Locate** affected product docs + story files
4. **Check** `docs/TEST_MATRIX.md` cho existing proof + gaps
5. **Work** trong selected lane: tiny, normal, hoặc high-risk
6. **Before finishing**, hỏi:
   - Product truth có thay đổi?
   - Validation expectations có thay đổi?
   - Architecture rules có thay đổi?
   - Có phát hiện repeated failure pattern?
   - Next agent có cần clearer instruction?
7. **Update** routine harness files trực tiếp, hoặc add proposal vào `docs/HARNESS_BACKLOG.md` nếu change là structural

---

## Harness Change Policy

### Agents có thể update trực tiếp:
- Story status + evidence
- `docs/TEST_MATRIX.md` rows
- Links từ story packets → product docs
- Validation notes + reports
- Small clarifications tied to current task

### Agents phải xin human confirmation trước khi:
- Thay đổi architecture direction
- Remove validation requirements
- Thay đổi source-of-truth hierarchy
- Thay đổi risk classification rules
- Replace feature workflow
- Chạy destructive operations (force-push, reset --hard, delete branches, etc.)

---

## Done Definition

**Task chỉ được coi là done khi:**

1. ✅ Requested change completed HOẶC blocker được document
2. ✅ Relevant docs, stories, test matrix entries vẫn current
3. ✅ Validation commands được run (nếu chúng tồn tại)
4. ✅ Missing harness capabilities được add vào `docs/HARNESS_BACKLOG.md`
5. ✅ Final response nói rõ:
   - What changed
   - What was NOT attempted

---

## Harness Growth Rule

**Harness grows từ friction.**

Khi agent:
- Confused
- Repeats manual reasoning
- Needs new validation command
- Discovers missing rule
- Sees recurring failure pattern

→ **Phải improve harness trực tiếp** HOẶC add proposal vào `docs/HARNESS_BACKLOG.md`

---

## Validation Ladder (Future)

Chưa có validation scripts. Khi implementation bắt đầu, expected ladder:

```bash
validate:quick
  # format, lint, typecheck, unit tests, architecture check

test:integration
  # backend, database, provider, service checks (theo stack)

test:e2e
  # user-visible end-to-end flows

test:platform
  # shell, mobile, desktop, deployment smoke checks (theo stack)

test:release
  # full suite, log checks, performance smoke
```

> **CRITICAL:** Agents không được claim commands này pass cho đến khi chúng exist + đã run.

---

## References

- **harness-experimental:** https://github.com/hoangnb24/harness-experimental
- **FEATURE_INTAKE.md:** Classification rules + risk checklist
- **ARCHITECTURE.md:** Layering + dependency rules + observability contract
- **HARNESS_BACKLOG.md:** Proposed harness improvements
