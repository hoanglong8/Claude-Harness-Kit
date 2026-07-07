---
name: fable-review
description: Pre-delivery self-review checklist enforcing the Fable quality standard (anti-fabrication, verification status, number cross-footing, anti-sycophancy, scope check, FOXAI format compliance). Use this skill BEFORE handing off any significant deliverable — client documents, cost models, code changes, reports, presentations — and whenever the user says "review theo chuẩn Fable", "tự kiểm tra lại", "check trước khi gửi", "rà soát lại", or asks whether the work is ready to deliver. Also use proactively at the end of any multi-step task, even if the user did not explicitly request a review.
---

# Fable Review — Pre-Delivery Checklist

Run every check below against the deliverable. Fix what you can fix; disclose what you cannot. Then produce the report table.

## Checks

**1. Fabrication scan.** Walk through every number, proper noun, citation, legal reference (số Nghị định/Thông tư), API/library/function name, and test result in the deliverable. Each must trace to one of: (a) input data provided by the user, (b) a calculation shown in the work, (c) a source actually read this session, (d) something actually executed this session. Anything untraceable → remove it or mark it "(cần xác minh)".

**2. Verification status.** For every "done / works / passes / đúng" claim: was it executed / opened / checked in this session? Downgrade any unearned status to "Đã viết, chưa chạy" and compile the "**Chưa kiểm chứng:**" list.

**3. Cross-foot the numbers.** For any table or model: recompute row totals, column totals, and every grand total stated in prose — they must reconcile exactly, including across sheets/sections. Do the arithmetic now, do not eyeball it.

**4. Sycophancy scan.** Did the work endorse any user decision, plan, or assumption without testing the counterargument? Generate the strongest objection to the work's main conclusion. Either address it inside the deliverable or surface it explicitly to the user. A deliverable containing only agreement is suspect.

**5. Scope scan.** Two lists: (a) anything delivered that was not asked for → flag or remove; (b) anything asked for that is not delivered → state plainly with reason.

**6. Format compliance.** Vietnamese output; English technical terms preserved; answer-first structure; tables only where comparative; every figure has unit + origin; no filler phrases; government-document formatting (Nghị định 30/2020/NĐ-CP) where applicable.

## Report format

Return this table, followed by the fixes applied:

| # | Check | Kết quả | Ghi chú |
|---|------------------|--------------------|---------|
| 1 | Fabrication | PASS / FAIL | mục nào đã gỡ / đánh dấu |
| 2 | Verification | PASS / PARTIAL | danh sách "Chưa kiểm chứng" |
| 3 | Numbers cross-foot | PASS / FAIL / N-A | chênh lệch nếu có |
| 4 | Sycophancy | PASS / FAIL | phản biện mạnh nhất là gì |
| 5 | Scope | PASS / FAIL | thừa gì / thiếu gì |
| 6 | Format | PASS / FAIL | lỗi định dạng nếu có |

**Nguyên tắc cuối:** a FAIL disclosed honestly is acceptable output. A FAIL hidden behind a confident summary is not.
