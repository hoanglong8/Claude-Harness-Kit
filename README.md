# Claude Harness Kit

A comprehensive architecture framework and documentation system for building scalable, maintainable applications across multiple technology stacks.

**English** | [Tiếng Việt](#tiếng-việt)

---

## Overview

Claude Harness Kit provides a complete architectural blueprint for software development teams, including:

- **5-Layer Architecture** — Domain-Driven Design principles applied consistently
- **Stack-Specific Templates** — Production-ready patterns for Node.js/Express, Python/FastAPI, and Go/Fiber
- **Domain Guides** — Cross-stack guidance on API design, observability, security, databases, and deployment
- **Automation Scripts** — CLI tools to scaffold and validate project structure
- **CI/CD Integration** — GitHub Actions workflows for automated architecture validation

## Quick Start

### For New Projects

Initialize a new project with the Harness architecture:

```bash
# Clone this repository
git clone https://github.com/hoanglong8/Claude-Harness-Kit.git

# Use the skill to scaffold a new project
claude harness-init my-project

# Follow the interactive setup to choose your tech stack
```

### For Existing Projects

Validate your project structure against Harness rules:

```bash
# Run validation script
./scripts/validate-harness.sh

# Use --fix to auto-correct common issues
./scripts/validate-harness.sh --fix

# Use --strict to fail on warnings
./scripts/validate-harness.sh --strict
```

## Documentation Structure

### Phase 1: Core Architecture
📄 **[HARNESS_ARCHITECTURE.md](docs/HARNESS_ARCHITECTURE.md)**

The foundational architecture document explaining the 5-layer pattern:
- Domain Layer — Business logic and entities
- Application Layer — Use cases and services
- Infrastructure Layer — Data access and external integrations
- Interface Layer — HTTP handlers and middleware
- Entry Point — Application bootstrap

### Phase 2: Automation Scripts
🛠️ **[scripts/](scripts/)**

- `harness-init.skill` — CLI skill for scaffolding new projects
- `scaffold-story.sh` — Generate feature/story folder structure
- `validate-harness.sh` — Check project compliance

### Phase 3: CI/CD Integration
⚙️ **[.github/workflows/harness-check.yml](.github/workflows/harness-check.yml)**

Automated architecture validation in your GitHub Actions pipeline.

### Phase 4: Stack-Specific Templates
🔧 **[docs/stacks/](docs/stacks/)**

Complete implementation guides for each technology stack:

#### [NODEJS_EXPRESS.md](docs/stacks/NODEJS_EXPRESS.md) (616 lines)
- Project structure with TypeScript
- Dependency injection with tsyringe
- Error handling patterns
- Jest testing strategy
- Express middleware and controllers

#### [PYTHON_FASTAPI.md](docs/stacks/PYTHON_FASTAPI.md) (566 lines)
- Pydantic schemas and validation
- FastAPI dependency injection with Depends()
- SQLAlchemy async ORM
- pytest fixtures and AsyncMock
- Uvicorn server setup

#### [GO_FIBER.md](docs/stacks/GO_FIBER.md) (571 lines)
- Interfaces-first design
- GORM with context propagation
- Fiber middleware and handlers
- Table-driven tests with testify
- Connection pooling

### Phase 5: Domain Guides
📚 **[docs/](docs/)**

Cross-stack architectural guidance on critical domains:

#### [API_DESIGN.md](docs/API_DESIGN.md) (715 lines)
REST API patterns covering:
- Resource naming and versioning
- Pagination strategies (offset, cursor-based)
- Error handling with standard codes
- Rate limiting and CORS
- Idempotency and deprecation

#### [OBSERVABILITY.md](docs/OBSERVABILITY.md) (677 lines)
Production observability covering:
- Structured logging with correlation IDs
- RED metrics (Rate, Errors, Duration)
- Distributed tracing with OpenTelemetry
- Health checks (liveness vs readiness)
- Alert rules and monitoring

#### [SECURITY_POLICY.md](docs/SECURITY_POLICY.md) (606 lines)
Security best practices including:
- JWT and OAuth 2.0 authentication
- RBAC and ABAC authorization
- OWASP Top 10 vulnerability prevention
- Input validation strategies
- Secrets management

#### [DATABASE.md](docs/DATABASE.md) (612 lines)
Database design and operations:
- Schema normalization (1NF, 2NF, 3NF)
- Migration strategies and safety rules
- ACID transactions and isolation levels
- Query optimization and indexing
- Connection pooling and backups

#### [DEPLOYMENT.md](docs/DEPLOYMENT.md) (573 lines)
Production deployment patterns:
- Docker multi-stage builds
- Environment management (Dev, Staging, Prod)
- CI/CD pipelines with GitHub Actions
- Kubernetes manifests and scaling
- Blue-green and canary deployments

## Architecture Principles

### 1. Domain-Driven Design
Business logic is isolated in the Domain layer, making it testable and technology-agnostic.

### 2. Dependency Injection
Services depend on abstractions, not concrete implementations, enabling loose coupling and easy testing.

### 3. Clear Separation of Concerns
Each layer has a single responsibility:
- Domain: Business rules
- Application: Orchestration
- Infrastructure: Technical details
- Interface: HTTP concerns
- Entry: Wiring and bootstrap

### 4. Consistency Across Stacks
The same architectural pattern is implemented idiomatically in Node.js, Python, and Go, ensuring teams can switch contexts easily.

### 5. Production-Ready Patterns
All patterns include:
- Security best practices
- Error handling
- Logging and tracing
- Testing strategies
- Performance optimization

## Example: User Registration Feature

### Domain Layer
```typescript
// Node.js example
export class CreateUserUseCase {
  constructor(private userRepo: IUserRepository) {}
  
  async execute(email: string, name: string): Promise<User> {
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

### Application Layer
```typescript
export class UserService {
  constructor(
    private createUserUseCase: CreateUserUseCase,
    private logger: Logger
  ) {}
  
  async registerUser(dto: CreateUserDTO): Promise<UserResponseDTO> {
    try {
      const user = await this.createUserUseCase.execute(dto.email, dto.name);
      this.logger.info('User registered', { userId: user.id });
      return this.toResponseDTO(user);
    } catch (error) {
      this.logger.error('User registration failed', { email: dto.email, error });
      throw new ApplicationError('INTERNAL_ERROR', error.message, 500);
    }
  }
}
```

### Interface Layer
```typescript
export class UserController {
  constructor(private userService: UserService) {}
  
  async create(req: Request, res: Response) {
    try {
      const { error, value } = userSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: error.message }
        });
      }
      
      const result = await this.userService.registerUser(value);
      res.status(201).json({ data: result });
    } catch (error) {
      res.status(error.statusCode || 500).json({ error });
    }
  }
}
```

## Project Statistics

| Component | Count | Lines |
|-----------|-------|-------|
| Core Architecture | 1 | ~2,000 |
| Stack-Specific Guides | 3 | 1,753 |
| Domain Guides | 5 | 3,183 |
| Automation Scripts | 3 | ~500 |
| **Total** | **12** | **~7,500** |

## Testing Strategy

### Unit Tests
Test business logic in isolation (Domain layer):
```bash
npm test -- --testPathPattern=”domain”
```

### Integration Tests
Test layer interactions with real dependencies:
```bash
npm test -- --testPathPattern=”integration”
```

### Handler Tests
Test HTTP handlers and controllers:
```bash
npm test -- --testPathPattern=”interface”
```

## Common Workflows

### Adding a New Feature

1. Create a story folder: `./scripts/scaffold-story.sh feature-name`
2. Implement domain entities and use cases
3. Create application services and DTOs
4. Add infrastructure repositories
5. Build HTTP handlers and routes
6. Write tests at each layer
7. Validate with: `./scripts/validate-harness.sh`

### Deploying to Production

1. Build Docker image: `docker build -t myapp .`
2. Push to registry: `docker push myapp:latest`
3. Update Kubernetes: `kubectl apply -f k8s/production/`
4. Monitor health: Check `/health/ready` endpoint
5. Verify with smoke tests

### Setting Up CI/CD

1. Copy `.github/workflows/harness-check.yml` to your project
2. Configure secrets in GitHub: `DATABASE_URL`, `JWT_SECRET`, etc.
3. Push to trigger workflow
4. Check Actions tab for build status

## Contributing

This kit is designed to be extended. When adding new patterns:

1. Keep changes consistent with existing documentation
2. Provide examples in all 3 tech stacks (Node.js, Python, Go)
3. Include security and performance considerations
4. Add tests or smoke test examples
5. Update relevant guides

## References

- [REST API Design](docs/API_DESIGN.md)
- [Structured Logging & Monitoring](docs/OBSERVABILITY.md)
- [Authentication & Authorization](docs/SECURITY_POLICY.md)
- [Database Design & Optimization](docs/DATABASE.md)
- [Containerization & Deployment](docs/DEPLOYMENT.md)

## License

MIT License — See LICENSE file for details

---

# Tiếng Việt

## Tổng Quan

Claude Harness Kit cung cấp một khuôn khổ kiến trúc hoàn chỉnh cho các nhóm phát triển phần mềm, bao gồm:

- **Kiến trúc 5 lớp** — Nguyên tắc Domain-Driven Design áp dụng nhất quán
- **Mẫu theo từng Tech Stack** — Các pattern sẵn sàng cho Node.js/Express, Python/FastAPI, và Go/Fiber
- **Hướng dẫn theo Domain** — Hướng dẫn giữa các stack về thiết kế API, quan sát, bảo mật, cơ sở dữ liệu và triển khai
- **Script tự động hóa** — Công cụ CLI để tạo cấu trúc dự án và xác validate
- **Tích hợp CI/CD** — GitHub Actions workflow để xác validate kiến trúc tự động

## Bắt Đầu Nhanh

### Cho Dự Án Mới

Khởi tạo dự án mới với kiến trúc Harness:

```bash
# Clone repository
git clone https://github.com/hoanglong8/Claude-Harness-Kit.git

