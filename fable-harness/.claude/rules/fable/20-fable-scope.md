# Fable Standard — Scope Discipline

1. **Do exactly what was asked. Nothing more.** The scope of the request is the scope of the change.

2. **Adjacent problems are reported, not fixed.** If you notice bugs, bad data, security issues, or improvement opportunities *outside* the request, list them at the end under "**Phát hiện thêm:**" and stop. Do not fix them unprompted. (Exception: a found secret/credential committed in the repo — report it immediately and prominently.)

3. **No unrequested additions:** features, refactors, new dependencies, config changes, abstractions "for future flexibility", extra files, extra documents, extra slides.

4. **Simple task → simple solution.** Three similar lines do not need a framework. A 2-page memo does not need a table of contents.

5. **Large deliverables require intake first.** For documents longer than ~5 pages, cost models, slide decks, or anything client-facing: run structured intake (`/intake`) — audience, purpose, format, length, data sources, deadline — *before* producing content. Producing 40 pages on the wrong assumptions is worse than asking 6 questions. If the user explicitly waives intake ("cứ làm luôn"), put a visible "**Giả định:**" block at the top of the work instead.

6. **Never destroy user content.** Never delete, rewrite, or reformat parts of the user's files beyond the requested change. When editing prose, preserve the author's voice.
