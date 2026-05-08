# Go + Fiber Architecture Guide

Implementing Harness Architecture (5-layer) in Go/Fiber projects.

---

## Project Structure

```
.
├── domain/                    # LAYER 1: Pure business logic
│   ├── models.go             # Entity definitions
│   ├── interfaces.go         # Repository & service contracts
│   ├── errors.go             # Custom errors
│   └── usecases.go
│
├── application/               # LAYER 2: Orchestration
│   ├── services.go           # Service implementations
│   └── dtos.go               # Data Transfer Objects
│
├── infrastructure/            # LAYER 3: External concerns
│   ├── database/
│   │   ├── connection.go     # Database setup
│   │   ├── migrations/
│   │   └── repositories.go   # Repository implementations
│   ├── http/
│   │   ├── client.go         # External API clients
│   │   └── webhooks.go
│   ├── cache/
│   │   └── redis.go
│   └── config/
│       └── config.go         # Environment, settings
│
├── interface/                 # LAYER 4: Framework setup
│   ├── handlers/
│   │   ├── user_handler.go   # HTTP handlers
│   │   └── product_handler.go
│   ├── middleware/
│   │   ├── auth.go
│   │   ├── error_handler.go
│   │   └── logging.go
│   ├── routes.go             # Route definitions
│   └── setup.go              # App initialization
│
├── main.go                    # Entry point
├── go.mod
├── go.sum
└── README.md
```

---

## Layer Implementation

### 1. Domain Layer (`domain/`)

**Pure business logic, no framework dependency**

```go
// domain/models.go
package domain

import "time"

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}

// domain/interfaces.go
package domain

import "context"

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
}

type UserService interface {
    CreateUser(ctx context.Context, email, name string) (*User, error)
    GetUser(ctx context.Context, id string) (*User, error)
}

// domain/errors.go
package domain

import "fmt"

type ErrorCode string

const (
    ValidationError ErrorCode = "VALIDATION_ERROR"
    NotFoundError   ErrorCode = "NOT_FOUND"
    ConflictError   ErrorCode = "CONFLICT"
)

type DomainError struct {
    Code    ErrorCode
    Message string
}

func (e DomainError) Error() string {
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func NewValidationError(msg string) DomainError {
    return DomainError{
        Code:    ValidationError,
        Message: msg,
    }
}

func NewNotFoundError(entity, id string) DomainError {
    return DomainError{
        Code:    NotFoundError,
        Message: fmt.Sprintf("%s with id %s not found", entity, id),
    }
}

// domain/usecases.go
package domain

import (
    "context"
    "strings"
    "time"

    "github.com/google/uuid"
)

type CreateUserUseCase struct {
    repo UserRepository
}

func NewCreateUserUseCase(repo UserRepository) *CreateUserUseCase {
    return &CreateUserUseCase{repo: repo}
}

func (uc *CreateUserUseCase) Execute(ctx context.Context, email, name string) (*User, error) {
    // Business logic only
    if !strings.Contains(email, "@") {
        return nil, NewValidationError("invalid email format")
    }

    if name == "" {
        return nil, NewValidationError("name is required")
    }

    user := &User{
        ID:        uuid.New().String(),
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
    }

    if err := uc.repo.Save(ctx, user); err != nil {
        return nil, err
    }

    return user, nil
}
```

**Rules:**
- No Fiber imports
- No database queries
- No HTTP concerns
- Return domain errors only
- Context-aware (ctx parameter)

---

### 2. Application Layer (`application/`)

**Service orchestration, validation, error mapping**

```go
// application/services.go
package application

import (
    "context"
    "fmt"

    "yourmodule/domain"
)

type UserService struct {
    repo      domain.UserRepository
    createUC  *domain.CreateUserUseCase
}

func NewUserService(repo domain.UserRepository) *UserService {
    return &UserService{
        repo:     repo,
        createUC: domain.NewCreateUserUseCase(repo),
    }
}

func (s *UserService) CreateUser(ctx context.Context, email, name string) (*UserResponseDTO, error) {
    // Execute domain logic
    user, err := s.createUC.Execute(ctx, email, name)
    if err != nil {
        // Transform domain errors
        if domErr, ok := err.(domain.DomainError); ok {
            return nil, fmt.Errorf("application error: %v", domErr)
        }
        return nil, err
    }

    // Map to response DTO
    return &UserResponseDTO{
        ID:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        CreatedAt: user.CreatedAt,
    }, nil
}

func (s *UserService) GetUser(ctx context.Context, id string) (*UserResponseDTO, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    if user == nil {
        return nil, domain.NewNotFoundError("User", id)
    }

    return &UserResponseDTO{
        ID:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        CreatedAt: user.CreatedAt,
    }, nil
}

// application/dtos.go
package application

import "time"

type CreateUserDTO struct {
    Email string `json:"email" validate:"required,email"`
    Name  string `json:"name" validate:"required"`
}

type UserResponseDTO struct {
    ID        string    `json:"id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}
