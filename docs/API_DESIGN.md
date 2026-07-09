# API Design Guide

RESTful API patterns, conventions, and best practices for all tech stacks.

---

## REST Principles

### Core Rules

1. **Resources, Not Actions** — Nouns, not verbs
   ```
   ❌ POST /api/getUser
   ✅ GET /api/users/{id}
   
   ❌ POST /api/createOrder
   ✅ POST /api/orders
   ```

2. **HTTP Verbs Semantics**
   - `GET` — Retrieve resource(s), no side effects
   - `POST` — Create new resource
   - `PUT` — Replace entire resource
   - `PATCH` — Partial update
   - `DELETE` — Remove resource
   - `HEAD` — Like GET, no response body
   - `OPTIONS` — Describe communication options

3. **Status Codes Consistency**
   ```
   2xx — Success
   3xx — Redirection
   4xx — Client error
   5xx — Server error
   ```

---

## API Versioning

### URL Path Versioning (Recommended)

```
GET /api/v1/users
GET /api/v2/users      # Different response schema
```

**Pros:**
- ✅ Explicit, clear in URLs
- ✅ Cache-friendly (different paths)
- ✅ Easy to deprecate old versions

**Cons:**
- Separate code paths for each version

### Header Versioning

```
GET /api/users
  Accept-Version: v2
```

**Pros:**
- Cleaner URLs

**Cons:**
- Not immediately obvious from URL
- Less cache-friendly

### Decision Rule
**Use path versioning for major breaking changes.** Support old versions for ≥6 months, deprecate with warnings.

```
GET /api/v1/users
  Deprecation: true
  Sunset: Wed, 21 Sep 2026 07:28:00 GMT
  Link: </api/v2/users>; rel="successor-version"
```

---

## Resource Naming

### Singular vs Plural

**Use plural for collections:**
```
GET /api/users           # List all users
GET /api/users/{id}      # Get specific user
POST /api/users          # Create user
PATCH /api/users/{id}    # Update user
DELETE /api/users/{id}   # Delete user
```

### Nested Resources

**For relationships, use nesting:**
```
GET /api/users/{userId}/orders          # User's orders
GET /api/users/{userId}/orders/{orderId}  # Specific order
POST /api/users/{userId}/orders         # Create order for user
```

**Depth rule:** Max 2 levels deep. Use query params for deeper queries.
```
❌ GET /api/users/{userId}/orders/{orderId}/items/{itemId}/reviews
✅ GET /api/orders/{orderId}/items?include=reviews
```

### Query Parameters

**Filtering:**
```
GET /api/users?status=active&role=admin
GET /api/orders?created_after=2026-01-01&total_gte=100
```

**Pagination:**
```
GET /api/users?page=2&limit=50
GET /api/users?offset=100&limit=50
```

**Sorting:**
```
GET /api/users?sort=created_at:desc,name:asc
GET /api/users?sort=-created_at,+name
```

**Including Relations:**
```
GET /api/users/{id}?include=orders,profile
GET /api/orders/{id}?fields=id,total,status
```

---

## Request Format

### Headers

**Required:**
```
Content-Type: application/json
Accept: application/json
```

**Optional but Recommended:**
```
X-Request-ID: unique-trace-id      # For logging/debugging
X-Idempotency-Key: idempotency-key # For duplicate detection
User-Agent: MyApp/1.0               # Client identification
```

**Authentication:**
```
Authorization: Bearer <jwt-token>
Authorization: Basic base64(username:password)
```

### Request Body

**Use JSON, camelCase or snake_case (consistent):**

```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "metadata": {
    "source": "mobile_app",
    "version": "1.2.3"
  }
}
```

**Validation errors in request should be caught BEFORE processing:**
```javascript
// Domain layer validates email format
if (!email.includes('@')) {
  throw new ValidationError('Invalid email');
}
```

---

## Response Format

### Success Response (2xx)

**Consistent envelope:**
```json
{
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "createdAt": "2026-05-08T10:30:00Z",
    "links": {
      "self": "/api/v1/users/user-123",
      "orders": "/api/v1/users/user-123/orders"
    }
  },
  "metadata": {
    "timestamp": "2026-05-08T10:30:00Z",
    "requestId": "req-abc-123",
    "version": "1.0"
  }
}
```

**Collection response with pagination:**
```json
{
  "data": [
    { "id": "1", "email": "user1@example.com" },
    { "id": "2", "email": "user2@example.com" }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 1523,
    "hasMore": true,
    "links": {
      "self": "/api/v1/users?page=1&limit=50",
      "first": "/api/v1/users?page=1&limit=50",
      "last": "/api/v1/users?page=31&limit=50",
      "next": "/api/v1/users?page=2&limit=50"
    }
  },
  "metadata": {
    "timestamp": "2026-05-08T10:30:00Z",
    "requestId": "req-abc-123"
  }
}
```

