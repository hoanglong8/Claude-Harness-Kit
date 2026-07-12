# MODEL MAPPING — chọn model cho từng role (GĐ2/GĐ3)

## 1. Tier Anthropic (mặc định — theo rule CLAUDE.md global của FOXAI)

| Tier | Dùng cho role | Ví dụ role | Chi phí tương đối |
|---|---|---|---|
| **haiku** | Bulk/cơ học: extract, phân loại, đối chiếu format, đếm | data-extractor, format-checker | 1× |
| **sonnet** | Research có scope, viết nội dung theo spec rõ, verify theo checklist | writer, reviewer, verifier thường | ~5× |
| **opus** | Planning, trade-off phức tạp, phán đoán tình huống mới, judge | architect, judge panel, critic gửi khách | ~25× |
| **inherit** | Verifier/critic quan trọng — chạy cùng model phiên chính | fable-critic, factory-verifier | theo phiên |

Nguyên tắc: (1) chọn tier THẤP nhất đủ dùng, nâng khi EVAL trượt — không nâng phòng hờ;
(2) verifier nên ≥ tier của worker nó kiểm; (3) subagent nhận ra cần tier cao hơn →
return về parent kèm ghi chú escalation, KHÔNG tự nâng.

## 2. Ràng buộc "không có Fable/Opus" (chỉ sonnet/haiku)

Vẫn chạy được toàn bộ pattern — bù phán đoán bằng kỷ luật: cài fable-harness bắt buộc
(EVAL đã đo: Sonnet + harness đạt 12/12); role judge/architect dùng sonnet + tăng số góc nhìn
độc lập (3 → 5) + adversarial verify thay vì tin 1 lượt; cấm role sonnet/haiku tự quyết
hành động irreversible — luôn đẩy về user.

## 3. Hybrid có Codex / GPT / model ngoài

**Giới hạn cứng phải biết:** file agent `.md` của Claude Code CHỈ chạy model Claude.
Role muốn dùng model ngoài phải thiết kế thành **tool-call step**, không phải agent:

| Cách gọi | Khi nào | Ghi chú |
|---|---|---|
| MCP `codex-global` (`mcp__codex-global__codex`) | Codex sinh/sửa code khối lượng lớn | Có sẵn trên máy FOXAI; gọi từ skill/workflow như một tool; kết quả PHẢI qua verifier Claude trước khi dùng |
| API trực tiếp (Bash + curl) | GPT/model khác có API | Key qua env của đúng process đó hoặc Windows Credential Manager — KHÔNG hardcode key vào file (bài học 9router); thêm bước parse + validate response |
| Sinh prompt để user chạy tay | Model ảnh, model không có API | Pattern image-prompts của foxai-book-writer |

Kiến trúc khuyến nghị hybrid: Claude làm orchestrator + verifier (kỷ luật Fable), model ngoài
làm "công nhân chuyên môn" ở bước được đóng khung chặt (input/output schema rõ). Không bao giờ
để model ngoài tự quyết bước irreversible — mọi đầu ra ngoài đều là "Đã viết, chưa kiểm chứng"
cho đến khi verifier Claude xác nhận.

## 4. Khai báo trong blueprint
Ma trận mục 4 của blueprint phải có đủ 2 cột (chỉ-Anthropic / hybrid) cho từng role —
kể cả khi dự án hiện tại chỉ dùng 1 cột, để đổi ràng buộc sau này không phải thiết kế lại.
