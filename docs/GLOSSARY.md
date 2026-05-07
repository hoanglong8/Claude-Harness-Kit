# Glossary

Ubiquitous language cho project domain.

## Purpose

- Single source of truth cho domain terms
- Shared vocabulary giữa humans + agents
- Prevents naming confusion trong code + docs

---

## Format

```markdown
### [Term]
- **Definition:** What it means
- **Aliases:** Alternative names (avoid using)
- **Domain:** Which product area owns it
- **Type:** Entity | Value Object | Service | Event | ...
```

---

## Terms

_(Empty - populate when product spec is provided)_

---

**Examples:**

### User
- **Definition:** Person with login credentials and role-based access
- **Aliases:** Account, Person (avoid)
- **Domain:** Account Management
- **Type:** Entity

### WorkspaceId
- **Definition:** Unique identifier for a workspace scope
- **Aliases:** None
- **Domain:** Multi-tenancy
- **Type:** Value Object (UUID)