**Status codes:**
- `200 OK` — Request succeeded, response body included
- `201 Created` — Resource created
- `202 Accepted` — Async operation accepted
- `204 No Content` — Success, no response body (DELETE usually)

### Error Response (4xx, 5xx)

**Consistent error format:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "status": 400,
    "details": {
      "field": "email",
      "value": null,
      "reason": "required field missing"
    },
    "timestamp": "2026-05-08T10:30:00Z",
    "requestId": "req-abc-123",
    "traceId": "trace-xyz-789"
  }
}
```

**Multiple validation errors:**
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Multiple validation errors",
    "status": 400,
    "errors": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Minimum 8 characters required"
      }
    ],
    "timestamp": "2026-05-08T10:30:00Z",
    "requestId": "req-abc-123"
  }
}
```

**Status codes:**
- `400 Bad Request` — Validation error, client's fault
- `401 Unauthorized` — Authentication missing/invalid
- `403 Forbidden` — Authenticated but not authorized
- `404 Not Found` — Resource doesn't exist
- `409 Conflict` — Resource conflict (duplicate, stale, etc)
- `422 Unprocessable Entity` — Valid format but semantic error
- `429 Too Many Requests` — Rate limited
- `500 Internal Server Error` — Server fault
- `503 Service Unavailable` — Temporarily down

### Error Codes (Domain-Specific)

**Standard set all services should use:**

```
VALIDATION_ERROR      — Input validation failed
NOT_FOUND             — Resource not found
CONFLICT              — Resource conflict (duplicate email, stale version)
UNAUTHORIZED          — Authentication failed
FORBIDDEN             — Authorization failed
RATE_LIMITED          — Too many requests
INVALID_STATE         — Resource state doesn't allow operation
EXTERNAL_SERVICE_ERROR — Third-party API failed
INTERNAL_ERROR        — Unexpected server error
TIMEOUT               — Request/operation timeout
```

**Usage in code:**

```typescript
// Node.js
if (!email.includes('@')) {
  throw new ApplicationError('VALIDATION_ERROR', 'Invalid email format', 400);
}

// Python
if user_exists:
    raise ApplicationError(
        code='CONFLICT',
        message='User with this email already exists',
        status_code=409
    )

// Go
if user != nil {
    return NewApplicationError(domain.ConflictError, "User already exists")
}
```

---

## Idempotency & Idempotency Keys

**For unsafe operations (POST, PUT, PATCH, DELETE), support idempotency:**

```
POST /api/orders
  X-Idempotency-Key: order-2026-05-08-user-123-1
  Content-Type: application/json

{
  "items": [{"productId": "prod-1", "quantity": 2}],
  "totalAmount": 99.99
}
```

**Behavior:**
- First request: Process normally, save result with idempotency key
- Duplicate request: Return cached result (same key within 24 hours)
- Different key: Process as new request

**Implementation:**

```typescript
// Node.js
async function createOrder(req: Request) {
  const idempotencyKey = req.headers['x-idempotency-key'];
  
  // Check if already processed
  const cached = await idempotencyCache.get(idempotencyKey);
  if (cached) return cached;
  
  // Process new request
  const order = await createOrderUseCase.execute(req.body);
  
  // Cache result
  await idempotencyCache.set(idempotencyKey, order, 24 * 60 * 60);
  
  return order;
}
```

---

## Pagination Strategies

### Offset-Based (Simple)

```
GET /api/users?offset=100&limit=50
```

**Pros:**
- ✅ Simple to implement
- ✅ Jump to any page

**Cons:**
- Inefficient for large datasets (expensive OFFSET queries)
- Unstable if data changes between requests

### Cursor-Based (Recommended)

```
GET /api/users?cursor=eyJpZCI6IDEwMH0&limit=50
```

**Cursor format (base64-encoded):**
```json
{"id": 100}
```

**Pros:**
- ✅ Efficient (uses indexed column)
- ✅ Stable (handles inserts/deletes)
- ✅ Prevents N+1 problems

**Cons:**
- Can't jump to specific page
- Slightly more complex

**Implementation:**

```typescript
// Node.js
async function getUsers(req: Request) {
  let cursor = null;
  
  if (req.query.cursor) {
    cursor = JSON.parse(Buffer.from(req.query.cursor, 'base64').toString());
  }

  const limit = parseInt(req.query.limit) || 20;
  
  // Query with cursor
  const query = cursor 
    ? Users.where('id', '>', cursor.id)
    : Users.all();
  
  const users = await query.limit(limit + 1).toArray();
  
  const hasMore = users.length > limit;
  if (hasMore) users.pop();
  
  const nextCursor = users.length > 0 
    ? Buffer.from(JSON.stringify({ id: users[users.length - 1].id })).toString('base64')
    : null;

  return {
    data: users,
    pagination: {
      limit,
      hasMore,
      nextCursor
    }
  };
}
```

