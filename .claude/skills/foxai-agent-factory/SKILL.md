---
name: foxai-agent-factory
description: >
  Quy trình FOXAI tạo hệ agentic AI (multi-agent) chuyên biệt cho một lĩnh vực, chạy trong
  Claude Code. Trigger khi user nói: "tạo agentic AI", "xây multi-agent cho [lĩnh vực]",
  "agent factory", "thiết kế hệ agent", "tạo đội agent cho dự án", "dựng AI chuyên biệt cho
  khách hàng X". Đi qua 5 giai đoạn: tiếp nhận yêu cầu → phân tích → blueprint (CỔNG DUYỆT)
  → build → test trong Claude Code. Hỗ trợ ràng buộc model: chỉ Anthropic (opus/sonnet/haiku)
  hoặc hybrid có Codex/GPT. KHÔNG build bất kỳ artifact nào trước khi user duyệt blueprint.
---

# foxai-agent-factory v1 — Nhà máy tạo hệ Multi-Agent chuyên biệt

Sản phẩm đầu ra của một lần chạy factory: bộ artifact hoàn chỉnh cài vào project đích —
agents (`.claude/agents/*.md`), workflow điều phối (`.claude/workflows/*.js`), skill điều
hành quy trình (`.claude/skills/<domain>/SKILL.md`), section CLAUDE.md, bộ EVAL canary
riêng cho hệ, và biên bản test có bằng chứng. Nền tảng kỷ luật: fable-harness (bắt buộc cài
vào project đích nếu chưa có — `bash fable-harness/INSTALL.sh <project>`).

## QUY TRÌNH 5 GIAI ĐOẠN (bắt buộc theo thứ tự)

### GĐ1 — TIẾP NHẬN YÊU CẦU (intake chuyên cho hệ agent)

Hỏi một lượt duy nhất, 8 mục (bỏ qua mục nào hội thoại đã trả lời — nêu lại thành giả định):
1. **Lĩnh vực & bài toán:** hệ agent giải quyết việc gì, cho ai (kế toán đối soát? pre-sale thầu? vận hành DC?)
2. **Đầu vào / đầu ra:** dữ liệu nhận vào dạng gì, sản phẩm cuối là gì (file, báo cáo, quyết định, hành động)
3. **Công cụ & dữ liệu:** cần đọc/ghi hệ thống nào (file, DB, MCP server nào, API nào)
4. **Ràng buộc model:** chỉ Anthropic (opus/sonnet/haiku)? có Fable? hay hybrid Codex/GPT? (xem templates/model-mapping.md)
5. **Ngân sách:** token/chi phí mỗi lần chạy chấp nhận được; tần suất chạy
6. **Người vận hành:** ai dùng hằng ngày (kỹ sư? BA? user cuối không biết code?) — quyết định mức tự động hóa
7. **Tiêu chí thành công ĐO ĐƯỢC:** làm sao biết hệ chạy đúng (con số, không cảm tính) — sẽ thành bộ EVAL ở GĐ5
8. **Rủi ro cấm phạm:** hành động nào hệ tuyệt đối không được tự làm (gửi mail? sửa DB? thanh toán?)

### GĐ2 — PHÂN TÍCH & CHỌN KIẾN TRÚC

1. Phân rã bài toán thành **jobs** → gom thành **roles** (mỗi role = 1 agent tiềm năng).
2. Chọn pattern (chọn cái RẺ nhất đủ dùng — không multi-agent hóa việc 1 agent làm được):

| Pattern | Khi nào | Ví dụ đã kiểm chứng trong kit |
|---|---|---|
| **Solo + skill** | 1 luồng việc, ít bước, cần rẻ | foxai-book-writer GĐ1-3 |
| **Pipeline writer→verifier** | Nhiều đơn vị việc độc lập, cần kiểm từng cái | workflow `book-production` |
| **Orchestrator + workers** | Việc phân nhánh theo loại, cần điều phối động | COORDINATOR pattern |
| **Judge panel** | Quyết định khó, cần nhiều góc nhìn độc lập | workflow `agent-factory` mode=design |
| **Adversarial verify** | Kết luận rủi ro cao, cần phản biện | fable-critic + EVAL canary |

3. Map model theo role bằng `templates/model-mapping.md` (tier Anthropic; role non-Claude → bước gọi tool, KHÔNG phải agent .md).
4. Hệ phức tạp (>3 roles hoặc kiến trúc chưa rõ): chạy workflow **`agent-factory` mode=design** —
   3 kiến trúc sư độc lập (góc nhìn: chi phí tối giản / độ tin cậy / tốc độ song song) + 1 judge chấm và tổng hợp.

