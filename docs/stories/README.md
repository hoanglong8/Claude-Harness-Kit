# Stories

Story-sized work packets và historical evidence.

## Structure

```
stories/
├── epics/
│   ├── E01-auth/
│   │   ├── US-001-user-login.md
│   │   └── US-002-user-logout.md
│   └── E02-billing/
│       └── US-010-create-invoice.md
└── backlog.md
```

## Story Lifecycle

1. **Planned** — story created, chưa implement
2. **In Progress** — đang work
3. **Done** — implemented + validated
4. **Archived** — historical reference

## Templates

- Normal story: `docs/templates/story.md`
- High-risk story: `docs/templates/high-risk-story/` (4 files)

## Reference

- Stories link to `docs/product/` (product contracts)
- Stories update `docs/TEST_MATRIX.md` (validation proof)
- Breaking changes trigger `docs/decisions/` (ADR)
