---
name: fable-review
description: >-
  Pre-handoff self-review checklist theo chuẩn Fable. Chạy TRƯỚC khi bàn
  giao bất kỳ sản phẩm quan trọng nào — tài liệu, code, cost model, slide
  deck, báo cáo. Kiểm tra scope, claims, status vocabulary, số liệu,
  assumptions, sycophancy và format FOXAI. Invoke when the user says
  "review trước khi gửi", "check lại giúp", or before delivering any
  significant product.
---

# Fable Review — Checklist tự kiểm trước bàn giao

Run through every item against the deliverable. For each: fix it, or
disclose it explicitly in the handoff report. Do not skip items.

## Checklist

1. **Scope** — Does the deliverable match exactly what was asked? Any
   extras or out-of-scope discoveries moved to "Phát hiện thêm:"?
2. **Claims** — Is every factual claim backed by one of: verified this
   session / cited source / explicit uncertainty marker per
   `10-fable-honesty.md` ("Tôi chắc chắn vì đã kiểm tra/chạy…" /
   "Tôi cho là vậy nhưng chưa kiểm chứng…" / "Tôi không biết…")? Any legal
   citation, price, benchmark, or API name stated from memory → remove or
   verify now.
3. **Status vocabulary** — Every component labeled correctly as
   "đã viết" / "đã chạy" / "đã kiểm chứng"? Nothing reported higher than
   achieved? "Chưa kiểm chứng:" section present (or "không có")?
4. **Numbers** — Every number has a unit and a source; money has currency;
   estimates labeled "ước tính"?
5. **Assumptions** — All labeled with "Giả định:"? Any silent assumption
   found now → label it or resolve it.
6. **Sycophancy check** — Any praise not earned by evidence, any softened
   finding, any "tuy nhiên" sandwich? Remove; state findings plainly.
7. **Format** — Tiếng Việt, thuật ngữ Anh giữ nguyên; outcome in the first
   sentence; complete sentences; everything the reader needs in one place?
8. **Escalation** — Deliverable goes to a client or leadership → call the
   **fable-critic** subagent for an independent red-team pass before
   sending. Multi-step task being declared complete → call
   **fable-verifier**.

## Output format

First a short review table — one row per item, verdict **ĐẠT** or **SỬA**
with a one-line reason — then the corrected deliverable. If any item is
SỬA and cannot be fixed now, it must appear in the handoff report under
"Chưa kiểm chứng:" or "Giả định:".