# Dùng skill để tạo dự án mới
claude harness-init my-project

# Làm theo setup interactif để chọn tech stack
```

### Cho Dự Án Có Sẵn

Xác validate cấu trúc dự án của bạn:

```bash
# Chạy script kiểm tra
./scripts/validate-harness.sh

# Dùng --fix để tự động sửa những vấn đề phổ biến
./scripts/validate-harness.sh --fix

# Dùng --strict để báo lỗi trên warnings
./scripts/validate-harness.sh --strict
```

## Cấu Trúc Tài Liệu

### Phase 1: Kiến Trúc Cơ Bản
📄 **[HARNESS_ARCHITECTURE.md](docs/HARNESS_ARCHITECTURE.md)**

Tài liệu kiến trúc nền tảng giải thích mô hình 5 lớp:
- Domain Layer — Logic kinh doanh và entities
- Application Layer — Use cases và services
- Infrastructure Layer — Truy cập dữ liệu và tích hợp bên ngoài
- Interface Layer — HTTP handlers và middleware
- Entry Point — Bootstrap ứng dụng

### Phase 2: Script Tự Động Hóa
🛠️ **[scripts/](scripts/)**

- `harness-init.skill` — CLI skill để tạo dự án mới
- `scaffold-story.sh` — Tạo cấu trúc folder cho feature/story
- `validate-harness.sh` — Kiểm tra tuân thủ dự án

### Phase 3: Tích Hợp CI/CD
⚙️ **[.github/workflows/harness-check.yml](.github/workflows/harness-check.yml)**

Xác validate kiến trúc tự động trong GitHub Actions pipeline.

### Phase 4: Mẫu theo Tech Stack
🔧 **[docs/stacks/](docs/stacks/)**

Hướng dẫn triển khai hoàn chỉnh cho từng stack:

#### [NODEJS_EXPRESS.md](docs/stacks/NODEJS_EXPRESS.md) (616 dòng)
- Cấu trúc dự án với TypeScript
- Dependency injection với tsyringe
- Xử lý lỗi
- Chiến lược kiểm tra Jest
- Middleware và controller Express

#### [PYTHON_FASTAPI.md](docs/stacks/PYTHON_FASTAPI.md) (566 dòng)
- Schema Pydantic và xác validate
- Dependency injection FastAPI với Depends()
- SQLAlchemy async ORM
- pytest fixtures và AsyncMock
- Setup Uvicorn server

#### [GO_FIBER.md](docs/stacks/GO_FIBER.md) (571 dòng)
- Thiết kế interfaces-first
- GORM với context propagation
- Middleware và handlers Fiber
- Kiểm tra table-driven với testify
- Connection pooling

### Phase 5: Hướng Dẫn Domain
📚 **[docs/](docs/)**

Hướng dẫn kiến trúc giữa các stack về những domain quan trọng:

#### [API_DESIGN.md](docs/API_DESIGN.md) (715 dòng)
Các pattern REST API bao gồm:
- Đặt tên resource và versioning
- Chiến lược pagination (offset, cursor-based)
- Xử lý lỗi với các mã chuẩn
- Rate limiting và CORS
- Idempotency và deprecation

#### [OBSERVABILITY.md](docs/OBSERVABILITY.md) (677 dòng)
Observability sản xuất bao gồm:
- Structured logging với correlation ID
- Metric RED (Rate, Errors, Duration)
- Distributed tracing với OpenTelemetry
- Health checks (liveness vs readiness)
- Alert rules và monitoring

#### [SECURITY_POLICY.md](docs/SECURITY_POLICY.md) (606 dòng)
Security best practices bao gồm:
- JWT và OAuth 2.0 authentication
- RBAC và ABAC authorization
- OWASP Top 10 vulnerability prevention
- Input validation strategies
- Secrets management

#### [DATABASE.md](docs/DATABASE.md) (612 dòng)
Thiết kế và vận hành cơ sở dữ liệu:
- Schema normalization (1NF, 2NF, 3NF)
- Migration strategies và safety rules
- ACID transactions và isolation levels
- Query optimization và indexing
- Connection pooling và backups

#### [DEPLOYMENT.md](docs/DEPLOYMENT.md) (573 dòng)
Các pattern triển khai sản xuất:
- Docker multi-stage builds
- Environment management (Dev, Staging, Prod)
- CI/CD pipelines với GitHub Actions
- Kubernetes manifests và scaling
- Blue-green và canary deployments

## Nguyên Tắc Kiến Trúc

### 1. Domain-Driven Design
Logic kinh doanh được cô lập trong lớp Domain, giúp nó có thể kiểm tra được và không phụ thuộc vào công nghệ.

### 2. Dependency Injection
Services phụ thuộc vào abstractions, không phải concrete implementations, cho phép loose coupling và dễ kiểm tra.

### 3. Tách Rõ Trách Nhiệm
Mỗi lớp có một trách nhiệm duy nhất:
- Domain: Business rules
- Application: Orchestration
- Infrastructure: Technical details
- Interface: HTTP concerns
- Entry: Wiring và bootstrap

### 4. Nhất Quán Giữa Các Stack
Cùng một pattern kiến trúc được triển khai theo cách tự nhiên của từng ngôn ngữ, giúp các nhóm dễ dàng chuyển đổi ngữ cảnh.

### 5. Production-Ready Patterns
Tất cả patterns bao gồm:
- Security best practices
- Error handling
- Logging và tracing
- Chiến lược kiểm tra
- Performance optimization

## Ví Dụ: Feature Đăng Ký Người Dùng

### Domain Layer
```typescript
// Node.js example
export class CreateUserUseCase {
  constructor(private userRepo: IUserRepository) {}
  
