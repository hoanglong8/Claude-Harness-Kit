# TÀI LIỆU HƯỚNG DẪN — SETUP FABLE HARNESS CHO CLAUDE CODE

> Đưa chuẩn hành vi Claude Fable 5 vào Opus, Sonnet và các model Claude khác
>
> **Phiên bản: 1.1** · Ngày: 11/07/2026 · Thay thế bản 1.0 (11/07/2026)
> Nguồn: repository `hoanglong8/Claude-Harness-Kit` (thư mục `fable-harness/`)
> Người biên soạn: Claude Code — duyệt: Nguyễn Hoàng Long
> File này là **nguồn chuẩn**; bản `.docx` cùng tên được sinh tự động từ file này bằng pandoc — sửa nội dung thì sửa ở đây rồi sinh lại.

**Thay đổi chính so với bản 1.0:** 7 → **10 rules** (thêm 45-writing, 70-autonomy, 75-context-economy); 2 → **4 hooks**, mỗi hook có cặp `.sh`/`.ps1` (thêm Stop verify + PreCompact checkpoint); hết cảnh "thiếu jq = guard tắt" (tự fallback sang PowerShell); Windows được hỗ trợ đầy đủ; EVAL 8 → **12 canary** kèm kết quả đo thật trên Sonnet và Opus.

## Giả định của tài liệu

| # | Giả định |
|---|---|
| 1 | Người đọc là thành viên team FOXAI (kỹ sư triển khai, PM/BA) đã cài Claude Code và biết thao tác terminal cơ bản |
| 2 | Tài liệu kỹ thuật nội bộ — không áp dụng định dạng văn bản hành chính NĐ 30/2020/NĐ-CP |
| 3 | Chạy được trên macOS/Linux/Windows; Windows có mục riêng (3.6) |
| 4 | Repo Claude-Harness-Kit đã clone về máy; đường dẫn ví dụ cần thay bằng đường dẫn thật |

---

## 1. Tổng quan

### 1.1. Fable Harness là gì

Bộ đóng gói chuẩn hành vi của Claude Fable 5 thành các thành phần cấu hình Claude Code — rules, skill, hooks, slash command, subagents — để Opus, Sonnet (và các model Claude sau này) hành xử nhất quán theo cùng một chuẩn trong mọi project FOXAI: không xu nịnh, không bịa nguồn, kiểm chứng trước khi báo xong, làm đúng phạm vi, tự chủ thực thi, trả lời theo format chuẩn FOXAI.

Nguồn nội dung: chưng cất từ hiến pháp hành vi Claude công bố công khai (anthropic.com/constitution) + nguyên tắc vận hành agentic (verify-before-done, scope discipline, calibrated uncertainty) — không phải bản sao system prompt nội bộ của Anthropic.

### 1.2. Harness làm được gì — và không làm được gì

| Tầng | Ví dụ | Harness chuyển giao được? |
|---|---|---|
| **Hành vi (behavior)** | Không xu nịnh; nói rõ mức chắc chắn; không bịa; kiểm chứng trước khi báo xong; đúng phạm vi; tự chủ thực thi | **CÓ** — điều khiển bằng prompt + cưỡng chế bằng hook. Đã đo được: EVAL 12/12 trên Sonnet |
| **Năng lực (capability)** | Độ sâu phán đoán; giữ mạch task rất dài; kiến thức; **độ chính xác số học** | **KHÔNG** — Opus chạy harness = Opus giữ kỷ luật của Fable, không phải Fable. Ví dụ thực đo: Sonnet từng tính nhẩm sai rồi kết luận "số khớp" — rule chỉ ép bày phép tính ra cho người đọc bắt được, không triệt tiêu được lỗi |

### 1.3. Kiến trúc defense-in-depth 3 lớp

| Lớp | Thành phần | Bản chất | Điểm mạnh / yếu |
|---|---|---|---|
| 1. Rules (thuyết phục) | `.claude/rules/fable/` (10 file) | Lời dặn — tự nạp mỗi phiên | Phủ rộng, tinh chỉnh dễ; model CÓ THỂ quên trong phiên dài |
| 2. Hooks (cưỡng chế) | 4 hooks × cặp .sh/.ps1 | Code — chạy tất định ngoài model | Không phụ thuộc model "nhớ"; chỉ chặn pattern đã khai báo |
| 3. Subagents (kiểm chéo) | fable-critic, fable-verifier | Con mắt thứ hai, context sạch | Không thiên kiến bởi phiên chính; tốn thêm lượt gọi |

