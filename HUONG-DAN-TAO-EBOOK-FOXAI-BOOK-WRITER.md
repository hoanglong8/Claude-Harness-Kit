# HƯỚNG DẪN TẠO EBOOK HOÀN CHỈNH VỚI FOXAI-BOOK-WRITER

> Sinh sách phi hư cấu tiếng Việt định dạng **DOCX + PDF** chất lượng xuất bản, theo 2 theme premium
>
> **Phiên bản: 1.1** · Ngày: 12/07/2026 · Skill: foxai-book-writer **v5** (quy trình 5 giai đoạn + multi-agent)
> Vị trí skill: `~/.claude/skills/foxai-book-writer/` (đã chuyển về đúng thư mục skills để Claude Code tự nhận diện)
> File này là nguồn chuẩn; bản `.docx` sinh bằng pandoc + reference FOXAI — sửa ở đây rồi sinh lại.

## 1. Skill làm được gì

Biến nội dung (tiếng Việt có sẵn, hoặc tài liệu Anh/Pháp/Trung/Nhật cần dịch) thành **sách hoàn chỉnh**: bìa + trang giới thiệu + mục lục + trang mở chương (splash) + nội dung có drop cap, callout box, footer đánh số trang, viền vàng mọi trang. Xuất đồng thời `.docx` (chỉnh sửa tiếp được trong Word) và `.pdf` (phát hành ngay).

**Hai theme** (chọn bằng trường `"theme"` trong JSON):

| Theme | Khi nào dùng | Màu chủ đạo |
|---|---|---|
| `navy-gold` (mặc định) | Tài liệu doanh nghiệp, giáo trình trang trọng | Bìa navy `#1E2A45` · accent gold `#C9A84C` |
| `burgundy` | Giống The AI Operator tập 1 — ấm, nổi bật | Bìa đỏ đô `#9E1A31` · heading `#6E1121` · accent vàng đồng `#A8853B` (đo pixel từ PDF gốc) |

**Không làm được:** layout magazine kiểu IELTS FLOW (grid nhiều cột, infographic, hình học trang bìa) — đó là engine khác, chưa có.

## 2. Chuẩn bị (một lần)

- Python 3 + các thư viện: `pip install reportlab python-docx lxml` (kiểm tra: cả ba đã có sẵn trên máy này)
- Font Cormorant Garamond: tự tải lần chạy đầu (cần mạng); đã có sẵn trong `assets/fonts/`
- Windows: **luôn chạy với `PYTHONUTF8=1`** — thiếu biến này tiếng Việt sẽ lỗi encoding

## 3. Tạo ebook nhanh nhất — 3 bước

**Bước 1 — Soạn file JSON** (cấu trúc tối thiểu):

```json
{
  "theme": "burgundy",
  "title": "Tên Sách",
  "subtitle": "Phụ đề",
  "author": "Tên Tác Giả",
  "series_label": "TÊN SERIES · TẬP 1",
  "tags": ["TAG 1", "TAG 2"],
  "cover_quote": "Trích dẫn ngắn trên bìa",
  "about_title": "VỀ CUỐN NÀY",
  "about_author": "Đoạn giới thiệu tác giả.",
  "parts": [
    {
      "number": "I",
      "title": "Tên Phần",
      "chapters": [
        {
          "number": 1,
          "title": "Tên Chương",
          "subtitle": "Phụ đề chương",
          "quote": "Trích dẫn trang mở chương",
          "quote_attribution": "NGUỒN · NĂM",
          "content": "Nội dung markdown của chương..."
        }
      ]
    }
  ]
}
```

**Bước 2 — Sinh sách:**

```bash
PYTHONUTF8=1 python ~/.claude/skills/foxai-book-writer/scripts/generate_book.py book.json thu_muc_output
```

**Bước 3 — Kiểm chứng (bắt buộc theo rule 30):** mở PDF xem bìa + mục lục + 1 trang nội dung; mở DOCX xác nhận không vỡ; đối chiếu số chương trong mục lục với JSON. Chưa mở ra xem thì chưa được báo "xong".

## 4. Cú pháp nội dung chương (trường `content`)

Các đoạn cách nhau bằng **dòng trống** (`\n\n` trong JSON). Đoạn đầu chương tự có drop cap màu accent.

| Viết | Ra kết quả |
|---|---|
| `## Tiêu đề` | Section heading IN HOA + gạch chân accent |
| `# Tiêu đề` | Tiểu mục đậm |
| `> câu trích` | Blockquote nghiêng, thụt lề |
| `**đậm**` / `*nghiêng*` | Bold / italic trong câu |
| `!! ghi chú` | Callout trung tính nền xám |
| `!b` `!t` `!d` `!l` `!p` `!c` `!g` | 7 hộp có nhãn: BỐI CẢNH · THÀNH PHẨM · ĐÒN BẨY · LỖI THƯỜNG GẶP · MẸO PRO · CÁCH DỰNG · BẢN GIAO VIỆC (nền đậm chữ accent) |

## 4B. Quy trình sản xuất 5 giai đoạn (sách hoàn chỉnh, từ v5)

Dùng cho sách thật (nhiều chương, cần chất lượng phát hành) — thay cho "3 bước nhanh" ở mục 3:

| GĐ | Việc | Anh cần làm gì |
|---|---|---|
| 1 | **Nạp bản thảo raw** — đưa file `.txt`/`.md`/`.docx` (hoặc `.pdf`), skill đọc bằng `read_source.py` | Cung cấp đường dẫn file; xác nhận ngôn ngữ/cấu trúc skill báo lại |
| 2 | **Master plan** — skill lập `book-plan-<tên>.md`: mục lục, mục tiêu + ý chính từng chương, kế hoạch ảnh minh họa từng chương | **Duyệt plan (nói "chốt")** — cổng cứng, chưa duyệt là chưa viết chữ nào |
| 3 | **Phong cách viết** — skill lập `style-profile-<tên>.md` | Đưa 1–3 **đoạn văn mẫu** phong cách anh muốn (hiệu quả hơn mô tả); duyệt profile |
| 4 | **Viết + prompt ảnh** — viết từng chương theo plan; sách dài có thể chạy workflow multi-agent `book-production` (mỗi chương 1 writer + 1 verifier song song); sinh prompt ảnh chuẩn hóa | Chạy prompt ảnh bên Midjourney/DALL-E... (kèm ảnh mẫu tham chiếu nếu có), lưu ảnh về, đưa đường dẫn |
| 5 | **Kiểm tra tuân thủ + sinh sách** — agent `foxai-book-verifier` đối chiếu từng ý chính/callout/ảnh/style với plan, trả bảng PASS/FAIL | Đọc bảng verifier trước khi nhận sách; FAIL nào chấp nhận được thì xác nhận |

Templates 3 file kế hoạch: `~/.claude/skills/foxai-book-writer/templates/`. Lưu ý chi phí multi-agent: sách N chương ≈ 2N agent — sách <3 chương viết tuần tự là đủ.

## 5. Quy trình đầy đủ cho sách dịch từ tài liệu nước ngoài

1. **Đọc nguồn:** `PYTHONUTF8=1 python .../scripts/read_source.py "file.docx|pdf|txt" --preview` — xem 10 block đầu, xác nhận ngôn ngữ; bỏ `--preview` để lấy toàn bộ.
2. **Dịch theo chương** (không dịch từng câu rời): giữ giọng tác giả; thuật ngữ giữ tiếng Anh + giải thích Việt lần đầu; tên riêng giữ nguyên.
3. **Làm giàu:** thêm ví dụ bối cảnh Việt Nam, callout `!!`/`!p` cho điểm nhấn, mỗi chương một câu chủ đề.
4. **Ghi nguồn** trong JSON: `"source_language"`, `"source_file"`, `"translation_note"`, khối `"credits"`.
5. Sinh sách + kiểm chứng như mục 3.

## 6. Checklist chất lượng trước khi phát hành (chuẩn Fable)

| ☐ | Kiểm tra |
|---|---|
| ☐ | Mở PDF: bìa đúng theme, tựa không tràn, mục lục khớp số chương và số trang |
| ☐ | Lướt toàn bộ trang: không chồng chữ, không callout vỡ, footer chạy đúng |
| ☐ | Mọi con số/trích dẫn trong sách truy được về nguồn (rule 10 — zero fabrication) |
| ☐ | Sách dịch: đã ghi credits nguyên tác + translation_note |
| ☐ | Chạy skill `fable-review` cho nội dung; sách gửi khách/phát hành rộng → thêm `fable-critic` |
| ☐ | DOCX mở được trong Word, style không vỡ (đây là bản khách chỉnh sửa tiếp) |

## 7. Troubleshooting

| Triệu chứng | Xử lý |
|---|---|
| Tiếng Việt thành `?` hoặc crash encoding | Quên `PYTHONUTF8=1` |
| Chữ chồng nhau quanh drop cap | Bug đã fix trong v4.1 — nếu còn gặp là đang chạy bản script cũ ở đường dẫn cũ `.claude/foxai-book-writer/` (đã thay bằng `.claude/skills/foxai-book-writer/`) |
| `[theme] 'xxx' khong ton tai` | Trường theme chỉ nhận `navy-gold` hoặc `burgundy` — gõ sai sẽ tự về mặc định |
| Font tải không được (lần đầu, máy mới) | Copy 4 file `CormorantGaramond-*.ttf` từ máy khác vào `assets/fonts/` |
| Muốn theme mới (màu thương hiệu khách) | Thêm 1 entry vào dict `THEMES` đầu `generate_book.py` — 6 giá trị màu, không phải sửa code khác |

## 8. Ví dụ đã kiểm chứng (12/07/2026)

Sách mẫu 2 chương chứa đủ mọi thành phần đã được sinh thật bằng cả 2 theme, render ra ảnh đối chiếu trực tiếp với The AI Operator tập 1: bìa, splash chương, drop cap, 7 callout, footer đều khớp ngôn ngữ thiết kế; DOCX kiểm tra màu chữ đúng palette (`6E1121`/`A8853B` với burgundy). Theme burgundy tái tạo đúng bố cục + màu bản gốc; khác biệt còn lại là font (bản gốc dùng font serif khác Cormorant Garamond) — chấp nhận được ở mức "cùng theme thiết kế".

— Hết tài liệu —