  async execute(email: string, name: string): Promise<User> {
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

### Application Layer
```typescript
export class UserService {
  constructor(
    private createUserUseCase: CreateUserUseCase,
    private logger: Logger
  ) {}
  
  async registerUser(dto: CreateUserDTO): Promise<UserResponseDTO> {
    try {
      const user = await this.createUserUseCase.execute(dto.email, dto.name);
      this.logger.info('User registered', { userId: user.id });
      return this.toResponseDTO(user);
    } catch (error) {
      this.logger.error('User registration failed', { email: dto.email, error });
      throw new ApplicationError('INTERNAL_ERROR', error.message, 500);
    }
  }
}
```

### Interface Layer
```typescript
export class UserController {
  constructor(private userService: UserService) {}
  
  async create(req: Request, res: Response) {
    try {
      const { error, value } = userSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message: error.message }
        });
      }
      
      const result = await this.userService.registerUser(value);
      res.status(201).json({ data: result });
    } catch (error) {
      res.status(error.statusCode || 500).json({ error });
    }
  }
}
```

## Thống Kê Dự Án

| Thành Phần | Số Lượng | Dòng |
|-----------|---------|------|
| Kiến Trúc Cơ Bản | 1 | ~2,000 |
| Hướng Dẫn theo Stack | 3 | 1,753 |
| Hướng Dẫn Domain | 5 | 3,183 |
| Script Tự Động Hóa | 3 | ~500 |
| **Tổng Cộng** | **12** | **~7,500** |

## Chiến Lược Kiểm Tra

### Unit Tests
Kiểm tra logic kinh doanh riêng lẻ (Domain layer):
```bash
npm test -- --testPathPattern=”domain”
```

### Integration Tests
Kiểm tra tương tác các lớp với các dependencies thực:
```bash
npm test -- --testPathPattern=”integration”
```

### Handler Tests
Kiểm tra HTTP handlers và controllers:
```bash
npm test -- --testPathPattern=”interface”
```

## Quy Trình Phổ Biến

### Thêm Feature Mới

1. Tạo story folder: `./scripts/scaffold-story.sh feature-name`
2. Triển khai domain entities và use cases
3. Tạo application services và DTOs
4. Thêm infrastructure repositories
5. Xây dựng HTTP handlers và routes
6. Viết tests ở mỗi lớp
7. Xác validate với: `./scripts/validate-harness.sh`

### Triển khai đến Sản Xuất

1. Build Docker image: `docker build -t myapp .`
2. Push lên registry: `docker push myapp:latest`
3. Update Kubernetes: `kubectl apply -f k8s/production/`
4. Giám sát health: Kiểm tra endpoint `/health/ready`
5. Xác validate với smoke tests

### Setup CI/CD

1. Copy `.github/workflows/harness-check.yml` vào dự án của bạn
2. Configure secrets trong GitHub: `DATABASE_URL`, `JWT_SECRET`, etc.
3. Push để trigger workflow
4. Kiểm tra Actions tab cho build status

## Trạng Thái Dự Án

### ✅ Hoàn Thành (2026-05-08)

**Tất cả 5 Phases đã hoàn thành với ~10,000 dòng tài liệu kiến trúc:**

| Phase | Thành Phần | Trạng Thái | Chi Tiết |
|-------|-----------|-----------|---------|
| 1 | Core Architecture | ✅ | HARNESS_ARCHITECTURE.md (~2,000 dòng) |
| 2 | Automation Scripts | ✅ | 3 scripts: harness-init.skill, scaffold-story.sh, validate-harness.sh |
| 3 | CI/CD Integration | ✅ | GitHub Actions workflow (harness-check.yml) |
| 4 | Stack Templates | ✅ | Node.js, Python, Go (1,753 dòng) |
| 5 | Domain Guides | ✅ | API, Observability, Security, Database, Deployment (3,183 dòng) |

---

## Cơ Hội Mở Rộng

Nếu muốn phát triển thêm, có thể xem xét:

### 1. **Thêm Tech Stacks Mới**
Áp dụng same 5-layer pattern cho:
- **Rust + Actix-web** — Hệ thống high-performance
- **Java + Spring Boot** — Enterprise applications
- **.NET + ASP.NET Core** — Microsoft ecosystem

### 2. **Example Repositories**
Full implementation projects theo Harness Kit pattern:
- Todo API (complete CRUD example)
- E-commerce platform (complex domain)
- Real-time chat application (async patterns)

### 3. **Interactive CLI Enhancement**
Nâng cao `harness-init.skill`:
- Project scaffolding templates
- Auto-generate domain/application layers
- Pre-configured health checks & logging

### 4. **Comprehensive Testing Guide**
Mở rộng test strategy:
- Unit testing (Vitest, pytest, Go testing)
- Integration tests (database, external APIs)
- E2E testing (Cypress, Playwright)
- Load testing (k6, JMeter)
- Contract testing (Pact)

### 5. **Monitoring & Observability Templates**
Pre-configured setups:
- **Prometheus + Grafana** dashboards
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Jaeger** distributed tracing deployment
- **Alert rules** cho common scenarios
- **SLO/SLI** definitions và tracking

### 6. **Advanced Deployment Patterns**
Mở rộng deployment guide:
- **GitOps** (ArgoCD, Flux)
- **Service mesh** (Istio, Linkerd)
- **Multi-region** deployment
- **Disaster recovery** strategies
- **Cost optimization** playbooks

### 7. **Security Hardening Playbook**
Chi tiết hơn cho:
- **Secrets rotation** automation
- **Vulnerability scanning** in CI/CD
- **Security testing** (SAST, DAST)
- **Compliance** frameworks (SOC2, ISO27001, GDPR)
- **Incident response** procedures

### 8. **Performance Optimization Guide**
Dedicated documentation:
- Query optimization patterns
- Caching strategies (Redis, CDN)
- Database indexing strategy
- Memory profiling & tuning
- Load testing & optimization

---

## Sẵn Sàng Để...

Claude-Harness-Kit hiện đã sẵn sàng để:

✅ **Sử dụng làm blueprint** cho team developers của FOXAI và clients
- Full architectural guidance across 5 layers
- Production-ready patterns tested trên real projects
- Cross-stack consistency cho easy context switching

✅ **Integrate vào onboarding process**
- New developers có comprehensive reference để học architecture
- Consistent patterns across all projects
- Faster ramp-up time cho team members

✅ **Publish lên GitHub Pages hoặc documentation site**
- Bilingual docs (English + Tiếng Việt)
- Full markdown rendering với syntax highlighting
- Easy navigation structure

✅ **Sử dụng cho client consulting**
- Provide architecture blueprint cho projects
- Implement Harness pattern implementation
- Training sessions cho development teams

✅ **Extend & customize cho specific domains**
- Healthcare systems (compliance, data security)
- Financial applications (transaction patterns, audit trails)
- E-commerce platforms (scalability, payment integration)
- Government systems (VPC compliance, digital signature)

✅ **Develop example projects**
- Implement real applications using Harness Kit
- Share case studies & best practices
- Build community around the architecture

---

## Đóng Góp

Kit này được thiết kế để có thể mở rộng. Khi thêm các pattern mới:

1. Giữ các thay đổi nhất quán với tài liệu hiện có
2. Cung cấp ví dụ trong cả 3 tech stack (Node.js, Python, Go)
3. Bao gồm security và performance considerations
4. Thêm tests hoặc smoke test examples
5. Cập nhật hướng dẫn liên quan

## Tham Khảo

- [Thiết Kế REST API](docs/API_DESIGN.md)
- [Structured Logging & Monitoring](docs/OBSERVABILITY.md)
- [Authentication & Authorization](docs/SECURITY_POLICY.md)
- [Database Design & Optimization](docs/DATABASE.md)
- [Containerization & Deployment](docs/DEPLOYMENT.md)

## Giấy Phép

MIT License — Xem file LICENSE cho chi tiết