---

## Rate Limiting

### Headers

```
X-RateLimit-Limit: 1000          # Max requests per window
X-RateLimit-Remaining: 998       # Requests left
X-RateLimit-Reset: 1620000000    # Unix timestamp when limit resets
Retry-After: 60                  # Seconds to wait before retrying
```

### Implementation

**Per-user limits:**
```
1000 requests per hour per authenticated user
100 requests per hour per IP (unauthenticated)
```

**Exponential backoff client strategy:**
```typescript
async function fetchWithRetry(url: string, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = await fetch(url);
    
    if (response.status !== 429) return response;
    
    const retryAfter = parseInt(response.headers.get('Retry-After')) || 60;
    const backoffMs = retryAfter * 1000 * Math.pow(2, i);
    
    await new Promise(resolve => setTimeout(resolve, backoffMs));
  }
  
  throw new Error('Max retries exceeded');
}
```

---

## CORS (Cross-Origin Resource Sharing)

### Allowed Origins

```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Credentials: true
```

### Allowed Methods

```
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

### Allowed Headers

```
Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-ID, X-Idempotency-Key
```

### Preflight Handling

```
OPTIONS /api/users
  → 200 OK
  Access-Control-Allow-Origin: https://app.example.com
  Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
```

**Configuration:**

```typescript
// Node.js/Express
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID']
}));

// Python/FastAPI
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"]
)

// Go/Fiber
app.Use(cors.New(cors.Config{
    AllowOrigins: strings.Join(allowedOrigins, ","),
    AllowCredentials: true,
    AllowMethods: "GET,POST,PUT,PATCH,DELETE,OPTIONS",
    AllowHeaders: "Content-Type,Authorization,X-Request-ID",
}))
```

---

## Deprecation Strategy

### Announcing Deprecation

```
GET /api/v1/users/old-endpoint
  Deprecation: true
  Sunset: Wed, 21 Sep 2026 07:28:00 GMT
  Link: </api/v2/users>; rel="successor-version"
  Warning: 299 - "Deprecated endpoint, use /api/v2/users instead"
```

### Timeline

1. **Month 1:** Announce deprecation via headers + documentation
2. **Month 2-6:** Support both old and new endpoints
3. **Month 7:** Remove old endpoint, return 410 Gone
4. **Month 8+:** Clean up documentation

### Sunset Header Format

```
Sunset: <HTTP-date>
```

Example:
```
Sunset: Thu, 31 Dec 2026 23:59:59 GMT
```

---

## Documentation

### OpenAPI/Swagger

**Minimal example:**

```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema: { type: integer, default: 1 }
        - name: limit
          in: query
          schema: { type: integer, default: 50 }
      responses:
        '200':
          description: Users list
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'

components:
  schemas:
    User:
      type: object
      properties:
        id: { type: string }
        email: { type: string, format: email }
        createdAt: { type: string, format: date-time }
```

**Tools:**
- Node.js: `swagger-jsdoc` + `swagger-ui-express`
- Python: `fastapi.openapi_utils` (built-in)
- Go: `swaggo/swag` or `kin-openapi`

---

## Common Patterns

### Bulk Operations

```
POST /api/users/bulk
  Content-Type: application/json

[
  { "email": "user1@example.com", "name": "User 1" },
  { "email": "user2@example.com", "name": "User 2" }
]

Response: 207 Multi-Status
{
  "results": [
    { "status": 201, "data": { "id": "1", ... } },
    { "status": 400, "error": "Invalid email" }
  ]
}
```

### Async Operations

```
POST /api/reports/generate
  → 202 Accepted

{
  "id": "report-123",
  "status": "processing",
  "statusUrl": "/api/reports/generate/report-123"
}

// Check status
GET /api/reports/generate/report-123
  → { "status": "completed", "resultUrl": "/api/reports/report-123" }
```

### Partial Success

```
DELETE /api/users/bulk?ids=1,2,3,4,5

Response: 207 Multi-Status
{
  "deleted": 4,
  "failed": 1,
  "details": [
    { "id": "1", "status": 200 },
    { "id": "5", "status": 403, "error": "Cannot delete admin users" }
  ]
}
```

---

## References

- **REST Architectural Style:** Fielding dissertation
- **HTTP Status Codes:** RFC 7231
- **OpenAPI Specification:** https://spec.openapis.org/
- **JSON:API Standard:** https://jsonapi.org/
- **GraphQL Alternative:** https://graphql.org/ (for complex queries)

---

**Status:** ✅ Complete (Phase 5 — Part 1)
