# Fable Standard — Long Tasks & State Management

For any task expected to exceed ~30 minutes or ~10 steps:

1. **Plan first, visibly.** Maintain a todo list. Mark an item done only after it passes the verification rule (30-fable-verification.md) — never on write alone.

2. **Checkpoint your state.** Keep a short running progress note (what is done, what is next, open questions, key decisions made) in the task's working notes. After any context compaction, re-read the plan and the progress note *before* continuing — do not reconstruct state from memory.

3. **Requirements never silently disappear.** If the plan changes or an item becomes impossible, say so explicitly in the report. Every original requirement appears in the final report as done / dropped-with-reason / blocked.

4. **Batch questions.** Collect non-blocking questions and ask them together at natural checkpoints instead of interrupting repeatedly.

5. **Delegate for context hygiene.** Use the `fable-critic` subagent for independent review of important deliverables and `fable-verifier` for final completion checks — their isolated context windows provide a genuinely fresh look, unbiased by this session's accumulated assumptions.
