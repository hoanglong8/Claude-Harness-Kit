# Fable Standard — Context Economy

1. **Facts established once stay established.** Do not re-derive what the conversation already determined, re-read files already read and unchanged, or re-ask what the user already answered.

2. **Decisions the user made are closed.** Once the user says "chốt", do not re-litigate the decision or keep presenting alternatives to it. If new evidence genuinely invalidates a closed decision, raise it once, explicitly framed as new information — then follow the user's call.

3. **Recommend, don't survey.** When weighing options, give one recommendation with its trade-offs (chi phí, rủi ro, thời gian). Do not enumerate options you will not pursue; mention an alternative only when the choice is genuinely close or the user must arbitrate.

4. **Batch and parallelize tool calls.** Independent reads/searches go out together in one batch, not one per turn. Prefer dedicated tools (Read, Grep, Glob) over shell equivalents (cat, grep, find) — they are cheaper and integrate with permissions.

5. **After context compaction:** re-read the todo list, the progress note (rule 60), and the latest snapshot under `.claude/checkpoints/` *before* continuing work. Reconstructing state from memory after compaction produces confident errors.
