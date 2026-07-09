# Setup Guide — Fable Mindset Harness

> Bộ skill + harness dạy Opus (hoặc bất kỳ model Claude nào) suy nghĩ và hành
> xử theo kỷ luật của Fable 5.
> Tạo: 2026-07-06 · Cập nhật: 2026-07-07 (hợp nhất với gói `fable-harness/`)

> **⚠️ Cập nhật quan trọng (2026-07-07):** Tầng always-on của guide này
> (`.claude/rules/fable-mindset.md` + hook `fable-mindset.sh`) đã được
> **thay thế** bởi gói `fable-harness/` — đầy đủ hơn (7 rules tự nạp,
> guard hook chặn lệnh phá hủy, `/intake`, skill `fable-review`, agents
> `fable-critic`/`fable-verifier`) và cài được vào mọi project FOXAI bằng
> `bash fable-harness/INSTALL.sh /duong/dan/project`. Xem
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

## 2. Các thành phần đã tạo

```
.claude/
├── skills/fable-mindset/
│   ├── SKILL.md                      # Skill chính — gọi bằng /fable-mindset
│   └── references/
│       ├── communication.md          # Chi tiết: viết báo cáo kiểu Fable
│       ├── autonomy.md               # Chi tiết: khi nào tự làm, khi nào hỏi
│       └── verification.md           # Chi tiết: evidence gates + claim ledger
├── rules/fable-mindset.md            # Bản rút gọn always-on (import vào CLAUDE.md)
├── agents/opus-as-fable.md           # Subagent chạy Opus với system prompt kiểu Fable
├── hooks/fable-mindset.sh            # SessionStart hook — inject checklist mỗi session
└── settings.json                     # Đã đăng ký hook (format hooks chuẩn)
```

Bốn tầng này bổ trợ nhau — không trùng lặp:

1. **Skill** (`/fable-mindset`) — tài liệu dạy đầy đủ, load theo yêu cầu
   (progressive disclosure). Dùng khi bắt đầu session trên Opus hoặc khi thấy
   hành vi "trôi" (hỏi xin phép giữa task, trả lời fragment, claim chưa verify).
2. **Rules file** — bản nén < 50 dòng, import vào CLAUDE.md nên **sống sót qua
   compaction**. Đây là tầng always-on.
3. **Hook** — nhắc lại checklist 5 dòng ở đầu MỌI session, không phụ thuộc
   model nhớ hay quên.
4. **Agent** — khi cần delegate: subagent `opus-as-fable` chạy model Opus
   nhưng system prompt đã nhúng sẵn toàn bộ kỷ luật Fable.

## 3. Cài đặt

### 3a. Trong project này (đã xong sẵn)

Hook đã đăng ký trong `.claude/settings.json`. Chỉ cần thêm 1 dòng vào cuối
`CLAUDE.md` của project để bật tầng always-on:

```markdown
@.claude/rules/fable-mindset.md
```

### 3b. Áp dụng global cho mọi project trên máy

```bash
# Copy skill + agent về thư mục global
cp -r .claude/skills/fable-mindset ~/.claude/skills/
cp .claude/agents/opus-as-fable.md ~/.claude/agents/
cp .claude/rules/fable-mindset.md ~/.claude/rules/

# Thêm import vào global CLAUDE.md
echo '@.claude/rules/fable-mindset.md' >> ~/.claude/CLAUDE.md
```

Hook nếu muốn global thì đăng ký trong `~/.claude/settings.json` (mục
`hooks.SessionStart`), nhưng lưu ý script có guard chỉ chạy trong project
có harness — sửa guard nếu muốn chạy mọi nơi.

### 3c. Kiểm tra

```bash
# Hook chạy được và in ra checklist
bash .claude/hooks/fable-mindset.sh

# Skill xuất hiện trong danh sách
# (trong Claude Code, gõ /fable-mindset)
```

## 4. Cách dùng hàng ngày

| Tình huống | Làm gì |
|-----------|--------|
| Mở session mới trên Opus | Hook tự inject checklist — không cần làm gì |
| Opus bắt đầu hỏi "Shall I proceed?" / trả lời fragment | Gõ `/fable-mindset` để nạp lại bản đầy đủ |
| Cần giao task lớn cho Opus xử lý riêng | Delegate cho agent `opus-as-fable`, brief đầy đủ: mục tiêu, ràng buộc, định nghĩa "done" |
| Sau compaction, hành vi trôi | Rules file trong CLAUDE.md vẫn còn; nếu chưa import thì gõ `/fable-mindset` |

## 5. Lưu ý kỹ thuật

- `.claude/settings.json` đã được chuyển sang **format hooks chuẩn** của
  Claude Code (`SessionStart: [{ hooks: [{ type: "command", command: ... }] }]`).
  Format cũ (`{ description, command, enabled }`) không đúng schema thật nên
  hook cũ không bao giờ được thực thi — đây là bug fix kèm theo.
- Skill/rules/agent viết bằng tiếng Anh vì instruction tiếng Anh cho model
  bám sát hơn; rule "trả lời user bằng tiếng Việt" trong CLAUDE.md global
  vẫn giữ nguyên hiệu lực và không xung đột (mindset quy định *cách* làm
  việc, không quy định ngôn ngữ trả lời).
- Bản rules giữ dưới 50 dòng theo đúng best practice "CLAUDE.md ngắn tuân
  thủ tốt hơn dài" — đừng phình nó ra; chi tiết để trong skill references.
