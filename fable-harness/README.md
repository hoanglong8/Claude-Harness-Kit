# fable-harness

Bộ harness đóng gói **chuẩn hành vi của Claude Fable 5** thành rules, skill, hooks và subagents cho Claude Code — để Opus, Sonnet (và các model Anthropic sau này) hành xử nhất quán theo cùng một chuẩn trong mọi project của FOXAI.

**Phiên bản:** 1.0 · **Yêu cầu:** Claude Code ≥ 2.0.64 (thư mục `.claude/rules/` tự nạp), `jq`, bash.

---

## 1. Harness này làm được gì — và không làm được gì

Cần nói thẳng trước khi cài. Sự khác biệt giữa các model có hai tầng:

| Tầng | Ví dụ | Harness chuyển giao được? |
|---|---|---|
| **Hành vi (behavior)** | Không xu nịnh; nói rõ mức chắc chắn; không bịa nguồn; kiểm chứng trước khi báo xong; làm đúng phạm vi; format chuẩn FOXAI | **Có** — đây chính là nội dung gói này. Phần lớn cảm giác "model này khác model kia" nằm ở tầng này, và tầng này điều khiển được bằng prompt + cưỡng chế bằng hook |
| **Năng lực (capability)** | Độ sâu phán đoán trong tình huống mới; khả năng giữ mạch task rất dài; kiến thức | **Không** — không có prompt nào nâng trần năng lực của model. Opus chạy harness này = Opus giữ được kỷ luật của Fable, không phải Fable |

Cơ chế ba lớp (defense in depth): **rules thuyết phục, hooks cưỡng chế, agents kiểm tra chéo.** Rules là lời dặn — model có thể quên trong phiên dài. Hook là code — chạy tất định, không phụ thuộc model có "nhớ" hay không. Subagent là con mắt thứ hai với context sạch — không bị thiên kiến bởi những gì phiên chính đã tin.

Nguồn nội dung: chưng cất từ hiến pháp hành vi Claude mà Anthropic công bố công khai (anthropic.com/constitution) cộng với các nguyên tắc vận hành agentic (verify-before-done, scope discipline, calibrated uncertainty), viết lại thành quy tắc thực thi được — không phải bản sao system prompt nội bộ.

---

## 2. Cấu trúc gói và cơ chế nạp

```
fable-harness/
├── README.md                      ← file này
├── INSTALL.sh                     ← cài tự động vào project
├── CLAUDE.md.fable-section.md     ← đoạn tùy chọn ghép vào CLAUDE.md
├── EVAL-canary-prompts.md         ← bộ kiểm thử hành vi sau cài
└── .claude/
    ├── settings.fable.json          ← fragment hooks bản bash (INSTALL.sh sẽ merge)
    ├── settings.fable.windows.json  ← fragment hooks bản PowerShell (Windows không có Git Bash)
    ├── rules/fable/               ← 10 file quy tắc, TỰ ĐỘNG NẠP mỗi phiên
    │   ├── 00-fable-core.md           tư duy cốt lõi, assumption protocol
    │   ├── 10-fable-honesty.md        chống xu nịnh, chống bịa, hiệu chỉnh chắc chắn
    │   ├── 20-fable-scope.md          đúng phạm vi, bắt buộc intake với deliverable lớn
    │   ├── 30-fable-verification.md   không "hoàn thành" khi chưa kiểm chứng
    │   ├── 40-fable-communication.md  tiếng Việt, thuật ngữ, số liệu có đơn vị + nguồn
    │   ├── 45-fable-writing.md        readable > concise; message cuối chứa mọi thứ user cần
    │   ├── 50-fable-guardrails.md     hành động phá hủy phải hỏi trước
    │   ├── 60-fable-long-horizon.md   task dài: todo, checkpoint, chống trôi context
    │   ├── 70-fable-autonomy.md       tự chủ thực thi: không hỏi xin phép giữa chừng, không kết thúc bằng lời hứa
    │   └── 75-fable-context-economy.md không re-derive/re-litigate; recommend thay vì survey
    ├── skills/fable-review/SKILL.md   checklist tự kiểm trước bàn giao (nạp khi cần)
    ├── agents/
    │   ├── fable-critic.md            subagent phản biện độc lập (red team)
    │   └── fable-verifier.md          subagent kiểm chứng hoàn thành độc lập
    ├── commands/intake.md             /intake — khai thác yêu cầu trước deliverable lớn
    └── hooks/                         mỗi hook có 2 bản .sh/.ps1; bản .sh tự fallback sang .ps1 khi thiếu jq
        ├── fable_session_context.{sh,ps1}      SessionStart: neo chuẩn vào đầu mỗi phiên (cả sau /clear và compact)
        ├── fable_guard_bash.sh + fable_guard.ps1  PreToolUse(Bash|PowerShell): bắt xác nhận lệnh phá hủy
        ├── fable_stop_verify.{sh,ps1}          Stop: chặn tuyên bố "hoàn thành" không có bằng chứng thực thi trong lượt
        └── fable_precompact_checkpoint.{sh,ps1} PreCompact: snapshot transcript vào .claude/checkpoints/ (giữ 5 bản)
```

