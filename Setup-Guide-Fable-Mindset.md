# Setup Guide — Fable Mindset Harness

> Bộ skill + harness dạy Opus (hoặc bất kỳ model Claude nào) suy nghĩ và hành
> xử theo kỷ luật của Fable 5.
> Tạo: 2026-07-06 · Cập nhật: 2026-07-09 (đồng bộ với fable-harness v1.1)

> **⚠️ Cập nhật quan trọng:** Tầng always-on của guide này
> (`.claude/rules/fable-mindset.md` + hook `fable-mindset.sh`) đã bị **xóa và
> thay thế** bởi gói `fable-harness/` v1.1 — 10 rules tự nạp (thêm
> 45-writing, 70-autonomy, 75-context-economy), guard hook chặn lệnh phá hủy
> Bash lẫn PowerShell, Stop hook chặn tuyên bố "hoàn thành" không có bằng
> chứng, PreCompact hook snapshot state trước khi nén context (mọi hook có
> cặp .sh/.ps1, bản .sh tự fallback sang .ps1 khi thiếu jq), `/intake`, skill
> `fable-review`, agents `fable-critic`/`fable-verifier`. Cài vào project
> FOXAI bằng `bash fable-harness/INSTALL.sh /duong/dan/project`. Xem
> `fable-harness/README.md`. Những gì còn hiệu lực trong guide này: skill
> `/fable-mindset` (tài liệu dạy, nạp theo yêu cầu) và agent
> `opus-as-fable` (delegate task cho Opus với system prompt kiểu Fable).

---

## 1. Ý tưởng

Khác biệt của Fable so với Opus không nằm ở kiến thức mà ở **kỷ luật hành vi**
(behavioral discipline). Bộ harness này mã hóa kỷ luật đó thành 4 trụ cột
(pillar) để model nào cũng thực thi được:

| Trụ cột | Nội dung cốt lõi |
|---------|------------------|
| **Communication** | Kết quả trước, chi tiết sau; câu hoàn chỉnh, không fragment/arrow chain; mọi thứ user cần nằm ở message cuối của turn |
| **Autonomy** | Hành động reversible (đảo ngược được) trong scope → làm luôn, không hỏi "Shall I…?"; chỉ dừng khi destructive, outward-facing, hoặc đổi scope |
| **Evidence** | Bằng chứng trước khi đổi state; verify bằng cách chạy thật; cấm "should work now" — thay bằng "ran X, observed Y" |
| **Turn ending** | Không kết thúc turn bằng plan/lời hứa — làm nốt việc đó ngay |

## 2. Các thành phần còn hiệu lực

```
.claude/
├── skills/fable-mindset/
│   ├── SKILL.md                      # Skill chính — gọi bằng /fable-mindset
│   └── references/
│       ├── communication.md          # Chi tiết: viết báo cáo kiểu Fable
│       ├── autonomy.md               # Chi tiết: khi nào tự làm, khi nào hỏi
│       └── verification.md           # Chi tiết: evidence gates + claim ledger
└── agents/opus-as-fable.md           # Subagent chạy Opus với system prompt kiểu Fable
```

Phân vai với fable-harness — không trùng lặp:

1. **fable-harness** (`fable-harness/`, luôn bật) — tầng cưỡng chế: 10 rules
   tự nạp mỗi phiên + 4 hooks chạy tất định. Đây là tầng always-on duy nhất.
2. **Skill** (`/fable-mindset`, nạp theo yêu cầu) — tài liệu dạy đầy đủ, có
   những phần harness không chứa: bảng Claim Ledger, Progress Narration
   Budget, bảng Anti-Pattern. Chỉ gọi khi hành vi "trôi" giữa phiên hoặc để
   onboarding người mới — KHÔNG nạp thường trực (rules harness đã luôn bật,
   nạp thêm là trùng ~1.800 token).
3. **Agent** (`opus-as-fable`) — khi cần delegate: subagent chạy model Opus
   với system prompt nhúng sẵn kỷ luật Fable; báo cáo cuối bằng tiếng Việt.

## 3. Cài đặt

Trên máy này đã cài xong global (2026-07-09): skill + agent nằm ở
`~/.claude/skills/fable-mindset/` và `~/.claude/agents/`, fable-harness v1.1
nằm ở `~/.claude/rules/fable/` + `~/.claude/hooks/` + `~/.claude/settings.json`.

Cài cho máy khác trong team:

```bash
# 1. Cài fable-harness (tầng always-on) vào project hoặc global
bash fable-harness/INSTALL.sh /duong/dan/project
# — hoặc global: copy fable-harness/.claude/rules/fable/ vào ~/.claude/rules/,
#   hooks vào ~/.claude/hooks/, merge settings.fable.json vào ~/.claude/settings.json

# 2. Copy skill dạy + agent (tùy chọn, on-demand)
cp -r .claude/skills/fable-mindset ~/.claude/skills/
cp .claude/agents/opus-as-fable.md ~/.claude/agents/
```

Kiểm tra sau cài: mở phiên Claude Code mới → thấy banner
`[FABLE STANDARD ACTIVE]` ở đầu phiên → chạy bộ 12 canary prompt trong
`fable-harness/EVAL-canary-prompts.md`.

## 4. Cách dùng hàng ngày

| Tình huống | Làm gì |
|-----------|--------|
| Mở session mới (mọi model) | fable-harness tự nạp rules + banner — không cần làm gì |
| Model bắt đầu hỏi "Shall I proceed?" / trả lời fragment giữa phiên | Gõ `/fable-mindset` để nạp lại bản dạy đầy đủ |
| Onboarding người mới vào chuẩn Fable | Đọc `/fable-mindset` + bảng Anti-Pattern |
| Cần giao task lớn cho Opus xử lý riêng | Delegate cho agent `opus-as-fable`, brief đầy đủ: mục tiêu, ràng buộc, định nghĩa "done" |
| Sau compaction, hành vi trôi | Rules harness tự nạp lại; checkpoint state nằm ở `.claude/checkpoints/` (PreCompact hook tạo) |

## 5. Lưu ý kỹ thuật

- Skill/agent viết bằng tiếng Anh vì instruction tiếng Anh cho model
  bám sát hơn; rule "trả lời user bằng tiếng Việt" (harness rule 40 +
  CLAUDE.md global) vẫn giữ nguyên hiệu lực và không xung đột (mindset quy
  định *cách* làm việc, không quy định ngôn ngữ trả lời).
- Quan hệ subagent: không spawn subagent để tỏ ra kỹ lưỡng, nhưng
  `fable-critic` (trước deliverable gửi khách) và `fable-verifier` (trước
  khi tuyên bố hoàn thành task nhiều bước) là bắt buộc theo harness rule
  30/60 — hai điều này không mâu thuẫn.
- Lịch sử: bản luôn-bật cũ của mindset (`.claude/rules/fable-mindset.md`,
  `.claude/hooks/fable-mindset.sh`) đã xóa hẳn khỏi repo khi hợp nhất vào
  fable-harness — nếu tài liệu nào còn trỏ đến 2 file đó thì là lỗi thời.
