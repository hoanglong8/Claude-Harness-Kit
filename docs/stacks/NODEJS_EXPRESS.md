# Node.js + Express Architecture Guide

Implementing Harness Architecture (5-layer) in Node.js/Express projects.

---

## Project Structure

```
src/
├── domain/                    # LAYER 1: Pure business logic
│   ├── entities/
│   │   ├── User.ts           # Entity definition
│   │   └── Product.ts
│   ├── usecases/
│   │   ├── CreateUserUseCase.ts
│   │   └── GetProductUseCase.ts
│   ├── repositories/
│   │   ├── IUserRepository.ts  # Interfaces (contracts)
│   │   └── IProductRepository.ts
│   └── errors/
│       ├── ValidationError.ts
│       └── NotFoundError.ts
│
├── application/               # LAYER 2: Orchestration
│   ├── services/
│   │   ├── UserService.ts     # Service = UseCase + validation
│   │   └── ProductService.ts
│   └── dto/
│       ├── CreateUserDTO.ts
│       └── UserResponseDTO.ts
│
├── infrastructure/            # LAYER 3: External concerns
│   ├── database/
│   │   ├── connection.ts      # DB client setup
│   │   ├── migrations/
│   │   └── repositories/      # Repository implementations
│   │       ├── PostgresUserRepository.ts
│   │       └── PostgresProductRepository.ts
│   ├── http/
│   │   ├── ExternalAPIClient.ts
│   │   └── WebhookService.ts
│   ├── cache/
│   │   └── RedisCache.ts
│   └── config/
│       └── environment.ts     # .env, secrets
│
├── interface/                 # LAYER 4: Framework setup
│   ├── middleware/
│   │   ├── authMiddleware.ts
│   │   ├── errorHandler.ts
│   │   ├── validation.ts
│   │   └── logging.ts
│   ├── routes/
│   │   ├── users.ts
│   │   ├── products.ts
│   │   └── index.ts           # Route aggregation
│   ├── controllers/
│   │   ├── UserController.ts  # HTTP handlers
│   │   └── ProductController.ts
│   └── express-setup.ts       # App initialization
│
├── main.ts                    # Entry point
├── package.json
└── tsconfig.json
```

---

## Layer Implementation

### 1. Domain Layer (`src/domain/`)

**Pure business logic, no framework dependency**

```typescript
// src/domain/entities/User.ts
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

// src/domain/repositories/IUserRepository.ts
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
  delete(id: string): Promise<void>;
}

// src/domain/usecases/CreateUserUseCase.ts
export class CreateUserUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(email: string, name: string): Promise<User> {
    // Business logic only
    if (!email.includes('@')) {
      throw new ValidationError('Invalid email');
    }
    
    const user: User = {
      id: generateId(),
      email,
      name,
      createdAt: new Date(),
    };

    await this.userRepo.save(user);
    return user;
  }
}
```

**Rules:**
- No Express imports
- No database queries
- No HTTP concerns
- Throw domain errors only
- Testable without mocks

---

### 2. Application Layer (`src/application/`)

**Service orchestration, validation, error mapping**

```typescript
// src/application/services/UserService.ts
import { IUserRepository } from '../../domain/repositories/IUserRepository';
import { CreateUserUseCase } from '../../domain/usecases/CreateUserUseCase';
import { CreateUserDTO } from '../dto/CreateUserDTO';
import { UserResponseDTO } from '../dto/UserResponseDTO';

export class UserService {
  private createUserUseCase: CreateUserUseCase;

  constructor(userRepository: IUserRepository) {
    this.createUserUseCase = new CreateUserUseCase(userRepository);
  }

  async createUser(dto: CreateUserDTO): Promise<UserResponseDTO> {
    try {
      // Validate input
      if (!dto.email || !dto.name) {
        throw new Error('Email and name required');
      }

      // Execute domain logic
      const user = await this.createUserUseCase.execute(dto.email, dto.name);

      // Map to response DTO
      return {
        id: user.id,
        email: user.email,
        name: user.name,
      };
    } catch (error) {
      // Map domain errors to application errors
      if (error instanceof ValidationError) {
        throw new ApplicationError('Validation failed', 400);
      }
      throw error;
    }
  }
}

// src/application/dto/CreateUserDTO.ts
export interface CreateUserDTO {
  email: string;
  name: string;
}

export interface UserResponseDTO {
  id: string;
  email: string;
  name: string;
}
```