### GĐ3 — BLUEPRINT → CỔNG DUYỆT CỨNG

Điền `templates/agent-blueprint.md` thành `agent-blueprint-<domain>.md`: bảng agents (vai, tools
tối thiểu, model, hành vi cấm), sơ đồ orchestration, ma trận model, bộ EVAL dự kiến, ước tính
chi phí/lần chạy, rủi ro. **DỪNG chờ user duyệt.** "Cứ làm luôn" → tự duyệt + khối "Giả định:".

### GĐ4 — BUILD (thực thi chi tiết)

Sinh từng artifact theo `templates/agent-spec.md` — chuẩn bắt buộc mỗi agent:
- Frontmatter đúng schema Claude Code (name/description có "Use PROACTIVELY khi.../Dùng khi..."/tools tối thiểu/model)
- Thân nhúng kỷ luật Fable: trạng thái trung thực (Đã viết≠Đã chạy≠Đã kiểm chứng), zero fabrication,
  UNVERIFIABLE thay vì đoán, escalation về parent thay vì tự nâng model, brief bắt buộc đủ 3 phần
  (artifact ở đâu / yêu cầu gốc / định nghĩa done)
- Workflow .js theo pattern đã kiểm chứng: **file LF không CRLF** (permission layer chặn), parse args
  phòng thủ (string hoặc object), structured output schema, pipeline() mặc định, guard chặn chạy trước cổng duyệt
- Nhiều component (>4 file): chạy workflow **`agent-factory` mode=build** — mỗi component 1 builder
  trả về content (KHÔNG tự ghi file) + 1 reviewer đối chiếu spec; main loop ghi file sau khi review pass.
- Cài fable-harness vào project đích nếu chưa có; ghép section CLAUDE.md của hệ vào CLAUDE.md project.

### GĐ5 — TEST TRONG CLAUDE CODE (3 lớp, đều phải có bằng chứng)

1. **Smoke test workflow:** chạy hệ với 1 case mini THẬT (như book-production đã smoke 1 chương) —
   bằng chứng: kết quả trả về đúng schema, agents_error=0.
2. **EVAL canary domain:** lập bộ ≥5 prompt ĐẠT/TRƯỢT theo `templates/domain-eval.md` (phương pháp
   y hệt fable-harness EVAL: headless `claude -p`, chấm bằng artifact, chuẩn ≥2/3 lần); mục 7 của
   intake (tiêu chí đo được) chính là nguồn viết canary.
3. **Nghiệm thu blueprint:** gọi agent **`foxai-factory-verifier`** đối chiếu hệ đã build với
   blueprint — file đủ, frontmatter hợp lệ, LF, guard có, EVAL có, smoke test có bằng chứng.
Chỉ báo "hoàn thành" khi cả 3 lớp PASS hoặc FAIL được user chấp nhận rõ ràng (rule 30).

## Templates & thành phần

| File | Dùng cho |
|---|---|
| `templates/agent-blueprint.md` | GĐ3 — bản thiết kế chờ duyệt |
| `templates/agent-spec.md` | GĐ4 — khuôn viết 1 file agent .md chuẩn Fable |
| `templates/model-mapping.md` | GĐ2/3 — chọn model, kể cả ràng buộc non-Anthropic |
| `templates/domain-eval.md` | GĐ5 — phương pháp viết + chạy bộ canary cho hệ mới |
| `~/.claude/workflows/agent-factory.js` | mode=design (judge panel) / mode=build (builder+reviewer) |
| `~/.claude/agents/foxai-factory-verifier.md` | GĐ5 lớp 3 — nghiệm thu độc lập |

## Lưu ý chi phí & giới hạn (nói thẳng với user trước khi chạy)
- mode=design ≈ 4 agents (~120–200k token); mode=build ≈ 2×số component; EVAL ≈ số canary × 3 phiên.
- Factory chuyển giao QUY TRÌNH + KỶ LUẬT, không nâng trần model: hệ chạy Haiku sẽ giữ nề nếp
  nhưng phán đoán vẫn là Haiku — map đúng tier theo độ khó của role (model-mapping).
- Claude Code agent .md chỉ chạy model Claude — role cần GPT/Codex phải thiết kế thành tool-call
  step trong workflow/skill (chi tiết + caveat bảo mật key trong model-mapping.md).
