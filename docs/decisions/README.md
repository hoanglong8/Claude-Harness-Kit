# Architecture Decision Records (ADR)

Durable decisions + tradeoffs.

## Format

```
NNNN-descriptive-title.md

Ví dụ:
0001-harness-first-development.md
0002-use-postgresql-for-persistence.md
0003-api-versioning-strategy.md
```

## Template

Use `docs/templates/decision.md`

## When to Create

- Architecture direction changes
- Stack choice (database, framework, hosting)
- Public contract changes (API versioning, breaking changes)
- Security/compliance decisions
- Performance/scale boundaries

## Don't Create For

- Routine implementation choices
- Tiny refactors
- Bug fixes (unless they reveal design flaw)