**Responsibilities:**
- Input validation
- Error transformation
- DTO mapping (domain ↔ presentation)
- Transaction management
- Logging & monitoring

---

### 3. Infrastructure Layer (`src/infrastructure/`)

**External service adapters**

```typescript
// src/infrastructure/database/repositories/PostgresUserRepository.ts
import { Pool } from 'pg';
import { User } from '../../../domain/entities/User';
import { IUserRepository } from '../../../domain/repositories/IUserRepository';

export class PostgresUserRepository implements IUserRepository {
  constructor(private pool: Pool) {}

  async findById(id: string): Promise<User | null> {
    const result = await this.pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async save(user: User): Promise<void> {
    await this.pool.query(
      'INSERT INTO users (id, email, name, created_at) VALUES ($1, $2, $3, $4)',
      [user.id, user.email, user.name, user.createdAt]
    );
  }

  async delete(id: string): Promise<void> {
    await this.pool.query('DELETE FROM users WHERE id = $1', [id]);
  }
}

// src/infrastructure/http/ExternalAPIClient.ts
export class PaymentAPIClient {
  constructor(private apiKey: string) {}

  async processPayment(amount: number, token: string): Promise<string> {
    const response = await fetch('https://api.payment.com/charge', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${this.apiKey}` },
      body: JSON.stringify({ amount, token }),
    });

    if (!response.ok) throw new Error('Payment failed');
    return response.json().transactionId;
  }
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

### 4. Interface Layer (`src/interface/`)

**Express routes, middleware, HTTP concerns**

```typescript
// src/interface/controllers/UserController.ts
import { Request, Response, NextFunction } from 'express';
import { UserService } from '../../application/services/UserService';

export class UserController {
  constructor(private userService: UserService) {}

  async createUser(req: Request, res: Response, next: NextFunction) {
    try {
      const dto = {
        email: req.body.email,
        name: req.body.name,
      };

      const result = await this.userService.createUser(dto);
      res.status(201).json(result);
    } catch (error) {
      next(error); // Pass to error handler
    }
  }

  async getUser(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await this.userService.getUserById(req.params.id);
      res.json(user);
    } catch (error) {
      next(error);
    }
  }
}

// src/interface/routes/users.ts
import { Router } from 'express';
import { UserController } from '../controllers/UserController';
import { validateInput } from '../middleware/validation';

export function createUserRoutes(controller: UserController): Router {
  const router = Router();

  router.post(
    '/users',
    validateInput(['email', 'name']),
    (req, res, next) => controller.createUser(req, res, next)
  );

  router.get('/users/:id', (req, res, next) =>
    controller.getUser(req, res, next)
  );

  return router;
}

// src/interface/middleware/errorHandler.ts
export function errorHandler(
  error: any,
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (error instanceof ValidationError) {
    return res.status(400).json({ error: error.message });
  }
  if (error instanceof NotFoundError) {
    return res.status(404).json({ error: error.message });
  }
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
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

### 5. Main Entry Point (`src/main.ts`)

**Dependency injection & app initialization**

```typescript
// src/main.ts
import express from 'express';
import { Pool } from 'pg';
import { PostgresUserRepository } from './infrastructure/database/repositories/PostgresUserRepository';
import { UserService } from './application/services/UserService';
import { UserController } from './interface/controllers/UserController';
import { createUserRoutes } from './interface/routes/users';
import { errorHandler } from './interface/middleware/errorHandler';
import { loggingMiddleware } from './interface/middleware/logging';

const app = express();
app.use(express.json());
app.use(loggingMiddleware);

// Infrastructure setup
const dbPool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Dependency injection
const userRepository = new PostgresUserRepository(dbPool);
const userService = new UserService(userRepository);
const userController = new UserController(userService);

// Routes
app.use('/api', createUserRoutes(userController));

// Error handling (last middleware)
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export { app, dbPool };
```

---

## Dependency Injection Pattern

### Constructor Injection (Recommended)

```typescript
class UserService {
  constructor(
    private userRepo: IUserRepository,
    private emailService: IEmailService,
    private logger: ILogger
  ) {}
}
```

**Pros:**
- ✅ Explicit dependencies
- ✅ Easy to test (just pass mocks)
- ✅ No magic

**Cons:**
- More verbose

### Container Pattern (tsyringe, inversify)

```typescript
// Register
container.registerSingleton<IUserRepository>(
  'UserRepository',
  PostgresUserRepository
);