```

**Responsibilities:**
- Input validation
- Error transformation
- DTO mapping (domain ↔ presentation)
- Transaction management
- Logging & monitoring

---

### 3. Infrastructure Layer (`infrastructure/`)

**External service adapters**

```go
// infrastructure/database/connection.go
package database

import (
    "context"
    "fmt"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

var DB *gorm.DB

func InitDatabase(dsn string) error {
    var err error
    DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        return fmt.Errorf("failed to connect database: %w", err)
    }

    return nil
}

func CloseDatabase() error {
    sqlDB, err := DB.DB()
    if err != nil {
        return err
    }
    return sqlDB.Close()
}

// infrastructure/database/repositories.go
package database

import (
    "context"
    "errors"

    "gorm.io/gorm"
    "yourmodule/domain"
)

type UserModel struct {
    ID        string `gorm:"primaryKey"`
    Email     string `gorm:"uniqueIndex"`
    Name      string
    CreatedAt int64
}

func (m UserModel) TableName() string {
    return "users"
}

type PostgresUserRepository struct {
    db *gorm.DB
}

func NewPostgresUserRepository(db *gorm.DB) *PostgresUserRepository {
    return &PostgresUserRepository{db: db}
}

func (r *PostgresUserRepository) FindByID(ctx context.Context, id string) (*domain.User, error) {
    var model UserModel
    result := r.db.WithContext(ctx).Where("id = ?", id).First(&model)

    if errors.Is(result.Error, gorm.ErrRecordNotFound) {
        return nil, nil
    }

    if result.Error != nil {
        return nil, result.Error
    }

    return &domain.User{
        ID:        model.ID,
        Email:     model.Email,
        Name:      model.Name,
        CreatedAt: time.UnixMilli(model.CreatedAt),
    }, nil
}

func (r *PostgresUserRepository) Save(ctx context.Context, user *domain.User) error {
    model := UserModel{
        ID:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        CreatedAt: user.CreatedAt.UnixMilli(),
    }

    return r.db.WithContext(ctx).Create(&model).Error
}

func (r *PostgresUserRepository) Delete(ctx context.Context, id string) error {
    return r.db.WithContext(ctx).Where("id = ?", id).Delete(&UserModel{}).Error
}

// infrastructure/http/client.go
package http

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
)

type PaymentAPIClient struct {
    apiKey  string
    baseURL string
    client  *http.Client
}

func NewPaymentAPIClient(apiKey string) *PaymentAPIClient {
    return &PaymentAPIClient{
        apiKey:  apiKey,
        baseURL: "https://api.payment.com",
        client:  &http.Client{},
    }
}

func (c *PaymentAPIClient) ProcessPayment(ctx context.Context, amount float64, token string) (string, error) {
    payload := map[string]interface{}{
        "amount": amount,
        "token":  token,
    }

    body, _ := json.Marshal(payload)

    req, _ := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/charge", nil)
    req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.apiKey))
    req.Header.Set("Content-Type", "application/json")

    resp, err := c.client.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return "", fmt.Errorf("payment failed with status %d", resp.StatusCode)
    }

    var result map[string]string
    json.NewDecoder(resp.Body).Decode(&result)

    return result["transaction_id"], nil
}

// infrastructure/config/config.go
package config

import (
    "os"

    "github.com/joho/godotenv"
)

type Config struct {
    DBHost     string
    DBPort     string
    DBUser     string
    DBPassword string
    DBName     string
    ServerPort string
}

