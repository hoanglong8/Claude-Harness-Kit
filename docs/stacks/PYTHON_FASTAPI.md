# Python + FastAPI Architecture Guide

Implementing Harness Architecture (5-layer) in Python/FastAPI projects.

---

## Project Structure

```
src/
├── domain/                    # LAYER 1: Pure business logic
│   ├── models.py             # Entity/model definitions
│   ├── schemas.py            # Pydantic schemas for validation
│   ├── interfaces.py         # Repository & service interfaces
│   ├── usecases.py
│   └── errors.py             # Custom exceptions
│
├── application/               # LAYER 2: Orchestration
│   ├── services/
│   │   ├── user_service.py   # Service = UseCase + validation
│   │   └── product_service.py
│   └── dto/
│       ├── create_user_dto.py
│       └── user_response_dto.py
│
├── infrastructure/            # LAYER 3: External concerns
│   ├── database/
│   │   ├── connection.py     # SQLAlchemy setup
│   │   ├── repositories/
│   │   │   ├── user_repository.py    # Repository implementations
│   │   │   └── product_repository.py
│   │   └── models.py         # SQLAlchemy ORM models
│   ├── http/
│   │   ├── external_api_client.py
│   │   └── webhook_service.py
│   ├── cache/
│   │   └── redis_cache.py
│   └── config/
│       └── settings.py       # Environment, secrets
│
├── interface/                 # LAYER 4: Framework setup
│   ├── middleware/
│   │   ├── auth_middleware.py
│   │   ├── error_handler.py
│   │   ├── validation.py
│   │   └── logging.py
│   ├── api/
│   │   ├── routes/
│   │   │   ├── users.py
│   │   │   ├── products.py
│   │   │   └── __init__.py    # Route aggregation
│   │   └── dependencies.py    # FastAPI dependency injection
│   └── controllers/
│       ├── user_controller.py # HTTP handlers
│       └── product_controller.py
│
├── main.py                    # Entry point
├── requirements.txt
└── pyproject.toml
```

---

## Layer Implementation

### 1. Domain Layer (`src/domain/`)

**Pure business logic, no framework dependency**

```python
# src/domain/models.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    id: str
    email: str
    name: str
    created_at: datetime

# src/domain/schemas.py
from pydantic import BaseModel, EmailStr

class CreateUserSchema(BaseModel):
    email: EmailStr
    name: str

class UserSchema(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime

    class Config:
        from_attributes = True

# src/domain/interfaces.py
from abc import ABC, abstractmethod
from typing import Optional
from .models import User

class IUserRepository(ABC):
    @abstractmethod
    async def find_by_id(self, user_id: str) -> Optional[User]:
        pass

    @abstractmethod
    async def save(self, user: User) -> None:
        pass

    @abstractmethod
    async def delete(self, user_id: str) -> None:
        pass

# src/domain/usecases.py
from .interfaces import IUserRepository
from .models import User
from .errors import ValidationError
import uuid

class CreateUserUseCase:
    def __init__(self, user_repo: IUserRepository):
        self.user_repo = user_repo

    async def execute(self, email: str, name: str) -> User:
        # Business logic only
        if '@' not in email:
            raise ValidationError('Invalid email')

        user = User(
            id=str(uuid.uuid4()),
            email=email,
            name=name,
            created_at=datetime.now()
        )

        await self.user_repo.save(user)
        return user

# src/domain/errors.py
class DomainError(Exception):
    code: str = 'UNKNOWN_ERROR'

class ValidationError(DomainError):
    code = 'VALIDATION_ERROR'

class NotFoundError(DomainError):
    code = 'NOT_FOUND'
```

**Rules:**
- No FastAPI imports
- No database queries
- No HTTP concerns
- Raise domain errors only
- Async-safe design

---

### 2. Application Layer (`src/application/`)

**Service orchestration, validation, error mapping**