### 1.4. Danh mục thành phần và cơ chế nạp

| Thành phần | Vị trí sau cài | Khi nào vào context | Chi phí token |
|---|---|---|---|
| 10 file rules | `.claude/rules/fable/*.md` | Mỗi phiên, tự động (Claude Code ≥ 2.0.64) | ~2.600–3.000 thường trực |
| Hook neo chuẩn | `hooks/fable_session_context.{sh,ps1}` | Đầu mỗi phiên + sau /clear, compact | ~170/phiên |
| Hook guard | `hooks/fable_guard_bash.sh` + `fable_guard.ps1` | Không vào context (PreToolUse, matcher `Bash\|PowerShell`) | 0 |
| Hook Stop verify | `hooks/fable_stop_verify.{sh,ps1}` | Chỉ khi chặn claim "hoàn thành" thiếu bằng chứng | ~120/lần chặn |
| Hook PreCompact | `hooks/fable_precompact_checkpoint.{sh,ps1}` | Không vào context — snapshot transcript vào `.claude/checkpoints/` (giữ 5 bản) | 0 |
| Skill fable-review | `skills/fable-review/SKILL.md` | Chỉ khi gọi | ~600/lần |
| Command /intake | `commands/intake.md` | Chỉ khi gõ /intake | theo lần dùng |
| 2 subagents | `agents/fable-{critic,verifier}.md` | Context riêng | 0 với phiên chính |
| 2 fragment settings | `settings.fable.json` (bash) / `settings.fable.windows.json` (PowerShell thuần) | Cấu hình | 0 |

## 2. Yêu cầu hệ thống

| Thành phần | Yêu cầu | Ghi chú |
|---|---|---|
| Claude Code | ≥ 2.0.64 | Bản có cơ chế tự nạp `.claude/rules/` |
| bash + jq **HOẶC** PowerShell | — | Hooks `.sh` tự phát hiện thiếu jq và **fallback sang bản `.ps1`** — không còn cảnh "thiếu jq = guard tắt" của v1.0. Riêng `INSTALL.sh` vẫn cần jq để merge settings; máy không có jq thì merge thủ công (mục 3.2) hoặc dùng fragment Windows (mục 3.6) |
| git | bất kỳ | Clone repo nguồn |

## 3. Cài đặt

### 3.1. Cách 1 — Tự động bằng INSTALL.sh (khuyến nghị, cần jq)

```bash
git clone https://github.com/hoanglong8/Claude-Harness-Kit.git
cd Claude-Harness-Kit
bash fable-harness/INSTALL.sh /duong/dan/toi/project
```

Script: copy toàn bộ file (không ghi đè file trùng tên đã có — **idempotent**, chạy lại an toàn); merge **4 nhóm hook** (SessionStart, PreToolUse, Stop, PreCompact) vào settings.json hiện có; `chmod +x` hooks; tự kiểm tra sau cài.

### 3.2. Cách 2 — Thủ công

```bash
cp -r fable-harness/.claude/rules/fable        <project>/.claude/rules/
cp -r fable-harness/.claude/skills/fable-review <project>/.claude/skills/
cp fable-harness/.claude/agents/fable-*.md      <project>/.claude/agents/
cp fable-harness/.claude/commands/intake.md     <project>/.claude/commands/
cp fable-harness/.claude/hooks/fable_*           <project>/.claude/hooks/   # cả .sh lẫn .ps1
chmod +x <project>/.claude/hooks/fable_*.sh
```

Merge nội dung `settings.fable.json` vào `<project>/.claude/settings.json` — kết quả cần đủ **4 nhóm hook**: `SessionStart` (fable_session_context.sh), `PreToolUse` matcher `Bash|PowerShell` (fable_guard_bash.sh), `Stop` (fable_stop_verify.sh), `PreCompact` (fable_precompact_checkpoint.sh). Dùng biến `$CLAUDE_PROJECT_DIR` trong đường dẫn hook. Kiểm tra: `jq -e . settings.json` hoặc `python -c "import json;json.load(open('...'))"`.

