---
name: foxai-book-writer
description: >
  Tạo sách phi hư cấu tiếng Việt định dạng .docx + .pdf cao cấp (Navy/Gold style —
  cảm hứng từ The AI Operator series). Trigger khi user nói: "tạo sách", "viết book",
  "xuất bản", "generate book", "book creation", "dịch và tạo sách", "chuyển tài liệu
  thành sách", hoặc muốn tạo ebook/tài liệu dạng sách từ bất kỳ ngôn ngữ nào.
  Luôn dùng skill này khi: (1) tạo sách nhiều chương, (2) có file tài liệu nước ngoài
  cần dịch sang tiếng Việt rồi xuất ra sách, (3) user đưa bản thảo raw (.txt/.md/.docx)
  muốn thành sách, (4) cần lập kế hoạch mục lục/master plan cho sách, (5) cần prompt
  sinh ảnh minh họa sách. Quy trình 5 giai đoạn có cổng duyệt — KHÔNG viết chương
  trước khi user duyệt book-plan.
---

# foxai-book-writer v5 — Quy Trình Sản Xuất 5 Giai Đoạn + Multi-Agent

## QUY TRÌNH SẢN XUẤT SÁCH (bắt buộc theo thứ tự, có cổng duyệt)

Với yêu cầu tạo sách hoàn chỉnh, đi qua đủ 5 giai đoạn. Sách nhỏ (<3 chương, user nói "làm nhanh") có thể gộp 2+3 vào một lượt hỏi.

**GĐ1 — NẠP BẢN THẢO RAW.** User cung cấp đường dẫn file `.txt`/`.md`/`.docx` (hoặc `.pdf`):
`PYTHONUTF8=1 python scripts/read_source.py "<file>" --preview` → xác nhận ngôn ngữ + cấu trúc với user. Không có bản thảo = viết mới từ đề bài, ghi rõ trong plan.

**GĐ2 — LẬP MASTER PLAN → CHỜ DUYỆT.** Tạo file `book-plan-<tên>.md` theo `templates/book-plan.md`: khung mục lục, mục tiêu + ý chính bắt buộc từng chương, kế hoạch ảnh minh họa từng chương, ràng buộc nghiệm thu. **DỪNG LẠI chờ user duyệt** ("chốt") — đây là cổng cứng, không viết chương nào trước khi qua cổng. User nói "cứ làm luôn" → tự duyệt kèm khối "Giả định:".

**GĐ3 — CHỐT PHONG CÁCH VIẾT.** Tạo `style-profile-<tên>.md` theo `templates/style-profile.md`. Ưu tiên xin user **đoạn văn mẫu** (từ sách họ thích/họ tự viết) và phân tích mẫu thay vì bắt mô tả trừu tượng. Duyệt cùng cổng GĐ2 được.

**GĐ4 — VIẾT + SINH PROMPT ẢNH.**
- Viết từng chương theo plan + style profile (đọc lại style-profile mục 4-5 trước mỗi chương).
- Sách nhiều chương / user yêu cầu song song: chạy workflow **`book-production`** (multi-agent — mỗi chương 1 writer + 1 verifier chạy song song; xem `~/.claude/workflows/book-production.js`, truyền chapters đã duyệt vào args). Lưu ý chi phí: N chương ≈ 2N agent.
- Sinh prompt ảnh cho model AI ngoài theo `templates/image-prompts.md` (image-style do user duyệt, hỗ trợ ảnh mẫu tham chiếu) → user tự chạy bên Midjourney/DALL-E/... → ảnh về điền vào trường `image`.

**GĐ5 — KIỂM TRA TUÂN THỦ + SINH SÁCH.** Ghép content vào book JSON → `generate_book.py` → gọi agent **`foxai-book-verifier`** đối chiếu toàn sách với book-plan (từng ý chính, callout, số ảnh, style, cổng duyệt) → báo cáo bảng PASS/FAIL kèm "Việc còn lại". Chỉ báo "hoàn thành" khi verifier kết luận ĐÚNG KẾ HOẠCH (rule 30).

