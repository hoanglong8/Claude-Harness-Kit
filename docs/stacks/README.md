# Stack-Specific Implementation Guides

Architecture patterns and layering guides for popular tech stacks.

---

## Purpose

These guides translate **Harness Architecture rules** into concrete patterns for each stack:
- Layering structure (domain → application → infrastructure → interface → surfaces)
- Dependency rule enforcement
- Code organization conventions
- Observable boundaries

**Use these when:**
- Starting a new project with this stack
- Onboarding team members
- Reviewing code structure
- Troubleshooting architectural issues

---

## Available Stacks

### 1. Node.js + Express

**File:** `NODEJS_EXPRESS.md`

**Coverage:**
- Project structure (folders & modules)
- Layer separation with middleware
- Domain models (entities, use cases)
- Infrastructure adapters (database, external APIs)
- Express routes & request handling
- Dependency injection patterns
- Error handling & validation
- Testing strategy

**Example Project:**
```
src/
├── domain/           # Pure business logic
│   ├── entities/
│   ├── usecases/
│   └── interfaces/
├── application/      # Use case orchestration
│   └── controllers/
├── infrastructure/   # External concerns
│   ├── database/
│   ├── http/
│   └── config/
├── interface/        # Express setup
│   ├── middleware/
│   ├── routes/
│   └── error-handlers/
└── main.ts          # Entry point
```

---

### 2. Python + FastAPI

**File:** `PYTHON_FASTAPI.md`

**Coverage:**
- Project structure (packages & modules)
- Layer separation with dependency injection
- Pydantic models (domain schemas)
- Service layer patterns
- Repository pattern for data access
- FastAPI route organization
- Async/await patterns
- Middleware & lifecycle
- Testing with pytest

**Example Project:**
```
src/
├── domain/           # Business logic
│   ├── models.py
│   ├── schemas.py
│   └── interfaces.py
├── application/      # Service layer
│   └── services.py
├── infrastructure/   # External concerns
│   ├── db.py
│   ├── repositories/
│   └── http_clients/
├── interface/        # FastAPI setup
│   ├── api/
│   ├── middleware/
│   └── dependencies.py
├── main.py          # Entry point
└── requirements.txt
```

---

### 3. Go + Fiber

**File:** `GO_FIBER.md`

**Coverage:**
- Project structure (packages)
- Interface-driven design
- Handler layer (Fiber routes)
- Service layer
- Repository pattern
- Error handling conventions
- Middleware setup
- Configuration management
- Testing patterns

**Example Project:**
```
.
├── domain/           # Interfaces & entities
│   ├── models.go
│   └── interfaces.go
├── application/      # Service implementations
│   └── services.go
├── infrastructure/   # External adapters
│   ├── database.go
│   ├── http.go
│   └── cache.go
├── interface/        # Fiber handlers
│   ├── handlers/
│   ├── middleware/
│   └── routes.go
├── main.go          # Entry point
└── go.mod
```

---

## Architecture Rules (All Stacks)

### Dependency Direction
```
┌─────────────────────────────────────────┐
│  Interface Layer (Handlers, Routes)     │
│  ↓ (depends on)                         │
│  Application Layer (Services, Use Case) │
│  ↓                                      │
│  Infrastructure Layer (DB, API, Cache)  │
│  ↓                                      │
│  Domain Layer (Models, Interfaces)      │
│                                         │
└─────────────────────────────────────────┘

RULE: Inner layers NEVER depend on outer layers
```

### Layer Responsibilities

| Layer | Responsibility | Examples |
|-------|---|---|
| **Domain** | Pure business logic, no external dependencies | Models, interfaces, use cases |
| **Infrastructure** | External service adapters | Database, APIs, file system |
| **Application** | Orchestration, validation | Services, error handling |
| **Interface** | HTTP/web concerns | Controllers, routes, middleware |

### Data Flow

```
Request → Route Handler (Interface)
  ↓
Validate & Parse Input
  ↓
Service/UseCase (Application)
  ↓
Domain Logic (Domain)
  ↓
Repository (Infrastructure)
  ↓
Database
  ↓
Response → (reverse direction)
```

---

## Common Patterns

### 1. Dependency Injection

**Why:** Decouple layers, enable testing

**Node.js Example:**
```typescript
class UserService {
  constructor(private userRepo: UserRepository) {}
}

// In main.ts
const userRepo = new PostgresUserRepository();
const userService = new UserService(userRepo);
```

**Python Example:**
```python
async def get_user_service() -> UserService:
    repo = PostgresUserRepository()
    return UserService(repo)

@router.get("/users/{id}")
async def get_user(id: int, service: UserService = Depends(get_user_service)):
    return await service.get_user(id)
```

**Go Example:**
```go
type UserHandler struct {
    service *UserService
}

func NewUserHandler(service *UserService) *UserHandler {
    return &UserHandler{service}
}
```

### 2. Error Handling

**Domain errors should:**
- Be custom types
- Not depend on web framework
- Carry meaningful context
- Be transformed to HTTP responses at interface layer

### 3. Validation

**Always validate at boundaries:**
- Input from external world
- Response from external services
- Before entering domain layer

**NEVER validate inside domain layer** (assume data is valid)

---

## Testing Strategy

### Unit Tests (Domain Layer)
- Test business logic in isolation
- No external dependencies
- Fastest, most numerous

### Integration Tests (Infrastructure Layer)
- Test repository + database interactions
- Use test databases
- Verify SQL/queries

### Handler Tests (Interface Layer)
- Test HTTP request/response
- Mock services below
- Verify status codes, headers

---

## References

- **ARCHITECTURE.md** — General layering rules
- **FEATURE_INTAKE.md** — Risk classification
- **TEST_MATRIX.md** — Proof tracking

---

## Adding New Stacks

To add a new stack guide:

1. Create `{FRAMEWORK}.md` file
2. Follow pattern from existing guides
3. Include: structure, layering, patterns, examples
4. Update this README

**Contact:** Check CLAUDE.md for framework-specific guidance

---

**Status:** ✅ Stack guides available (Phase 4)

