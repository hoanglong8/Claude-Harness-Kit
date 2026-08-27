# Global Claude Code Rules — VPS
> Áp dụng cho MỌI project trên VPS này
> Nguồn: chuẩn Anthropic + fable-harness (EVAL 12/12 trên Sonnet) + kinh nghiệm FOXAI
> Bản VPS: 2026-08-27

---

## 1. THÔNG TIN CÁ NHÂN

- **Tên:** Nguyễn Hoàng Long | Delivery Center Director | FOXAI, JSC (fox.ai.vn)
- **Ngôn ngữ:** Luôn trả lời tiếng Việt; thuật ngữ kỹ thuật giữ nguyên tiếng Anh (dịch trong ngoặc ở lần dùng đầu)
- **Trình độ:** PM/PO/BA/Solution Architect — không lập trình trực tiếp
- **Phong cách làm việc:**
  - Giải thích kỹ thuật ở mức đủ để quản lý ra quyết định (không phải mức implement)
  - Nêu rõ trade-off: chi phí, rủi ro, thời gian
  - Ưu tiên giải pháp thực tế với team FOXAI (nhân sự mới, kiêm nhiệm)
  - Thẳng thắn chỉ ra vấn đề — tin xấu nói trước

---

## 2. CONTEXT & SESSION

- Mỗi session = **1 mục tiêu cụ thể** → xong việc mở session mới
- Compact **chủ động** khi context ~70%: `/compact "focus on [X]"`
- Tiếp tục session cũ: `claude -c` (không bắt đầu lại)
- CLAUDE.md + `rules/` **sống sót qua compaction** → ghi rule vào file, không chỉ nói trong chat

---

## 3. TOOL & WORKFLOW

- Gọi **tên tool cụ thể**: "Dùng Grep để tìm X" (không mơ hồ)
- Workflow chuẩn: **Explore → Plan → Execute** (không bỏ bước Plan)
- Continue giữa chừng: "Continue từ [điểm X]" (không hỏi lại từ đầu)
- Reference file bằng đường dẫn — không paste nội dung vào chat

**Token-saving:**
- PDF: dùng `pdftotext` CLI, KHÔNG dùng `Read` (Read load PDF như ảnh = tốn ~5x token)
- Web: ưu tiên `WebFetch` (text-only) → browser tool khi cần trang động/auth
- Subagent model: Haiku (bulk/cơ học) · Sonnet (research có scope) · Opus (planning/trade-off phức tạp)
- Spawn subagent khi: isolate context, parallelize, bulk — KHÔNG khi parent cần reasoning liên tục

**Patterns lặp lại (bake-in):**
- Request "đọc repo / rà soát / bổ sung" → Explore README + cấu trúc thư mục TRƯỚC
- Request "viết tài liệu" → hỏi rõ **đối tượng đọc + format output** trước khi viết
- Làm việc với repo cấu hình cá nhân → đọc CLAUDE.md + memory hiện tại trước khi sửa

**Slash commands hay dùng:** `/memory` `/compact` `/intake` `/review` `/security-review` `/model`

---

## 4. RULES TỰ NẠP (`~/.claude/rules/` — KHÔNG dùng `@import`, sẽ nạp trùng)

- `fable/00..75` (10 file) — chuẩn hành vi Fable (xem §9)
- `bmad-survey.md` — BMAD Quick Survey 30s trước khi execute request mới
- `claude-code-architecture.md` — tham chiếu kiến trúc Claude Code

---

## 5. BEST PRACTICES

**CLAUDE.md:** giữ < 150 dòng · 3 cấp: `~/.claude/CLAUDE.md` (global) · `./CLAUDE.md` (project, commit) · `CLAUDE.local.md` (cá nhân, không commit) · Linux case-sensitive → luôn `CLAUDE.md` (all-caps)

**Memory:** lưu tại `~/.claude/projects/<project>/memory/MEMORY.md` · chỉ ~200 dòng đầu auto-load → index ngắn gọn · dùng `/memory` để browse/edit/xóa

**Hooks:** Hooks > CLAUDE.md cho rule phải thực thi 100%. Đang chạy 4 hook Fable:
SessionStart (neo `[FABLE STANDARD ACTIVE]`) · PreToolUse guard (chặn lệnh phá hủy Bash) ·
Stop verify (chặn claim "hoàn thành" không bằng chứng) · PreCompact checkpoint (snapshot vào `.claude/checkpoints/`).
Config: `~/.claude/settings.json`. Hook cần `jq`; thiếu `jq` → hook thoát êm.

---

## 6. BA & DOCUMENTATION

Keywords "viết tài liệu / BA / framework / glossary / specification" → hỏi 4 câu (đối tượng đọc, mục tiêu, phạm vi/độ dài, format) rồi chọn template phù hợp (Business Vision, BMC, Glossary, Event Storming, Roadmap, Process Flow / Use Case).

---

## 7. DANH SÁCH PROJECT FOXAI (tham chiếu)

- Triển khai VN: Sở KHCN HN, Lào Cai, VPCP, Công An, Bệnh viện A, Agribank, Việt Hưng, Văn Định
- Lào: TPLUS, LaoVietBank
- Cơ hội KD: Vân Đồn, LDBank, APBank

---

## 8. GIT AN TOÀN TRÊN VPS

- Trước khi `git` trong repo lạ: `git remote -v` + `git status` để biết remote là gì, có phải public không
- **KHÔNG `git add .` / `git add -A`** ở thư mục có thể chứa file cá nhân — luôn `git add` đích danh từng path
- Ask trước: `git push --force`, `git reset --hard`, `git clean -f`, xóa branch, rewrite history (hook guard sẽ nhắc)
- Secrets: KHÔNG set `ANTHROPIC_API_KEY` trong env (đè lên login claude.ai). Không in/commit key vào file/log.

---

## 9. CHUẨN HÀNH VI FABLE (fable-harness — auto-load)

10 rule trong `~/.claude/rules/fable/` tự nạp mọi phiên. Điểm neo bắt buộc theo loại việc:

| Tình huống | Hành động |
|---|---|
| Deliverable lớn (>5 trang, cost model, slide deck, tài liệu gửi khách) | Chạy `/intake` trước khi viết |
| Trước khi bàn giao sản phẩm quan trọng | Chạy skill `fable-review` |
| Deliverable gửi khách / trình lãnh đạo | Gọi subagent `fable-critic` phản biện |
| Trước khi báo "hoàn thành" task nhiều bước | Gọi subagent `fable-verifier` kiểm chứng |
| Kiểm số liệu trong văn bản | Viết phép tính tường minh, cấm kiểm nhẩm (rule 20) |

Non-negotiable: (1) đánh giá không xu nịnh (2) bất định nói rõ, cấm bịa số/trích dẫn/tên API (3) cấm claim "hoàn thành/chạy được" khi chưa thực thi + quan sát trong phiên (4) đúng scope, phát hiện thêm ghi cuối (5) trả lời tiếng Việt.

Skill dạy chi tiết (on-demand, không nạp thường trực): `/fable-mindset`.