func LoadConfig() *Config {
    godotenv.Load()

    return &Config{
        DBHost:     getEnv("DB_HOST", "localhost"),
        DBPort:     getEnv("DB_PORT", "5432"),
        DBUser:     getEnv("DB_USER", "postgres"),
        DBPassword: getEnv("DB_PASSWORD", ""),
        DBName:     getEnv("DB_NAME", "app"),
        ServerPort: getEnv("SERVER_PORT", "3000"),
    }
}

func getEnv(key, defaultVal string) string {
    if value, exists := os.LookupEnv(key); exists {
        return value
    }
    return defaultVal
}
```

**Responsibilities:**
- Database connections & queries
- External API clients
- Cache implementations
- Configuration management
- File system operations

**Rules:**
- Implement domain interfaces
- Encapsulate external details
- Handle connection pooling
- Clean up resources

---

### 4. Interface Layer (`interface/`)

**Fiber routes, middleware, HTTP concerns**

```go
// interface/handlers/user_handler.go
package handlers

import (
    "errors"
    "net/http"

    "github.com/gofiber/fiber/v2"
    "yourmodule/application"
    "yourmodule/domain"
)

type UserHandler struct {
    service *application.UserService
}

func NewUserHandler(service *application.UserService) *UserHandler {
    return &UserHandler{service: service}
}

func (h *UserHandler) CreateUser(c *fiber.Ctx) error {
    var dto application.CreateUserDTO

    if err := c.BodyParser(&dto); err != nil {
        return c.Status(http.StatusBadRequest).JSON(fiber.Map{
            "error": "invalid request body",
        })
    }

    result, err := h.service.CreateUser(c.Context(), dto.Email, dto.Name)
    if err != nil {
        var domErr domain.DomainError
        if errors.As(err, &domErr) {
            status := http.StatusInternalServerError
            switch domErr.Code {
            case domain.ValidationError:
                status = http.StatusBadRequest
            case domain.NotFoundError:
                status = http.StatusNotFound
            }
            return c.Status(status).JSON(fiber.Map{
                "error": domErr.Message,
                "code":  domErr.Code,
            })
        }
        return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
            "error": "internal server error",
        })
    }

    return c.Status(http.StatusCreated).JSON(result)
}

func (h *UserHandler) GetUser(c *fiber.Ctx) error {
    id := c.Params("id")

    result, err := h.service.GetUser(c.Context(), id)
    if err != nil {
        var domErr domain.DomainError
        if errors.As(err, &domErr) {
            status := http.StatusInternalServerError
            switch domErr.Code {
            case domain.NotFoundError:
                status = http.StatusNotFound
            }
            return c.Status(status).JSON(fiber.Map{
                "error": domErr.Message,
            })
        }
        return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
            "error": "internal server error",
        })
    }

    return c.JSON(result)
}

// interface/middleware/error_handler.go
package middleware

import (
    "github.com/gofiber/fiber/v2"
)

func ErrorHandler(c *fiber.Ctx, err error) error {
    code := fiber.StatusInternalServerError

    if e, ok := err.(*fiber.Error); ok {
        code = e.Code
    }

    return c.Status(code).JSON(fiber.Map{
        "error":  err.Error(),
        "status": code,
    })
}

// interface/middleware/logging.go
package middleware

import (
    "log"
    "time"

    "github.com/gofiber/fiber/v2"
)

func LoggingMiddleware(c *fiber.Ctx) error {
    start := time.Now()

    err := c.Next()

    duration := time.Since(start)
    log.Printf(
        "%s %s - Status: %d - Duration: %v",
        c.Method(),
        c.Path(),
        c.Response().StatusCode(),
        duration,
    )

    return err
}

// interface/routes.go
package interface

import (
    "github.com/gofiber/fiber/v2"
    "yourmodule/application"
    "yourmodule/interface/handlers"
    "yourmodule/interface/middleware"
)

func SetupRoutes(app *fiber.App, userService *application.UserService) {
    // Middleware
    app.Use(middleware.LoggingMiddleware)
    app.Use(func(c *fiber.Ctx) error {
        return c.Next()
    })

    // Handlers
    userHandler := handlers.NewUserHandler(userService)

    // Routes
    api := app.Group("/api")
    v1 := api.Group("/v1")

    v1.Post("/users", userHandler.CreateUser)
    v1.Get("/users/:id", userHandler.GetUser)

    // Health check
    app.Get("/health", func(c *fiber.Ctx) error {
        return c.JSON(fiber.Map{"status": "ok"})
    })
}

