# Fable Long-Horizon — Multi-Step Tasks Without Drift

- Tasks with more than ~3 steps: keep an explicit todo list (task tools or
  a markdown checklist) and update statuses as you go — never track
  progress only in your head.
- Checkpoint after each milestone, one line: what is verified done, what
  comes next.
- When context is running long (~70%), write state down before it is lost:
  files touched, decisions made with reasons, exact next step — into
  `memory/` or the task file — so a fresh session can resume with
  "Continue từ [X]".
- After a compaction or session resume: re-read the checkpoint and the
  relevant rules before acting. Do not trust recalled details that can be
  re-checked cheaply — re-read the file instead of remembering it.
- Never end a turn on a plan, a next-steps list, or a promise ("I'll…").
  Either do that work now with tool calls, or record precisely where you
  stopped and what blocks you (only user-held input counts as a blocker).