```python
# src/application/services/user_service.py
from typing import Optional
from ...domain.interfaces import IUserRepository
from ...domain.usecases import CreateUserUseCase
from ...domain.schemas import CreateUserSchema, UserSchema
from ...domain.models import User
from ...domain.errors import ValidationError

class UserService:
    def __init__(self, user_repository: IUserRepository):
        self.create_user_usecase = CreateUserUseCase(user_repository)
        self.user_repo = user_repository

    async def create_user(self, schema: CreateUserSchema) -> UserSchema:
        try:
            # Execute domain logic
            user = await self.create_user_usecase.execute(
                schema.email,
                schema.name
            )

            # Map to response schema
            return UserSchema.from_orm(user)

        except ValidationError as error:
            raise ApplicationError(
                message=error.message,
                status_code=400,
                code=error.code
            )

    async def get_user(self, user_id: str) -> UserSchema:
        user = await self.user_repo.find_by_id(user_id)
        if not user:
            raise ApplicationError(
                message=f'User {user_id} not found',
                status_code=404,
                code='NOT_FOUND'
            )
        return UserSchema.from_orm(user)

class ApplicationError(Exception):
    def __init__(self, message: str, status_code: int, code: str):
        self.message = message
        self.status_code = status_code
        self.code = code
        super().__init__(message)
```

**Responsibilities:**
- Input validation
- Error transformation
- Schema mapping (domain ↔ presentation)
- Transaction management
- Logging & monitoring

---

### 3. Infrastructure Layer (`src/infrastructure/`)

**External service adapters**

```python
# src/infrastructure/database/connection.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql+asyncpg://user:password@localhost/dbname"

engine = create_async_engine(
    DATABASE_URL,
    echo=True,
    future=True
)

async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_session() -> AsyncSession:
    async with async_session() as session:
        yield session

# src/infrastructure/database/models.py
from sqlalchemy import Column, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class UserModel(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

# src/infrastructure/database/repositories/user_repository.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ...domain.interfaces import IUserRepository
from ...domain.models import User
from ..models import UserModel
from typing import Optional

class PostgresUserRepository(IUserRepository):
    def __init__(self, session: AsyncSession):
        self.session = session

    async def find_by_id(self, user_id: str) -> Optional[User]:
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        user_model = result.scalars().first()
        if not user_model:
            return None

        return User(
            id=user_model.id,
            email=user_model.email,
            name=user_model.name,
            created_at=user_model.created_at
        )

    async def save(self, user: User) -> None:
        user_model = UserModel(
            id=user.id,
            email=user.email,
            name=user.name,
            created_at=user.created_at
        )
        self.session.add(user_model)
        await self.session.commit()

    async def delete(self, user_id: str) -> None:
        await self.session.execute(
            select(UserModel).where(UserModel.id == user_id).delete()
        )
        await self.session.commit()

# src/infrastructure/http/external_api_client.py
import httpx
from typing import Dict, Any

class PaymentAPIClient:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.payment.com"

    async def process_payment(self, amount: float, token: str) -> str:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/charge",
                json={"amount": amount, "token": token},
                headers={"Authorization": f"Bearer {self.api_key}"}
            )

            if response.status_code != 200:
                raise Exception("Payment failed")

            return response.json()["transaction_id"]
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

### 4. Interface Layer (`src/interface/`)

**FastAPI routes, middleware, HTTP concerns**

```python
# src/interface/controllers/user_controller.py
from fastapi import Depends, HTTPException
from ...application.services.user_service import UserService, ApplicationError
from ...domain.schemas import CreateUserSchema, UserSchema

class UserController:
    def __init__(self, user_service: UserService = Depends()):
        self.user_service = user_service

    async def create_user(self, schema: CreateUserSchema) -> UserSchema:
        try:
            return await self.user_service.create_user(schema)
        except ApplicationError as error:
            raise HTTPException(
                status_code=error.status_code,
                detail=error.message
            )

    async def get_user(self, user_id: str) -> UserSchema:
        try:
            return await self.user_service.get_user(user_id)
        except ApplicationError as error:
            raise HTTPException(
                status_code=error.status_code,
                detail=error.message
            )

