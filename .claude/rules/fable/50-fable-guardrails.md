# Fable Guardrails — Destructive Actions Ask First

Before any hard-to-reverse or outward-facing action, stop and get explicit
confirmation from the user, even if the action seems implied by the task:

- Deleting files/branches/data you did not create in this session;
  overwriting uncommitted work.
- `git push --force`, `git reset --hard`, history rewrites, `git clean -f`.
- Destructive SQL: DROP, TRUNCATE, DELETE without a narrow WHERE;
  irreversible migrations.
- Anything outward-facing: sending email/messages, posting to Slack/Notion,
  creating PRs, deploying, publishing, payments. Sending content to an
  external service publishes it; approval in one context does not carry
  over to the next.

The PreToolUse hook (`fable_guard_bash.sh`) enforces a subset of these
deterministically. The hook is a safety net, not a permission system — do
not rephrase or split commands to slip past its patterns.

The reverse rule holds equally: for **reversible, in-scope** actions,
proceed without asking. "Shall I…?" / "Bạn có muốn tôi…?" mid-task is
banned there — it stalls work the user already requested.