// Inject
@injectable()
class UserService {
  constructor(
    @inject('UserRepository') private userRepo: IUserRepository
  ) {}
}
```

**Pros:**
- Less verbose
- Auto-wiring support

**Cons:**
- Hidden dependencies
- Runtime errors possible

---

## Error Handling

### Domain Errors

```typescript
// src/domain/errors/DomainError.ts
export abstract class DomainError extends Error {
  abstract code: string;
}

export class ValidationError extends DomainError {
  code = 'VALIDATION_ERROR';
  constructor(message: string) {
    super(message);
  }
}

export class NotFoundError extends DomainError {
  code = 'NOT_FOUND';
  constructor(entity: string, id: string) {
    super(`${entity} with id ${id} not found`);
  }
}
```

### HTTP Response Mapping

```typescript
// src/interface/middleware/errorHandler.ts
const errorToStatusCode: Record<string, number> = {
  VALIDATION_ERROR: 400,
  NOT_FOUND: 404,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
};

app.use((error: any, req: Request, res: Response, next: NextFunction) => {
  const status = errorToStatusCode[error.code] || 500;
  res.status(status).json({
    error: error.message,
    code: error.code,
  });
});
```

---

## Testing Strategy

### Unit Test (Domain)

```typescript
// src/domain/usecases/__tests__/CreateUserUseCase.test.ts
describe('CreateUserUseCase', () => {
  it('should create user with valid email', async () => {
    const mockRepo = {
      save: jest.fn(),
    };

    const useCase = new CreateUserUseCase(mockRepo);
    const user = await useCase.execute('test@example.com', 'John');

    expect(user.email).toBe('test@example.com');
    expect(mockRepo.save).toHaveBeenCalled();
  });

  it('should throw on invalid email', async () => {
    const useCase = new CreateUserUseCase(mockRepo);
    await expect(
      useCase.execute('invalid-email', 'John')
    ).rejects.toThrow(ValidationError);
  });
});
```

### Integration Test (Infrastructure)

```typescript
// src/infrastructure/database/repositories/__tests__/PostgresUserRepository.test.ts
describe('PostgresUserRepository', () => {
  let repo: PostgresUserRepository;
  let testPool: Pool;

  beforeAll(async () => {
    testPool = await setupTestDatabase();
    repo = new PostgresUserRepository(testPool);
  });

  it('should save and retrieve user', async () => {
    const user: User = {
      id: 'test-1',
      email: 'test@example.com',
      name: 'Test',
      createdAt: new Date(),
    };

    await repo.save(user);
    const found = await repo.findById('test-1');

    expect(found).toEqual(user);
  });
});
```

### Handler Test (Interface)

```typescript
// src/interface/controllers/__tests__/UserController.test.ts
describe('UserController', () => {
  it('should return 201 on create', async () => {
    const mockService = {
      createUser: jest.fn().mockResolvedValue({ id: '1', email: 'test@example.com' }),
    };

    const controller = new UserController(mockService);
    const req = { body: { email: 'test@example.com', name: 'John' } };
    const res = { status: jest.fn().returnThis(), json: jest.fn() };

    await controller.createUser(req as any, res as any, jest.fn());

    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalled();
  });
});
```

---

## Development Workflow

### Running the Application

```bash
# Install dependencies
npm install

# Run migrations
npm run migrate

# Development mode (with hot reload)
npm run dev

# Production build
npm run build
npm start
```

### Adding a New Feature

1. **Create domain use case** (`src/domain/usecases/`)
2. **Create service** (`src/application/services/`)
3. **Create repository implementation** (`src/infrastructure/database/repositories/`)
4. **Create controller** (`src/interface/controllers/`)
5. **Create routes** (`src/interface/routes/`)
6. **Write tests** (unit → integration → handler)

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Circular dependencies | Use interfaces (IRepository) in domain, implementations in infrastructure |
| Domain logic in controllers | Move to service or use case |
| Direct database queries in services | Create repository pattern |
| Framework imports in domain | Remove all Express/framework imports from domain/ |
| Hard to test | Too many dependencies; use DI instead |

---

## References

- **ARCHITECTURE.md** — General layering rules
- **TEST_MATRIX.md** — Testing strategy
- **Express Documentation:** https://expressjs.com/
- **Clean Architecture:** Robert C. Martin

---

**Status:** ✅ Complete (Phase 4)

