# Hệ đối soát ngân hàng FOXAI — Project Rules

## 🎯 Chuẩn hành vi Fable (ƯU TIÊN CAO NHẤT)
Máy này đã cài fable-harness GLOBAL (`~/.claude/rules/fable/` tự nạp) — không cần cài lại.
Không thương lượng: không bịa giao dịch/số liệu; không báo "hoàn thành" khi verifier chưa chạy;
số liệu phải cross-foot được; ngoài phạm vi → "Phát hiện thêm".

## Hệ này là gì
Pipeline 2 agent đối soát sao kê ngân hàng ↔ sổ phụ kế toán, sinh bởi **foxai-agent-factory**
theo `agent-blueprint-doisoat.md` (hợp đồng nghiệm thu — mọi thay đổi hành vi phải sửa blueprint trước).

- Kế toán dùng: đặt 2 file vào `input/` → gõ "đối soát tháng này" → nhận báo cáo trong `output/`
- `doisoat-reconciler` (sonnet): trích xuất → script Python tất định match → báo cáo cross-foot
- `doisoat-verifier` (haiku): recompute độc lập từ file gốc → verdict PASS/FAIL — **bắt buộc chạy trước khi báo kết quả**

## Ràng buộc cứng (từ blueprint mục 3)
- **Dữ liệu KHÔNG rời máy:** cấm mọi tool mạng/MCP gửi ra ngoài trong project này (WebFetch, Gmail, Slack, Notion...). Gửi báo cáo = việc của con người sau khi duyệt.
- Không sửa/ghi đè file trong `input/` — output chỉ ghi vào `output/`.
- Control totals lệch với số dư sao kê → DỪNG chờ người, không đoán.
- PDF scan không có text layer → yêu cầu xin file xlsx, không OCR.
- Mọi con số trong báo cáo do script tính — model không tính nhẩm.
- Tháng đầu với ngân hàng mới: kế toán duyệt tay 100% exception.

## EVAL
Bộ canary: `EVAL-doisoat.md` — chạy lại sau mỗi lần sửa agent/tolerance, chuẩn ≥2/3 lượt.