// interface/setup.go
package interface

import (
    "log"

    "github.com/gofiber/fiber/v2"
    "yourmodule/application"
    "yourmodule/infrastructure/database"
)

func SetupApp(userService *application.UserService) *fiber.App {
    app := fiber.New(fiber.Config{
        ErrorHandler: middleware.ErrorHandler,
    })

    SetupRoutes(app, userService)

    return app
}

func StartServer(app *fiber.App, port string) error {
    log.Printf("Server starting on port %s", port)
    return app.Listen(":" + port)
}
```

**Responsibilities:**
- HTTP request/response handling
- Route definitions
- Middleware execution
- Input validation (first layer)
- Error response transformation
- Logging & tracing

---

### 5. Main Entry Point (`main.go`)

**Dependency injection & app initialization**

```go
// main.go
package main

import (
    "fmt"
    "log"

    "yourmodule/application"
    "yourmodule/infrastructure/config"
    "yourmodule/infrastructure/database"
    iface "yourmodule/interface"
)

func main() {
    // Load configuration
    cfg := config.LoadConfig()

    // Database setup
    dsn := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        cfg.DBHost,
        cfg.DBPort,
        cfg.DBUser,
        cfg.DBPassword,
        cfg.DBName,
    )

    if err := database.InitDatabase(dsn); err != nil {
        log.Fatalf("Failed to initialize database: %v", err)
    }
    defer database.CloseDatabase()

    // Repository & Service setup (Dependency Injection)
    userRepo := database.NewPostgresUserRepository(database.DB)
    userService := application.NewUserService(userRepo)

    // App setup
    app := iface.SetupApp(userService)

    // Start server
    if err := iface.StartServer(app, cfg.ServerPort); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}
```

---

## Dependency Injection Pattern

### Constructor Injection (Recommended)

```go
type UserService struct {
    repo  domain.UserRepository
    cache domain.CacheService
    logger domain.Logger
}

func NewUserService(
    repo domain.UserRepository,
    cache domain.CacheService,
    logger domain.Logger,
) *UserService {
    return &UserService{
        repo:   repo,
        cache:  cache,
        logger: logger,
    }
}
```

**Pros:**
- ✅ Explicit dependencies
- ✅ Easy to test (just pass mocks)
- ✅ No magic

**Cons:**
- More verbose

---

## Error Handling

### Domain Errors

```go
// domain/errors.go
type ErrorCode string

const (
    ValidationError ErrorCode = "VALIDATION_ERROR"
    NotFoundError   ErrorCode = "NOT_FOUND"
)

type DomainError struct {
    Code    ErrorCode
    Message string
}

func (e DomainError) Error() string {
    return e.Message
}
```

### HTTP Response Mapping

```go
// interface/handlers/user_handler.go
func (h *UserHandler) GetUser(c *fiber.Ctx) error {
    result, err := h.service.GetUser(c.Context(), id)
    if err != nil {
        var domErr domain.DomainError
        if errors.As(err, &domErr) {
            status := http.StatusInternalServerError
            switch domErr.Code {
            case domain.ValidationError:
                status = http.StatusBadRequest
            case domain.NotFoundError:
                status = http.StatusNotFound
            }
            return c.Status(status).JSON(fiber.Map{
                "error": domErr.Message,
                "code":  domErr.Code,
            })
        }
    }
    return nil
}
```

---

## Testing Strategy

### Unit Test (Domain)

```go
// domain/usecases_test.go
package domain

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(ctx context.Context, id string) (*User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*User), args.Error(1)
}

func (m *MockUserRepository) Save(ctx context.Context, user *User) error {
    args := m.Called(ctx, user)
    return args.Error(0)
}

func (m *MockUserRepository) Delete(ctx context.Context, id string) error {
    args := m.Called(ctx, id)
    return args.Error(0)
}

func TestCreateUserWithValidEmail(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)

    uc := NewCreateUserUseCase(mockRepo)
    user, err := uc.Execute(context.Background(), "test@example.com", "John")

    assert.NoError(t, err)
    assert.Equal(t, "test@example.com", user.Email)
    assert.Equal(t, "John", user.Name)
    mockRepo.AssertCalled(t, "Save", mock.Anything, mock.Anything)
}