---

## Themes (mới v4.1)

Chọn qua trường `"theme"` trong book JSON (không có = navy-gold):

| Theme | Bìa/splash | Heading | Accent | Nguồn gốc |
|---|---|---|---|---|
| `navy-gold` (mặc định) | Navy `#1E2A45` | Navy | Gold `#C9A84C` | Design v4 gốc |
| `burgundy` | Đỏ đô `#9E1A31` | Đỏ đậm `#6E1121` | Vàng đồng `#A8853B` | Trích pixel từ The AI Operator tập 1 (PDF gốc) |

Fix kèm v4.1: drop cap chỉ áp cho đoạn đầu chương (trước đây bị re-áp sau mỗi `##` heading gây chồng chữ); dòng drop cap tự giãn (`autoLeading`) không đè đoạn trên; drop cap + viền DOCX + hộp `!g` đổi màu theo theme.

## Mô tả
Tạo sách phi hư cấu tiếng Việt chất lượng cao từ hai nguồn:
- **Nội dung có sẵn** (tiếng Việt) → cấu trúc JSON → xuất DOCX + PDF
- **Tài liệu nước ngoài** (EN/FR/ZH/JA/...) → đọc → dịch → cấu trúc JSON → xuất DOCX + PDF

---

## Scripts

| Script | Mục đích |
|--------|---------|
| `generate_book.py` | Tạo DOCX + PDF từ JSON |
| `read_source.py` | Đọc & extract tài liệu nguồn (docx/txt/pdf) |

```bash
# Đọc tài liệu nguồn
PYTHONUTF8=1 python C:\Users\Admin\.claude\skills\foxai-book-writer\scripts\read_source.py <file> [--preview]

# Tạo sách
PYTHONUTF8=1 python C:\Users\Admin\.claude\skills\foxai-book-writer\scripts\generate_book.py <book.json> [output_dir]
```

---

## Workflow A — Nội dung tiếng Việt có sẵn

1. **Thu thập nội dung** — đọc file hoặc nhận nội dung trực tiếp từ user
2. **Cấu trúc JSON** — tổ chức thành parts → chapters với nội dung markdown
3. **Điền metadata** — title, subtitle, series_label, tags, author, cover_image
4. **Lưu JSON** → Desktop hoặc nơi user chỉ định
5. **Chạy `generate_book.py`** → DOCX + PDF có timestamp
6. **Báo kết quả** — đường dẫn file + size

---

## Workflow B — Dịch tài liệu nước ngoài → Sách tiếng Việt

### Bước 1: Đọc tài liệu nguồn
```bash
PYTHONUTF8=1 python read_source.py "<đường_dẫn>" --preview
```
Xem 10 block đầu để kiểm tra ngôn ngữ và cấu trúc. Nếu cần toàn bộ:
```bash
PYTHONUTF8=1 python read_source.py "<đường_dẫn>" > source_raw.json
```
`read_source.py` trả về:
- `detected_language`: `en` / `fr` / `zh` / `ja` / `vi` / `unknown`
- `blocks`: danh sách `{type: h1|h2|h3|p|quote|list, text: "..."}`

### Bước 2: Dịch theo cấu trúc
Dịch từng nhóm block (theo chương/section), **không dịch theo từng câu rời rạc**. Nguyên tắc:
- **Ngữ nghĩa trước, sát nghĩa sau** — tránh dịch máy word-by-word
- **Giữ giọng văn tác giả** — học thuật thì giữ học thuật, kể chuyện thì giữ tự nhiên
- **Thuật ngữ kỹ thuật**: giữ nguyên tiếng Anh + thêm giải thích tiếng Việt trong ngoặc lần đầu tiên xuất hiện
  - ✅ `thuật toán (algorithm)` — lần đầu; `thuật toán` — các lần sau
  - ✅ Giữ nguyên: AI, API, ChatGPT, blockchain, startup, MVP, token
  - ✅ Dịch: neural network → mạng nơ-ron, dataset → tập dữ liệu