# src/interface/api/dependencies.py
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ...infrastructure.database.connection import get_session
from ...infrastructure.database.repositories.user_repository import PostgresUserRepository
from ...application.services.user_service import UserService

async def get_user_repository(session: AsyncSession = Depends(get_session)) -> PostgresUserRepository:
    return PostgresUserRepository(session)

async def get_user_service(repo: PostgresUserRepository = Depends(get_user_repository)) -> UserService:
    return UserService(repo)

# src/interface/api/routes/users.py
from fastapi import APIRouter, Depends
from ...controllers.user_controller import UserController
from ...domain.schemas import CreateUserSchema, UserSchema
from ...dependencies import get_user_service

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserSchema, status_code=201)
async def create_user(
    schema: CreateUserSchema,
    service = Depends(get_user_service)
) -> UserSchema:
    controller = UserController(service)
    return await controller.create_user(schema)

@router.get("/{user_id}", response_model=UserSchema)
async def get_user(
    user_id: str,
    service = Depends(get_user_service)
) -> UserSchema:
    controller = UserController(service)
    return await controller.get_user(user_id)

# src/interface/middleware/error_handler.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import logging

logger = logging.getLogger(__name__)

def setup_error_handlers(app: FastAPI):
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=400,
            content={"detail": "Validation error", "errors": exc.errors()}
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )
```

**Responsibilities:**
- HTTP request/response handling
- Route definitions
- Dependency injection setup
- Input validation (first layer)
- Error response transformation
- Logging & tracing

---

### 5. Main Entry Point (`src/main.py`)

**Dependency injection & app initialization**

```python
# src/main.py
from fastapi import FastAPI
from contextlib import asynccontextmanager
from .infrastructure.database.connection import engine, Base
from .interface.api.routes import users
from .interface.middleware.error_handler import setup_error_handlers
from .interface.config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    await engine.dispose()

app = FastAPI(
    title="User API",
    version="1.0.0",
    lifespan=lifespan
)

# Setup middleware & error handlers
setup_error_handlers(app)

# Include routes
app.include_router(users.router)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
```

---

## Dependency Injection Pattern

### FastAPI Depends()

```python
from fastapi import Depends

# Repository dependency
def get_user_repository(session: AsyncSession = Depends(get_session)) -> IUserRepository:
    return PostgresUserRepository(session)

# Service dependency
def get_user_service(repo: IUserRepository = Depends(get_user_repository)) -> UserService:
    return UserService(repo)

# Use in route
@app.post("/users")
async def create_user(
    schema: CreateUserSchema,
    service: UserService = Depends(get_user_service)
):
    return await service.create_user(schema)
```

**Pros:**
- ✅ Automatic injection
- ✅ Request-scoped dependencies
- ✅ Type-safe

**Cons:**
- Dependencies resolved per request (use Singleton for efficiency)

### Singleton Pattern

```python
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()

@app.get("/")
async def root(settings: Settings = Depends(get_settings)):
    return {"env": settings.environment}
```

---

## Error Handling

### Domain Errors

```python
# src/domain/errors.py
class DomainError(Exception):
    code: str = 'UNKNOWN_ERROR'
    message: str = 'An error occurred'

class ValidationError(DomainError):
    code = 'VALIDATION_ERROR'

class NotFoundError(DomainError):
    code = 'NOT_FOUND'
```

### HTTP Response Mapping

```python
# src/interface/middleware/error_handler.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from ...application.services.user_service import ApplicationError

