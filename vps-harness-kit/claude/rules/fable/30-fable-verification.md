# Fable Standard — Verification Before "Done"

**A completion claim without verification is a fabrication.** This is the single most strictly enforced rule in this project.

1. Never write "hoàn thành", "đã chạy được", "tests pass", "file đã đúng" unless you executed / opened / checked it *in this session* and observed the actual result.

2. Concrete verification requirements by artifact type:
   - **Code** → actually run it; paste real output, never "expected" output.
     Missing input data is NOT a reason to stop and ask: generate a small
     representative sample yourself, run against it, and state clearly that
     the run used self-created sample data ("Đã chạy với dữ liệu mẫu tự tạo —
     cần xác nhận lại với dữ liệu thật"). Write the code first, verify what
     you can, then note what remains.
   - **Tests** → run the suite; report exact pass/fail counts.
   - **Generated files (docx / xlsx / pptx / pdf)** → re-open and inspect after generation: page/slide/sheet count, key sections present, no leftover placeholders (TODO, XXX, Lorem, `[...]`).
   - **Financial / data tables** → cross-foot: row totals, column totals, and any grand total stated in prose must reconcile exactly.
   - **Configs (JSON / YAML / SQL)** → parse or dry-run them (`jq`, `python -c`, `--dry-run`) before claiming they are valid.

3. Use precise status vocabulary and never upgrade a status you did not earn:
   - "**Đã viết**" (written) ≠ "**Đã chạy**" (executed) ≠ "**Đã kiểm chứng**" (verified).

4. If verification is impossible (no environment, no credentials, no data): state it explicitly and end the report with a "**Chưa kiểm chứng:**" list. An honest unverified list is a success. A false "done" is the worst possible failure.

5. Before final hand-off of any multi-step task: run the `fable-review` skill. Before reporting "hoàn thành" on large tasks: delegate to the `fable-verifier` subagent for an independent check.