### 3.3. Cài toàn máy (mọi project của một cá nhân)

```bash
cp -r fable-harness/.claude/rules/fable   ~/.claude/rules/
cp fable-harness/.claude/agents/*.md      ~/.claude/agents/
cp -r fable-harness/.claude/skills/fable-review ~/.claude/skills/
cp fable-harness/.claude/commands/intake.md ~/.claude/commands/
cp fable-harness/.claude/hooks/fable_*    ~/.claude/hooks/
```

Hooks đăng ký trong `~/.claude/settings.json` với dạng `bash ~/.claude/hooks/fable_*.sh`. **Lưu ý đã kiểm chứng:** mọi file `.md` trong `~/.claude/rules/` (kể cả cấp gốc) đều tự nạp — KHÔNG thêm dòng `@import` trong CLAUDE.md cho các file này, sẽ nạp trùng 2 lần. Khuyến nghị FOXAI: cài theo project + commit vào git để cả team chung chuẩn có version control; bản global cho máy cá nhân.

### 3.4. Ghép đoạn nhận diện vào CLAUDE.md của project (tùy chọn)

```bash
cat fable-harness/CLAUDE.md.fable-section.md >> <project>/CLAUDE.md
```

Rules đã tự nạp nên bước này chỉ giúp model và người mới nhìn thấy harness ngay. Template project mới của kit (`CLAUDE-TEMPLATE.md`) đã có sẵn section "Chuẩn hành vi Fable (ƯU TIÊN CAO NHẤT)".

### 3.5. Xác nhận sau cài

1. Khởi động lại phiên Claude Code.
2. Đầu phiên thấy khối `[FABLE STANDARD ACTIVE]` (6 điểm không thương lượng + workflow anchors).
3. `/memory` xác nhận **10 file** rules đã nạp.
4. Chạy bộ **12 canary** trong `EVAL-canary-prompts.md` (mục 10).

### 3.6. Windows

- **Có Git Bash** (đa số máy FOXAI): dùng `settings.fable.json` như thường — hooks `.sh` tự fallback sang `.ps1` khi thiếu jq. Không cần cài thêm gì.
- **Không có Git Bash**: merge `settings.fable.windows.json` thay cho bản thường (gọi thẳng `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`).
- File `.ps1` phải giữ **encoding UTF-8 có BOM** — Windows PowerShell 5.1 đọc file không BOM như ANSI sẽ vỡ tiếng Việt. Sửa file .ps1 bằng editor khác xong phải kiểm tra lại BOM (3 byte đầu `EF BB BF`).

## 4. Thành phần 1 — Rules (10 file, lớp thuyết phục)

Claude Code tự nạp mọi `.md` trong `.claude/rules/` đầu phiên, ưu tiên ngang CLAUDE.md. Rules viết tiếng Anh có chủ đích (tiết kiệm ~1,5–2× token, instruction-following ổn định hơn), nhúng nhãn đầu ra tiếng Việt; đầu ra cho người dùng vẫn 100% tiếng Việt (rule 40 cưỡng chế).

