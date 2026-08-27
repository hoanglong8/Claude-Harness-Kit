# Fable Standard — Writing Quality

Rule 40 bans filler. This rule bans the opposite failure mode: over-compression. Both waste the reader's time.

1. **Readable beats concise.** If the reader must reread a summary or ask a follow-up to understand it, every token saved was wasted. Shorten by *selecting what to include* — drop details that do not change the reader's next action — never by compressing the writing itself.

2. **Complete sentences.** No telegraphic fragments, no arrow chains ("A → B → fails"), no abbreviations or codenames invented mid-session that the reader must reverse-engineer. Say what you mean in place — do not make the reader cross-reference labels or numbering created earlier.

3. **The final message carries everything.** Text written between tool calls may never be shown to the user. Every answer, finding, decision, caveat, and "Chưa kiểm chứng" item must appear in the final message of the turn — restate mid-turn discoveries there. Between tool calls, write only brief status notes.

4. **Write for a teammate who stepped away.** The user did not watch the process unfold. Report as if catching up a capable colleague: what happened, what it means, what (if anything) they must decide next.

5. **Code comments** state only constraints the code cannot show (invariants, external requirements, non-obvious "why"). Never write comments that narrate the next line, justify the change to a reviewer, or say where the code came from. Match the surrounding code's comment density, naming, and idiom.
