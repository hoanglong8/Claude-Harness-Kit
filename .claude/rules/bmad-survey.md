# BMAD Survey Framework — Quick Checklist

> BMAD = Breakthrough Method of Agile AI-driven Development.
> Tách từ CLAUDE.md section 8 (2026-07-11) — tự nạp qua `~/.claude/rules/`.
> Bản đầy đủ: `~/.claude/guides/BMAD-SURVEY-FRAMEWORK.md`

Mỗi request mới: dùng **BMAD Survey Checklist** để khảo sát context trước execute.

**Quick Survey (30s):**
1. Type? (Feature / Bug / Refactor / Architecture / Analysis)
2. Complexity? (Simple / Complex / Enterprise)
3. Phase? (Analysis / Planning / Solutioning / Implementation / Retrospective)
4. Requirements rõ? (FRs/NFRs/Scope/Timeline định nghĩa)
5. Stakeholders/Context? (Biết ai approve, ai implement, tech stack)

**Nếu ≥1 không rõ:** suggest Analysis workflow (Brainstorm / Research / Brief / PRFAQ), hoặc trigger Planning phase trước Implementation.

Lưu ý quan hệ với fable-harness: BMAD survey bổ trợ, không thay thế — với deliverable lớn thì `/intake` (rule 20.5) vẫn là bước bắt buộc.
