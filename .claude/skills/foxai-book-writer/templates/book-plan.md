# BOOK PLAN — [Tên sách] (master plan, cần user duyệt trước khi viết)

> Trạng thái: DRAFT — chưa được duyệt. Chỉ bắt đầu viết sau khi user nói "chốt"/"duyệt".
> File này là hợp đồng giữa người viết (AI) và người duyệt (user): mọi chương viết ra sẽ bị
> agent `foxai-book-verifier` đối chiếu ngược lại đúng file này.

## 1. Thông tin chung
- **Tựa / phụ đề:**
- **Độc giả mục tiêu:** (ai đọc, trình độ, họ cần gì sau khi đọc)
- **Mục tiêu sách:** (1 câu — đọc xong người đọc làm được gì)
- **Nguồn bản thảo raw:** (đường dẫn file .txt/.md/.docx đã nạp qua read_source.py, hoặc "viết mới")
- **Theme:** navy-gold / burgundy · **Số chương dự kiến:** · **Độ dài mục tiêu/chương:** ~X từ

## 2. Khung mục lục & kế hoạch từng chương

| # | Chương | Mục tiêu chương (1 câu) | Ý chính bắt buộc (3–5 gạch đầu dòng) | Callout dự kiến | Minh họa |
|---|---|---|---|---|---|
| 1 | | | | ví dụ: 1 `!b`, 1 `!g` | 1 ảnh: [chủ đề ảnh, đặt sau section nào] |
| 2 | | | | | |

## 3. Kế hoạch ảnh minh họa toàn sách
- **Số lượng:** bìa (1) + mỗi chương (0–2)
- **Phong cách ảnh thống nhất:** (điền từ image-style profile — xem templates/image-prompts.md)
- **Danh sách ảnh:** bảng [mã ảnh | chương | chủ đề | vị trí đặt | ghi chú]
- Ảnh sinh bằng model ngoài (Midjourney/DALL-E/Ideogram...) từ prompt do skill tạo — ảnh về đặt vào trường `image` của chapter/part trong JSON.

## 4. Ràng buộc & tiêu chí nghiệm thu
- Zero fabrication: số liệu/trích dẫn trong sách phải truy được nguồn (rule 10)
- Mỗi chương đúng ý chính đã liệt kê ở bảng trên — thiếu ý = verifier đánh FAIL
- Phong cách theo style-profile.md đã duyệt
- [Ràng buộc riêng của user: điều không được viết, thông điệp bắt buộc...]

## 5. Cổng duyệt
- [ ] User đã duyệt khung mục lục + kế hoạch chương
- [ ] User đã duyệt style-profile
- [ ] User đã duyệt image-style + số lượng ảnh
→ Đủ 3 ô mới bắt đầu viết. User nói "cứ làm luôn" = tự tick kèm khối "Giả định:" trong plan.