| File | Chủ đề | Quy tắc cốt lõi |
|---|---|---|
| 00-fable-core | Tư duy cốt lõi | Lead with result; effort tỷ lệ task; root cause thay vì workaround; đọc trước khi viết; assumption protocol (nghiêng hẳn 1 cách hiểu → làm luôn + "Giả định:"; chỉ hỏi 1 câu khi lệch xa); coi user là professional |
| 10-fable-honesty | Trung thực & hiệu chỉnh | Sycophancy = lỗi ngang factual error; evaluate-don't-validate; 3 nhãn chắc chắn (chắc chắn vì đã kiểm / cho là vậy chưa kiểm chứng / không biết); zero fabrication (số liệu, giá, citation, API, số hiệu Nghị định, kết quả test); tin xấu nói trước |
| 20-fable-scope | Kỷ luật phạm vi | Đúng cái được yêu cầu; vấn đề lân cận báo "Phát hiện thêm:" — **quét lỗi liền kề là nghĩa vụ**, và khi quét số liệu phải **viết phép tính tường minh** ("120 − 80 = 40 ≠ 50"), cấm kiểm nhẩm *(mới v1.1 — vá theo kết quả EVAL)*; cấm thêm không-được-yêu-cầu; deliverable lớn bắt buộc /intake |
| 30-fable-verification | Kiểm chứng trước "xong" | Completion claim không kiểm chứng = fabrication; code phải chạy + dán output thật — **thiếu dữ liệu đầu vào KHÔNG phải lý do dừng hỏi: tự tạo dữ liệu mẫu, chạy, ghi rõ "đã chạy với dữ liệu mẫu tự tạo"** *(mới v1.1)*; file sinh ra phải mở lại kiểm; bảng số phải cross-foot; Đã viết ≠ Đã chạy ≠ Đã kiểm chứng; kết báo cáo bằng "Chưa kiểm chứng:" |
| 40-fable-communication | Giao tiếp FOXAI | Tiếng Việt, thuật ngữ Anh; answer-first; bảng cho so sánh, prose cho phân tích; cấm filler; số có đơn vị + nguồn, "(ước tính)" đánh dấu; NĐ 30/2020/NĐ-CP với văn bản hành chính; độ sâu theo vai người hỏi |
| **45-fable-writing** *(mới)* | Chất lượng viết | Readable > concise — rút gọn bằng chọn lọc nội dung, không nén thành fragment/arrow chain; câu hoàn chỉnh; **mọi thứ user cần phải nằm ở message cuối lượt** (text giữa các tool call có thể không hiển thị); viết cho đồng nghiệp vừa quay lại; code comment chỉ ghi ràng buộc code không tự thể hiện |
| 50-fable-guardrails | Phá hủy & hướng ngoại | Hỏi trước khi irreversible (rm -rf, force push, DROP/TRUNCATE, deploy, gửi email/message, API có phí); production: đọc trước ghi, backup trước migrate; secrets không in/commit/copy; cấm viết lại lệnh để lách guard |
| 60-fable-long-horizon | Task dài | Todo hiển thị, done chỉ sau verify; checkpoint trạng thái; sau compaction đọc lại note trước khi tiếp; yêu cầu gốc không biến mất im lặng; gom câu hỏi |
| **70-fable-autonomy** *(mới)* | Tự chủ thực thi | Đủ thông tin thì hành động — không hỏi "Tôi có nên tiếp tục?"; **không kết thúc lượt bằng lời hứa** ("Tôi sẽ làm X" → làm X ngay); lỗi tự chẩn đoán retry; thiếu thông tin tự đi tìm; chỉ dừng khi destructive/scope-change/fork-đắt; **user mô tả vấn đề → deliverable là đánh giá, không tự sửa**; lệnh đổi state cần bằng chứng khớp đúng hành động đó |
| **75-fable-context-economy** *(mới)* | Tiết kiệm context | Fact đã xác lập không re-derive; quyết định user đã "chốt" không mở lại; **recommend thay vì survey** (1 đề xuất kèm trade-off, không liệt kê mọi phương án); batch/song song tool call độc lập; sau compaction đọc checkpoint ở `.claude/checkpoints/` |

**Nhãn đầu ra chuẩn hóa:** "Giả định:" · "Chưa kiểm chứng:" · "Phát hiện thêm:" · "Đã viết / Đã chạy / Đã kiểm chứng" · "(ước tính)".

## 5. Thành phần 2 — Hooks (4 hooks, lớp cưỡng chế)

Mỗi hook có cặp `.sh`/`.ps1`; bản `.sh` tự fallback sang `.ps1` khi thiếu jq (Windows không cần cài jq).

### 5.1. fable_session_context — neo chuẩn (SessionStart)

In khối `[FABLE STANDARD ACTIVE]` ~170 token: 6 điều không thương lượng (v1.1 thêm điểm autonomy) + workflow anchors. Chạy cả sau `/clear` và compaction.

### 5.2. fable_guard — chặn lệnh phá hủy (PreToolUse, matcher `Bash|PowerShell`)

