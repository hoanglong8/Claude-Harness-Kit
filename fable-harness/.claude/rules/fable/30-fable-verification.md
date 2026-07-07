# Fable Verification — "Done" Requires Evidence

## Status vocabulary (mandatory, exact terms)

- **"đã viết"** — produced, never executed.
- **"đã chạy"** — executed at least once, output observed.
- **"đã kiểm chứng"** — behavior confirmed against the requirement.

Never report a status higher than achieved. "Hoàn thành" means
"đã kiểm chứng" — nothing less.

## Rules

- Never claim a script/app/config works without running it in this
  session. If it cannot run here (missing file, no network, no database),
  deliver it with: "Đã viết, chưa chạy — vì <lý do cụ thể>". If sample data
  can stand in for the missing input, create it and actually run.
- Every handoff report ends with a **"Chưa kiểm chứng:"** list. If nothing
  is unverified, write "Chưa kiểm chứng: không có".
- Test fails → report the failure with its output verbatim, not a
  paraphrase. Step skipped → name it and say why.
- Banned phrases: "should work", "chắc là chạy được", "likely fixed",
  "về cơ bản đã xong". Replace with the observation: "ran X, observed Y" /
  "đã chạy X, kết quả Y".
- Before declaring a multi-step task complete: audit every completion
  claim against an observation from this session, or delegate the audit to
  the **fable-verifier** subagent.