- **Tên riêng**: giữ nguyên tên người, địa danh nước ngoài
- **Trích dẫn** (quotes): dịch + ghi nguồn gốc tiếng Anh trong ngoặc đơn nếu nổi tiếng
- **Đặc thù từng ngôn ngữ**:
  - Tiếng Anh → Việt: chú ý chủ ngữ ẩn, câu bị động
  - Tiếng Pháp → Việt: chú ý giới tính danh từ không cần dịch ra
  - Tiếng Trung/Nhật → Việt: giữ âm Hán-Việt cho khái niệm cổ điển khi phù hợp

### Bước 3: Viết lại và làm phong phú
Sau khi dịch, làm cho nội dung hấp dẫn hơn với độc giả Việt:
- Thêm ví dụ thực tế từ bối cảnh Việt Nam khi phù hợp
- Chú thích ngắn cho khái niệm xa lạ với độc giả Việt
- Đảm bảo mỗi chương có câu chủ đề rõ ràng
- Thêm callout box (`!!`) cho điểm quan trọng cần nhấn mạnh

### Bước 4: Cấu trúc & tạo sách
Xây dựng JSON book data như Workflow A, thêm trường:
```json
{
  "source_language": "en",
  "source_file": "C:\\path\\to\\original.docx",
  "translation_note": "Dịch từ tiếng Anh, lược bỏ chương 5 theo yêu cầu"
}
```

### Bước 5: Chạy generate_book.py và báo kết quả

---

## JSON Schema

### Book-level fields
```json
{
  "title": "Tên Sách",
  "subtitle": "Phụ đề (italic, nhỏ hơn)",
  "author": "Tên Tác Giả",
  "author_byline": "BIÊN SOẠN CÙNG AXIOM V8 TRÊN CLAUDE CODE",
  "author_title": "Chức danh / vai trò",
  "author_contact": "email@example.com",
  "about_author": "Đoạn giới thiệu tác giả (paragraph)",
  "about_title": "VỀ CUỐN NÀY",
  "about_subtitle": "Subtitle trang about",
  "series_label": "THE AI OPERATOR · TẬP 2",
  "tags": ["CLAUDE COWORK", "CLAUDE CODE", "CÔNG VIỆC THẬT"],
  "level_badge": "ADVANCED · CẤP ĐỘ NÂNG CAO",
  "cover_quote": "Trích dẫn ngắn trên bìa",
  "cover_image": "C:\\path\\to\\cover.jpg",
  "source_language": "en",
  "source_file": "C:\\path\\to\\original.docx",
  "translation_note": "Ghi chú về quá trình dịch",
  "credits": {
    "Nguyên tác": "Tên tác giả gốc",
    "Biên dịch": "Claude Code (FOXAI)",
    "Biên tập": "Tên người"
  },
  "parts": [...]
}
```

### Part fields
```json
{
  "number": "I",
  "title": "Tên Phần",
  "subtitle": "Phụ đề phần",
  "image": "C:\\path\\to\\part_bg.jpg",
  "chapters": [...]
}
```

### Chapter fields
```json
{
  "number": 1,
  "title": "Tên Chương",
  "subtitle": "Phụ đề chương (italic)",
  "section_title": "Label nhỏ trên đầu nội dung",
  "quote": "Trích dẫn trên splash page",
  "quote_attribution": "NGUỒN · NĂM",
  "image": "C:\\path\\to\\chapter_bg.jpg",
  "content": "Nội dung markdown (xem syntax bên dưới)"
}
```

---

## Content Markdown Syntax

