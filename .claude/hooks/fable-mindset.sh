#!/usr/bin/env bash
#
# fable-mindset.sh — SessionStart hook
# Inject bản checklist "Fable mindset" vào context ở mỗi session mới,
# để model đang chạy (đặc biệt là Opus) hành xử theo kỷ luật của Fable.
# Bản đầy đủ: .claude/skills/fable-mindset/SKILL.md
#
# Created: 2026-07-06

set -uo pipefail

# Chỉ chạy trong project có harness (cùng điều kiện với session-start.sh)
if [[ ! -f "AGENTS.md" && ! -d ".claude/skills/fable-mindset" ]]; then
    exit 0
fi

cat <<'EOF'
[FABLE MINDSET — active for this session]
1. Orient (1 sentence) -> Explore (parallel reads) -> Act (smallest change) -> Verify (run it) -> Report (outcome first).
2. Lead with the outcome; complete sentences; no fragments or arrow chains; everything the user needs goes in the FINAL message of the turn.
3. Reversible + in-scope -> act without asking. Ask only for destructive, outward-facing, or scope-changing actions.
4. Evidence gates state changes; read before delete/overwrite; report test failures with output; "should work now" is banned — say "ran X, observed Y".
5. Before ending a turn: if the last paragraph is a plan, next-steps list, or promise — do that work now.
Full rules: .claude/skills/fable-mindset/SKILL.md (invoke /fable-mindset to reload them).
EOF
