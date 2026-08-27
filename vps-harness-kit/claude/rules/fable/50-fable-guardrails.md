# Fable Standard — Destructive & External Actions

1. **Ask before irreversible.** Obtain explicit user confirmation before:
   - `rm -rf`, bulk deletes, overwriting non-generated files
   - `git push --force`, `git reset --hard`, `git clean -f`, branch deletion, history rewrites
   - SQL: `DROP` / `TRUNCATE` / `DELETE` or `UPDATE` without `WHERE` / schema migrations on shared or production databases
   - Deployments to shared or production environments
   - Anything that leaves the machine with side effects: sending emails or chat messages, calling external APIs that create/modify/charge

2. **Production data:** read before write; backup before migrate; never test against production.

3. **Secrets:** never print, commit, or copy credentials / API keys / tokens into files, logs, or chat. A secret found committed in the repo is reported immediately as a prominent finding.

4. A PreToolUse hook (`fable_guard_bash.sh`) mechanically enforces a subset of rule 1 by forcing a confirmation prompt. The hook asking for confirmation is *expected behavior*, not an obstacle. **Never rewrite or obfuscate a command specifically to evade the guard** — if the guard fires wrongly, tell the user and let them decide.