Bắt xác nhận (`permissionDecision=ask`) trước: `rm -rf` (trừ /tmp, $TMPDIR); **`Remove-Item -Recurse -Force`, `rd /s` (trừ Temp/scratchpad) — mới v1.1**; git push --force / reset --hard / clean -f / branch -D (cho qua `--force-with-lease`); SQL DROP/TRUNCATE/DELETE-không-WHERE (chỉ khi gọi DB client thật — grep/echo chứa SQL không bị chặn nhầm); pipe-to-shell `curl|sh` và **`iwr/irm | iex` — mới v1.1**; `chmod -R 777`. Guard hỏi là hành vi đúng thiết kế; model bị cấm viết lại lệnh để lách.

### 5.3. fable_stop_verify — chặn claim "hoàn thành" không bằng chứng (Stop) — *mới v1.1*

Cuối mỗi lượt: nếu message cuối tuyên bố "hoàn thành / đã chạy được / tests pass / đã kiểm chứng" mà lượt đó **không có tool call nào tạo bằng chứng** (Bash/PowerShell/Read/Agent/Skill) → block kèm lý do, buộc model hoặc chạy kiểm chứng ngay hoặc hạ trạng thái xuống "Đã viết, chưa chạy". Có chống vòng lặp (`stop_hook_active`), bỏ qua dạng phủ định ("chưa/không hoàn thành") và bỏ qua khi message đã tự khai "Chưa kiểm chứng" (vá false positive ~6% quan sát được khi đo). Đây là lớp cưỡng chế cho rule 30 — rule nghiêm nhất của harness.

### 5.4. fable_precompact_checkpoint — snapshot trước khi nén context (PreCompact) — *mới v1.1*

Copy transcript vào `.claude/checkpoints/precompact-<timestamp>-<session>.jsonl` (giữ 5 bản gần nhất) trước khi Claude Code compact — rule 60/75 yêu cầu model đọc lại checkpoint sau compaction thay vì tái dựng từ trí nhớ.

## 6. Thành phần 3 — Skill fable-review (tự kiểm trước bàn giao)

6 bước: fabrication scan (mọi số/tên/citation truy về 1 trong 4 nguồn: dữ liệu user / phép tính hiển thị / nguồn đã đọc / lệnh đã chạy) → verification status (hạ cấp claim chưa xứng) → cross-foot numbers (tính thật, không nhìn lướt) → sycophancy scan (sinh phản biện mạnh nhất) → scope scan (thừa gì/thiếu gì) → format compliance. Đầu ra: bảng 6 dòng PASS/FAIL. Nguyên tắc: FAIL khai báo trung thực là output chấp nhận được; FAIL giấu sau summary tự tin thì không.

## 7. Thành phần 4 — Command /intake

Bắt buộc trước deliverable lớn (>5 trang, cost model, slide deck — rule 20.5). Hỏi 6 nhóm trong 1 message: người nhận & bối cảnh · mục tiêu · phạm vi & độ dài · định dạng & chuẩn · nguồn dữ liệu · ràng buộc. Chốt spec ≤10 dòng chờ "chốt" rồi mới sản xuất. User bỏ qua ("cứ làm luôn") → khối "Giả định:" đầu deliverable.

## 8. Thành phần 5 — Subagents (lớp kiểm chéo)

**fable-critic** (red team, tools: Read/Grep/Glob/WebSearch/WebFetch): dùng TRƯỚC deliverable gửi khách/lãnh đạo. Không rubber-stamp; tấn công giả định trước; tự tính lại tổng — cost model lệch tổng là CHƯA ĐẠT bất kể văn hay; tư duy như kiểm toán nhà nước/hội đồng rủi ro. Đầu ra: ĐẠT / ĐẠT CÓ ĐIỀU KIỆN / CHƯA ĐẠT + top rủi ro + phản biện mạnh nhất.

**fable-verifier** (tools: Read/Grep/Glob/Bash): dùng SAU khi phiên chính tin đã xong, TRƯỚC khi báo user. "Trust nothing you are told" — kiểm máy móc từng yêu cầu: file mở ra xem, code tự chạy lại, số tự tính lại; không kiểm được → UNVERIFIABLE (không phải PASS). Đầu ra: bảng PASS/FAIL/UNVERIFIABLE + bằng chứng thật.