func TestCreateUserWithInvalidEmail(t *testing.T) {
    mockRepo := new(MockUserRepository)
    uc := NewCreateUserUseCase(mockRepo)

    _, err := uc.Execute(context.Background(), "invalid-email", "John")

    assert.Error(t, err)
    domErr := err.(DomainError)
    assert.Equal(t, ValidationError, domErr.Code)
}
```

### Integration Test (Infrastructure)

```go
// infrastructure/database/repositories_test.go
package database

import (
    "context"
    "testing"
    "time"

    "github.com/stretchr/testify/assert"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
    "yourmodule/domain"
)

func setupTestDB(t *testing.T) *gorm.DB {
    db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
    assert.NoError(t, err)

    db.AutoMigrate(&UserModel{})
    return db
}

func TestSaveAndRetrieveUser(t *testing.T) {
    db := setupTestDB(t)
    repo := NewPostgresUserRepository(db)

    user := &domain.User{
        ID:        "test-1",
        Email:     "test@example.com",
        Name:      "Test",
        CreatedAt: time.Now(),
    }

    err := repo.Save(context.Background(), user)
    assert.NoError(t, err)

    found, err := repo.FindByID(context.Background(), "test-1")
    assert.NoError(t, err)
    assert.Equal(t, "test@example.com", found.Email)
}
```

### Handler Test (Interface)

```go
// interface/handlers/user_handler_test.go
package handlers

import (
    "bytes"
    "encoding/json"
    "net/http"
    "testing"

    "github.com/gofiber/fiber/v2"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "yourmodule/application"
)

type MockUserService struct {
    mock.Mock
}

func (m *MockUserService) CreateUser(ctx interface{}, email, name string) (*application.UserResponseDTO, error) {
    args := m.Called(ctx, email, name)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*application.UserResponseDTO), args.Error(1)
}

func TestCreateUserReturns201(t *testing.T) {
    mockService := new(MockUserService)
    mockService.On("CreateUser", mock.Anything, mock.Anything, mock.Anything).Return(
        &application.UserResponseDTO{
            ID:    "1",
            Email: "test@example.com",
            Name:  "John",
        },
        nil,
    )

    handler := NewUserHandler(mockService)
    app := fiber.New()
    app.Post("/users", handler.CreateUser)

    payload := map[string]string{
        "email": "test@example.com",
        "name":  "John",
    }
    body, _ := json.Marshal(payload)

    req := &http.Request{
        Method: "POST",
        URL:    &url.URL{Path: "/users"},
        Body:   io.NopCloser(bytes.NewReader(body)),
        Header: make(http.Header),
    }

    resp, _ := app.Test(req)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
}
```

---

## Development Workflow

### Running the Application

```bash
# Install dependencies
go mod download
go mod tidy

# Run migrations (if using tool like migrate)
migrate -path infrastructure/database/migrations -database "postgresql://..." up

# Development mode (with hot reload using air)
air

# Production build
go build -o app main.go
./app

# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...
```

### Adding a New Feature

1. **Create domain models** (`domain/models.go`)
2. **Create domain interfaces** (`domain/interfaces.go`)
3. **Create use case** (`domain/usecases.go`)
4. **Create service** (`application/services.go`)
5. **Create DTO** (`application/dtos.go`)
6. **Create repository** (`infrastructure/database/repositories.go`)
7. **Create handler** (`interface/handlers/`)
8. **Create routes** (`interface/routes.go`)
9. **Write tests** (unit → integration → handler)

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Circular dependencies | Use interfaces in domain; implementations in infrastructure |
| Domain logic in handlers | Move to service or use case |
| Direct database queries in services | Create repository pattern |
| Fiber imports in domain | Remove all framework imports from domain/ |
| Error type assertion fails | Use `errors.As()` for type checking |
| Hard to test | Too many dependencies; use constructor injection |

---

## References

- **ARCHITECTURE.md** — General layering rules
- **TEST_MATRIX.md** — Testing strategy
- **Fiber Documentation:** https://docs.gofiber.io/
- **GORM Documentation:** https://gorm.io/
- **Clean Architecture:** Robert C. Martin

---

**Status:** ✅ Complete (Phase 4)