Ánh xạ vào khung **Harness Engineering 5 layer** (harness-init): rules + skill + command → Layer 1 (Memory); hai hooks → Layer 4 (Hooks); phần merge settings.json → Layer 3+4. Gói này **bổ sung**, không thay thế, những gì harness-init đã dựng — mọi file đều có prefix `fable` nên không đụng độ tên.

Cơ chế nạp của từng thành phần:

| Thành phần | Khi nào vào context | Chi phí token (ước tính) |
|---|---|---|
| `rules/fable/*.md` (10 file) | Mỗi phiên, tự động, ưu tiên ngang CLAUDE.md | ~2.600–3.000 token, thường trực |
| Hook SessionStart | Đầu mỗi phiên (và sau /clear, compact) | ~170 token, 1 lần/phiên |
| Skill `fable-review` | Chỉ khi được gọi/kích hoạt | ~600 token, theo lần dùng |
| Subagents | Chạy trong context riêng | không tốn context phiên chính (chỉ nhận kết quả về) |
| Hook fable_guard, fable_precompact | Không vào context (chạy ngoài) | 0 |
| Hook fable_stop_verify | Chỉ khi chặn một claim "hoàn thành" thiếu bằng chứng | ~120 token, theo lần chặn |

---

## 3. Cài đặt

**Cách 1 — tự động (khuyến nghị):**

```bash
bash INSTALL.sh /duong/dan/toi/project
```

Script sẽ: copy toàn bộ file (không ghi đè file trùng tên đã có), merge hooks vào `settings.json` hiện có bằng `jq` (append, giữ nguyên hooks cũ; tự bỏ qua nếu đã cài), `chmod +x` hooks, và tự kiểm tra sau cài.

**Cách 2 — thủ công:** copy nội dung `.claude/` vào `.claude/` của project; merge nội dung `settings.fable.json` vào `settings.json`; `chmod +x .claude/hooks/*.sh`.

**Sau khi cài:** khởi động lại phiên Claude Code → chạy `/memory` xác nhận 7 file rules đã nạp → chạy bộ kiểm thử trong `EVAL-canary-prompts.md` (8 canary prompt, có tiêu chí ĐẠT/TRƯỢT rõ ràng). Nếu prompt nào trượt lặp lại, sửa rule tương ứng và đo lại — rules là code, tinh chỉnh theo vòng lặp.

**Windows:** mỗi hook có sẵn 2 bản `.sh` và `.ps1`. Máy có Git Bash: dùng `settings.fable.json` như thường — bản `.sh` tự phát hiện thiếu `jq` và fallback sang bản `.ps1` (không cần cài jq). Máy Windows không có Git Bash: merge `settings.fable.windows.json` thay cho `settings.fable.json` (gọi thẳng PowerShell). Các file `.ps1` phải giữ encoding UTF-8 có BOM — Windows PowerShell 5.1 đọc file không BOM như ANSI sẽ làm vỡ tiếng Việt.

---

## 4. Tùy biến

- **Tắt một quy tắc:** xóa file tương ứng trong `rules/fable/` — các file độc lập, không tham chiếu chéo cứng.
- **Thêm pattern nguy hiểm cho guard:** thêm block `grep -Eq ... && ask "..."` vào `fable_guard_bash.sh`. Mặc định guard trả `permissionDecision=ask` (hỏi người dùng) thay vì `deny` (chặn hẳn) — phù hợp team 5–20 người; muốn cứng hơn cho môi trường production, đổi `ask` thành `deny` ở pattern SQL.
- **Áp dụng toàn máy thay vì từng project:** copy `rules/fable/` vào `~/.claude/rules/`, agents vào `~/.claude/agents/` — sẽ áp cho mọi project của cá nhân đó.
- **Giảm chi phí token:** các file có thể cắt nếu cần gọn: `60-fable-long-horizon.md` + `75-fable-context-economy.md` (nếu project chỉ có task ngắn) và `40-fable-communication.md` + `45-fable-writing.md` (nếu CLAUDE.md project đã quy định format). Giữ lại tối thiểu: 00, 10, 30, 70 — đây là 4 file tạo khác biệt hành vi lớn nhất.
- **Tắt Stop hook** nếu thấy chặn nhầm nhiều (false positive trên các câu chứa "hoàn thành" trong ngữ cảnh khác): xóa block `Stop` trong settings.json. Hook đã có chống vòng lặp (`stop_hook_active`) và bỏ qua các dạng phủ định ("chưa/không hoàn thành").

## 5. Ghi chú về ngôn ngữ của rules

Rules viết bằng **tiếng Anh** có chủ đích, với các cụm đầu ra chuẩn hóa nhúng sẵn tiếng Việt ("Giả định:", "Chưa kiểm chứng:", "Phát hiện thêm:"). Lý do: (1) cùng nội dung, tiếng Việt tốn ~1,5–2 lần token do tokenizer — với ~2.000 token thường trực mỗi phiên, chênh lệch này nhân lên theo mọi phiên của mọi người; (2) instruction-following của các model Claude ổn định nhất với tiếng Anh; (3) đầu ra cho người dùng vẫn 100% tiếng Việt vì rule 40 cưỡng chế điều đó. Nếu team muốn bản rules thuần Việt cho dễ bảo trì, dịch trực tiếp 7 file — cấu trúc đã thiết kế để dịch 1-1.