Brief cho agent cần đủ: vị trí artifact + yêu cầu gốc + định nghĩa "done" (agent không thấy hội thoại chính).

**Bổ trợ ngoài gói (cùng repo):** skill `/fable-mindset` — tài liệu dạy chuẩn Fable, CHỈ gọi khi hành vi trôi giữa phiên hoặc onboarding (không nạp thường trực — trùng ~1.800 token với rules); agent `opus-as-fable` — worker Opus với system prompt nhúng kỷ luật Fable, báo cáo tiếng Việt.

## 9. Ba cấp CLAUDE.md và thứ tự ưu tiên

| Cấp | File | Vai trò với harness |
|---|---|---|
| Global | `~/.claude/CLAUDE.md` (hoặc CLAUDE.md ở home) | Section "Chuẩn hành vi Fable" + bảng workflow anchors |
| Project | `<project>/CLAUDE.md` (commit git) | Section Fable ưu tiên cao nhất (có sẵn trong `CLAUDE-TEMPLATE.md` của kit) |
| Cá nhân | `CLAUDE.local.md` (không commit) | Preference riêng — **không được nới lỏng rule không-thương-lượng** |

**Thứ tự ưu tiên khi mâu thuẫn: rules Fable → CLAUDE.md global → CLAUDE.md project → CLAUDE.local.md.** Rule project muốn ngoại lệ phải ghi rõ kèm lý do. Nguyên tắc đã kiểm chứng: CLAUDE.md < 150 dòng; rule cần thực thi 100% → dùng hook; rules/CLAUDE.md sống qua compaction, quy ước nói trong chat thì mất.

## 10. Kiểm thử sau cài — bộ EVAL 12 canary

Chạy mỗi prompt 3 lần trên đúng model team dùng, chuẩn ĐẠT = ≥2/3 lần. Chi tiết prompt + tiêu chí trong `fable-harness/EVAL-canary-prompts.md`. 12 bài: anti-sycophancy · anti-fabrication pháp lý · verification (tự tạo sample chạy thật) · scope + báo lỗi liền kề · guard hook (tất định) · calibrated uncertainty · intake · status vocabulary · autonomy · problem-vs-request · recommend-don't-survey · Stop hook (tất định).

**Kết quả đo thật (07/2026, headless, đối chiếu artifact):**

| Model | Kết quả | Ghi chú |
|---|---|---|
| Sonnet | **12/12 ĐẠT** (33 phiên + hook 3/3) | Canary #4 ban đầu 1/3 → vá rule 20 (phép tính tường minh) → 3/3. Stop hook false positive ~6% → đã vá |
| Opus | **12/12 ĐẠT** (22/22 phiên 2 lượt + hook 3/3; lượt 3 nghẽn session limit — kết luận đã chắc vì 2/2 ≥ ngưỡng 2/3) | Chất lượng nhỉnh hơn: tự trích rule khi thực thi, tự quy đổi TCO khi so sánh, đưa khoảng giá kèm mức chắc chắn |

Vòng lặp tinh chỉnh: prompt trượt lặp lại → thêm ví dụ hành vi sai cụ thể + tăng mức mệnh lệnh vào rule → đo lại. Rules là code.

## 11. Vận hành hàng ngày

| Tình huống | Hành động |
|---|---|
| Mở phiên mới | Không cần làm gì — liếc `[FABLE STANDARD ACTIVE]` xác nhận hook sống |
| Sắp yêu cầu tài liệu/cost model lớn | `/intake <mô tả>` → trả lời 6 câu → "chốt" spec |
| Trước khi nhận bàn giao quan trọng | Yêu cầu chạy skill `fable-review`, đọc bảng 6 check trước |
| Deliverable gửi khách/lãnh đạo | Gọi `fable-critic`; chỉ gửi khi ĐẠT hoặc đã xử lý finding lớn |
| Model báo "hoàn thành" task nhiều bước | Gọi `fable-verifier`; tin bảng PASS/FAIL, không tin lời văn |
| Guard/Stop hook chặn | Đọc lý do `[fable-guard]`/`[fable-verify]`, quyết định — hành vi đúng thiết kế |
| Model "quên" chuẩn giữa phiên dài | `/compact` (PreCompact hook tự snapshot); nặng: mở phiên mới |
| Task dừng giữa chừng | `claude -c` + "Continue từ [điểm X]" — model đọc lại checkpoint theo rule 60/75 |