def setup_error_handlers(app: FastAPI):
    @app.exception_handler(ApplicationError)
    async def application_error_handler(request: Request, exc: ApplicationError):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "detail": exc.message,
                "code": exc.code
            }
        )

    @app.exception_handler(Exception)
    async def general_error_handler(request: Request, exc: Exception):
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )
```

---

## Testing Strategy

### Unit Test (Domain)

```python
# src/domain/usecases/__tests__/test_create_user_usecase.py
import pytest
from unittest.mock import AsyncMock
from ..create_user_usecase import CreateUserUseCase
from ...errors import ValidationError

@pytest.mark.asyncio
async def test_create_user_with_valid_email():
    mock_repo = AsyncMock()
    usecase = CreateUserUseCase(mock_repo)

    user = await usecase.execute('test@example.com', 'John')

    assert user.email == 'test@example.com'
    assert user.name == 'John'
    mock_repo.save.assert_called_once()

@pytest.mark.asyncio
async def test_create_user_with_invalid_email():
    mock_repo = AsyncMock()
    usecase = CreateUserUseCase(mock_repo)

    with pytest.raises(ValidationError):
        await usecase.execute('invalid-email', 'John')
```

### Integration Test (Infrastructure)

```python
# src/infrastructure/database/repositories/__tests__/test_user_repository.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from ...user_repository import PostgresUserRepository
from ....domain.models import User
import asyncio

@pytest.fixture
async def test_session():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    TestingSessionLocal = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with TestingSessionLocal() as session:
        yield session

    await engine.dispose()

@pytest.mark.asyncio
async def test_save_and_retrieve_user(test_session):
    repo = PostgresUserRepository(test_session)

    user = User(
        id='test-1',
        email='test@example.com',
        name='Test',
        created_at=datetime.now()
    )

    await repo.save(user)
    found = await repo.find_by_id('test-1')

    assert found.email == 'test@example.com'
```

### Handler Test (Interface)

```python
# src/interface/api/routes/__tests__/test_users.py
import pytest
from fastapi.testclient import TestClient
from ....main import app
from unittest.mock import AsyncMock, patch

client = TestClient(app)

def test_create_user_returns_201():
    with patch('src.interface.api.dependencies.get_user_service') as mock_service:
        mock_service.return_value.create_user = AsyncMock(
            return_value={
                'id': '1',
                'email': 'test@example.com',
                'name': 'John',
                'created_at': '2024-01-01T00:00:00'
            }
        )

        response = client.post(
            '/users/',
            json={'email': 'test@example.com', 'name': 'John'}
        )

        assert response.status_code == 201
        assert response.json()['email'] == 'test@example.com'
```

---

## Development Workflow

### Running the Application

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations (if using Alembic)
alembic upgrade head

# Development server (with hot reload)
uvicorn src.main:app --reload

# Production build
gunicorn src.main:app --workers 4
```

### Adding a New Feature

1. **Create domain model** (`src/domain/models.py`)
2. **Create domain interface** (`src/domain/interfaces.py`)
3. **Create use case** (`src/domain/usecases.py`)
4. **Create service** (`src/application/services/`)
5. **Create repository** (`src/infrastructure/database/repositories/`)
6. **Create schema** (`src/domain/schemas.py`)
7. **Create route** (`src/interface/api/routes/`)
8. **Write tests** (unit → integration → handler)

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Circular imports | Use absolute imports from src/; imports flow: domain ← application ← infrastructure ← interface |
| Domain logic in routes | Move to service or use case |
| Direct database queries in services | Create repository pattern |
| FastAPI imports in domain | Remove all FastAPI imports from domain/ |
| Async/await in sync function | Mark function as `async` and use `await` |
| Hard to test | Too many dependencies; use FastAPI Depends() for injection |

---

## References

- **ARCHITECTURE.md** — General layering rules
- **TEST_MATRIX.md** — Testing strategy
- **FastAPI Documentation:** https://fastapi.tiangolo.com/
- **SQLAlchemy Async:** https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- **Clean Architecture:** Robert C. Martin

---

**Status:** ✅ Complete (Phase 4)
