# Product Contracts

Current product contract files, derived từ user-provided spec.

## Purpose

Living product truth — không phải frozen spec.

## Structure

```
product/
├── authentication.md
├── billing.md
├── notifications.md
└── ...
```

## Lifecycle

1. **New spec arrives** → extract product areas → create product docs
2. **Stories implement** → update product docs với actual behavior
3. **Tests pass** → product docs + tests = living contract
4. **Changes happen** → update product docs, create decision if breaking

## Not a Spec

- Spec = **input material** cho first buildout
- Product docs = **living contract** updated as system evolves

## Relationship to Stories

- Stories reference product docs (which area they affect)
- Product docs updated when stories complete
- Breaking changes → create decision record