## 12. Tùy biến & bảo trì

| Nhu cầu | Cách làm |
|---|---|
| Tắt một nhóm quy tắc | Xóa file tương ứng trong `rules/fable/` — các file độc lập |
| Giảm token thường trực | Cắt `60` + `75` (project chỉ task ngắn) và/hoặc `40` + `45` (CLAUDE.md project đã quy định format). **Giữ tối thiểu: 00, 10, 30, 70** — 4 file tạo khác biệt lớn nhất |
| Tắt Stop hook (nếu chặn nhầm nhiều) | Xóa block `Stop` trong settings.json — hook đã có chống loop + bỏ qua phủ định/tự khai |
| Thêm pattern guard | Block `grep -Eq ... && ask "..."` vào `.sh` VÀ regex tương ứng vào `.ps1` (giữ 2 bản đồng bộ) |
| Chặn cứng thay vì hỏi | Đổi `ask` → `deny` cho pattern muốn cứng (khuyến nghị: SQL production) |
| Cập nhật khi repo nguồn có bản mới | `git pull` + chạy lại INSTALL.sh — installer KHÔNG ghi đè file đã có; file muốn nhận bản mới phải xóa trước / copy đè thủ công (diff trước nếu đã tùy biến) |
| Quản lý phiên bản | Commit `.claude/` của project vào git — thay đổi rules/hook đi qua review như code |

## 13. Troubleshooting

| Triệu chứng | Nguyên nhân thường gặp | Xử lý |
|---|---|---|
| Không thấy `[FABLE STANDARD ACTIVE]` | settings chưa merge đúng; hook thiếu +x; đường dẫn sai | `jq -e . settings.json`; `ls -l hooks/`; chạy tay `bash hooks/fable_session_context.sh`; mở phiên mới |
| Canary #5 trượt (force push chạy thẳng) | Hook chưa +x; settings thiếu nhóm PreToolUse; máy không có cả bash lẫn PowerShell | Test tay: `echo '{"tool_input":{"command":"git push --force origin main"}}' \| bash hooks/fable_guard_bash.sh` — phải ra JSON `ask` |
| Rules không nạp (/memory không thấy) | Claude Code < 2.0.64; file sai chỗ; chưa mở phiên mới | `claude --version`; `ls .claude/rules/fable/` (đủ **10** file) |
| Stop hook chặn nhầm | Message nhắc "hoàn thành" trong ngữ cảnh meta | Bản v1.1 đã bỏ qua khi có "Chưa kiểm chứng" trong message; còn chặn nhầm → xóa block Stop hoặc tinh chỉnh regex cả `.sh` lẫn `.ps1` |
| Windows: hook vỡ tiếng Việt | File `.ps1` mất BOM | Kiểm 3 byte đầu = `EF BB BF`; re-encode UTF-8 BOM |
| Model vẫn xu nịnh/bịa sau cài | Rule chưa đủ mạnh với model đó | Vòng lặp EVAL mục 10: thêm ví dụ sai cụ thể, tăng mệnh lệnh, đo lại |
| Test headless (`claude -p`) lỗi "Credit balance too low" | Biến `ANTHROPIC_API_KEY` trong env đè login claude.ai | `env -u ANTHROPIC_API_KEY claude -p ...`; kiểm tra và gỡ biến khỏi User environment. **Cảnh báo:** batch `--model X` có thể ghi đè model default trong settings.json — kiểm tra lại sau khi test |

## 14. Giới hạn cần biết trước khi kỳ vọng

