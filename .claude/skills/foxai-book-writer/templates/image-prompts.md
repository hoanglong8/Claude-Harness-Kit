# IMAGE PROMPTS — prompt sinh ảnh minh họa cho model AI ngoài

> Skill KHÔNG tự sinh ảnh — nó tạo prompt chuẩn hóa để user đưa sang Midjourney / DALL-E /
> Ideogram / Stable Diffusion..., rồi ảnh trả về đặt vào trường `image` trong book JSON.

## 1. Image-style profile (cần user duyệt — điền một lần, áp cho cả sách)
- **Phong cách:** (flat illustration / isometric 3D / editorial photo / watercolor / line art...)
- **Bảng màu:** khớp theme sách — navy-gold: `#1E2A45` + `#C9A84C` trên nền sáng · burgundy: `#9E1A31` + `#A8853B`
- **Ảnh mẫu tham chiếu của user:** (nếu user đưa ảnh mẫu: mô tả lại đặc điểm trích xuất được —
  chất liệu, ánh sáng, mức chi tiết, bố cục — và nhúng mô tả đó vào MỌI prompt bên dưới;
  với model hỗ trợ image reference thì ghi chú "đính kèm ảnh mẫu khi chạy")
- **Tỷ lệ khung:** bìa 2:3 dọc · ảnh chương 16:9 hoặc 4:3 · **Cấm:** chữ trong ảnh (trừ khi user yêu cầu), watermark, logo lạ

## 2. Cấu trúc prompt chuẩn (mỗi ảnh một khối)

```
[MÃ ẢNH: ch01-a] — Chương 1, đặt sau section "..."
Prompt (EN, cho model ảnh):
  <subject: cảnh/ẩn dụ minh họa ý chính section>, <style profile mục 1>,
  <composition: góc nhìn, tiêu điểm>, <palette: mã màu theme>,
  no text, no watermark, high detail, book illustration
Negative (nếu model hỗ trợ): text, watermark, logo, deformed hands
Aspect: 16:9
Ghi chú cho user: [ảnh này cần truyền tải điều gì — để user tự đánh giá kết quả]
```

## 3. Quy trình
1. Sau khi plan được duyệt: sinh toàn bộ prompt theo danh sách ảnh trong book-plan mục 3, lưu file `image-prompts-<tên sách>.md`.
2. User chạy prompt bên model ảnh (có thể lặp vài lần, chỉnh theo Ghi chú) → lưu ảnh về thư mục dự án.
3. Điền đường dẫn ảnh vào trường `image` của chapter/part trong book JSON → sinh sách.
4. Verifier đối chiếu: số ảnh trong JSON = số ảnh trong plan; ảnh nào thiếu phải nằm trong mục "Chưa kiểm chứng/Còn thiếu" của báo cáo.