| Prefix | Kết quả |
|--------|---------|
| `## Heading` | Section heading — navy bold + gold underline |
| `# Heading 2` | Sub-heading navy |
| `> text` | Blockquote italic (left indent) |
| `!! text` | Callout box chung — nền xám nhạt |
| `!i text` | Callout box italic |
| `**text**` | Bold inline |
| `*text*` | Italic inline |
| _(paragraph trống)_ | Ngăn cách đoạn văn |

Đoạn đầu tiên mỗi chương tự động có **drop cap** (chữ đầu to, màu vàng).

### Labeled Callout Boxes (AI Operator style)

| Prefix | Label | Màu nền | Dùng khi nào |
|--------|-------|---------|-------------|
| `!b text` | **BỐI CẢNH** | Xanh nhạt `#EBF0F8` | Giải thích ngữ cảnh, background |
| `!t text` | **THÀNH PHẨM** | Xanh lá nhạt `#EBF5EB` | Kết quả đầu ra, deliverable |
| `!d text` | **ĐÒN BẨY** | Vàng nhạt `#FDF8EC` | Kỹ thuật/công cụ tăng năng suất |
| `!l text` | **LỖI THƯỜNG GẶP** | Đỏ nhạt `#FDF0EC` | Cảnh báo sai lầm phổ biến |
| `!p text` | **MẸO PRO** | Tím nhạt `#F3ECFD` | Bí quyết từ kinh nghiệm thực tế |
| `!c text` | **⚙ CÁCH DỰNG** | Xanh dương nhạt `#F0F4F8` | Hướng dẫn kỹ thuật step-by-step |
| `!g text` | **✦ BẢN GIAO VIỆC** | Navy `#1E2A45` (chữ vàng) | Template prompt/task giao cho AI |

**Ví dụ:**
```
!b Bối cảnh: Người dùng đang làm việc trong môi trường doanh nghiệp với hàng chục workflows khác nhau.

!t Thành phẩm: Một file .md hoàn chỉnh chứa system prompt tùy chỉnh cho team.

!g Hãy đóng vai senior consultant và phân tích business model của [công ty] theo framework MECE.
```

---

## Design System v4.1 (màu theo theme — bảng dưới là navy-gold)

| Element | Chi tiết |
|---------|---------|
| Màu nền bìa | Navy `#1E2A45` (thuần programmatic; `cover_image` tùy chọn) |
| Màu nền body | Cream white `#FDFCF8` |
| Viền trang | Gold `#C9A84C`, 0.8pt, inset 6mm — **mọi trang** |
| Heading | Navy `#1E2A45` bold, Cormorant Garamond + gold underline |
| Body text | `#1A1A1A`, Times New Roman 11pt, justified, 1.2× leading |
| Footer | Trái: series_label · Phải: page number (thin gold rule trên) |
| TOC numbers | Light gray `#CCCCCC`, 38pt (decorative) |
| Chapter opener | Navy splash — **"CHƯƠNG" nhỏ + số "01" lớn 96pt** (zero-padded) |
| Callout box chung | Nền `#EEECE4` (prefix `!!` / `!i`) |
| Labeled callout | 7 loại màu riêng với label bold (prefix `!b` `!t` `!d` `!l` `!p` `!c` `!g`) |
| DOCX border | `<w:pgBorders>` gold single line |

---

## Assets
- Fonts: `C:\Users\Admin\.claude\skills\foxai-book-writer\assets\fonts\` (auto-download lần đầu)
- Images: `C:\Users\Admin\.claude\skills\foxai-book-writer\assets\images\`
  - `cover.png` — ảnh bìa mặc định
  - `Chapter_N.png` — ảnh chương

## Lưu ý kỹ thuật
- `PYTHONUTF8=1` bắt buộc khi chạy trên Windows
- `read_source.py` hỗ trợ `.docx`, `.txt`, `.md`, `.pdf`
- PDF: dùng `pdftotext` (poppler) hoặc `pip install pymupdf`
- PDF lớn: chạy `--preview` trước để kiểm tra, sau đó đọc toàn bộ theo chương