1. **Không nâng capability** — Opus + harness = Opus có kỷ luật Fable. Đã đo được ví dụ cụ thể: lỗi số học khi kiểm nhẩm; rule 20 v1.1 ép bày phép tính ra (sai sẽ lộ) chứ không triệt tiêu — cost model gửi khách vẫn bắt buộc qua fable-review + fable-critic.
2. Rules có thể bị "quên" trong phiên rất dài — anchor hook + mỗi phiên 1 mục tiêu + compact chủ động ~70%.
3. Guard chỉ chặn pattern đã khai báo (terraform destroy, kubectl delete... chủ đích không đưa vào bản canonical — tự thêm theo mục 12).
4. EVAL không tất định (trừ #5, #12) — chuẩn chấm ≥2/3 lần; kết quả đo tham chiếu ở mục 10 để so khi cài máy mới.
5. Chi phí thường trực ~2.800–3.200 token/phiên (10 rules + anchor) — đổi lấy hành vi ổn định đã đo được.

## Phụ lục A — Checklist cài đặt

| ☐ | Bước | Lệnh / cách kiểm |
|---|---|---|
| ☐ | Clone repo nguồn | `git clone https://github.com/hoanglong8/Claude-Harness-Kit.git` |
| ☐ | Chạy installer (hoặc cài thủ công mục 3.2) | `bash fable-harness/INSTALL.sh <project>` |
| ☐ | settings.json hợp lệ, đủ **4 nhóm hook** | `jq -e . <project>/.claude/settings.json` |
| ☐ | Hooks có quyền thực thi (.sh) + BOM (.ps1) | `ls -l hooks/`; 3 byte đầu .ps1 = EF BB BF |
| ☐ | Khởi động lại phiên, thấy `[FABLE STANDARD ACTIVE]` | quan sát đầu phiên |
| ☐ | `/memory` thấy **10 file** rules | chạy /memory |
| ☐ | Canary #5: force push bị hỏi; #12: claim ẩu bị chặn | chạy thử trong phiên |
| ☐ | Chạy đủ **12 canary × 3 lần**, ≥2/3 đạt mỗi prompt | so với bảng kết quả mục 10 |
| ☐ | Commit `.claude/` vào git của project | `git add .claude && git commit` |

## Phụ lục B — Cây thư mục sau khi cài

```
<project>/.claude/
├── settings.json                       # đã merge 4 nhóm hook fable
├── rules/fable/                        # TỰ NẠP mỗi phiên — 10 file
│   ├── 00-fable-core.md  10-fable-honesty.md  20-fable-scope.md
│   ├── 30-fable-verification.md  40-fable-communication.md  45-fable-writing.md
│   ├── 50-fable-guardrails.md  60-fable-long-horizon.md
│   └── 70-fable-autonomy.md  75-fable-context-economy.md
├── skills/fable-review/SKILL.md
├── agents/fable-critic.md  fable-verifier.md
├── commands/intake.md
├── hooks/                              # 4 hooks × cặp .sh/.ps1
│   ├── fable_session_context.{sh,ps1}  # SessionStart: neo chuẩn
│   ├── fable_guard_bash.sh + fable_guard.ps1   # PreToolUse: chặn lệnh phá hủy
│   ├── fable_stop_verify.{sh,ps1}      # Stop: chặn claim thiếu bằng chứng
│   └── fable_precompact_checkpoint.{sh,ps1}    # PreCompact: snapshot state
└── checkpoints/                        # sinh tự động khi compact (5 bản gần nhất)
```

## Phụ lục C — Nguồn tham khảo trong repo

| Tài liệu | Vị trí |
|---|---|
| README gói (khái niệm + cài đặt + tùy biến) | `fable-harness/README.md` |
| Bộ kiểm thử + kết quả đo | `fable-harness/EVAL-canary-prompts.md` |
| Installer | `fable-harness/INSTALL.sh` |
| Fragment settings (bash / Windows thuần) | `fable-harness/.claude/settings.fable{,.windows}.json` |
| Đoạn ghép CLAUDE.md | `fable-harness/CLAUDE.md.fable-section.md` |
| Template CLAUDE.md project mới (đã nhúng section Fable) | `CLAUDE-TEMPLATE.md` |
| Skill dạy mindset (on-demand) + guide | `.claude/skills/fable-mindset/` + `Setup-Guide-Fable-Mindset.md` |
| Agent delegate Opus kiểu Fable | `.claude/agents/opus-as-fable.md` |

— Hết tài liệu —
