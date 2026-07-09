# Security Policy Guide

Authentication, authorization, and defense against OWASP top 10 vulnerabilities.

---

## Authentication

### JWT (JSON Web Tokens)

**Structure:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9  # Header (algorithm, type)
.eyJzdWIiOiJ1c2VyLTEyMyIsImlhdCI6MTYyMDAwMDAwMH0  # Payload (claims)
.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ  # Signature
```

**Claims structure:**
```json
{
  "iss": "https://auth.example.com",  # Issuer
  "sub": "user-123",                   # Subject (user ID)
  "aud": "api.example.com",            # Audience
  "exp": 1620003600,                   # Expiration time
  "iat": 1620000000,                   # Issued at
  "nbf": 1620000000,                   # Not before
  "jti": "token-abc-123",              # JWT ID (for revocation)
  "role": "admin",
  "permissions": ["read:users", "write:users"]
}
```

**Implementation:**

```typescript
// Node.js with jsonwebtoken
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET;

// Create token
function createToken(userId: string, role: string) {
  return jwt.sign(
    {
      sub: userId,
      role,
      permissions: getPermissions(role)
    },
    SECRET,
    {
      expiresIn: '1h',
      issuer: 'https://auth.example.com',
      audience: 'api.example.com'
    }
  );
}

// Verify token
function verifyToken(token: string) {
  return jwt.verify(token, SECRET, {
    issuer: 'https://auth.example.com',
    audience: 'api.example.com'
  });
}
```

```python
# Python with PyJWT
import jwt
from datetime import datetime, timedelta

SECRET = os.getenv('JWT_SECRET')

def create_token(user_id: str, role: str) -> str:
    payload = {
        'sub': user_id,
        'role': role,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(hours=1),
        'iss': 'https://auth.example.com',
        'aud': 'api.example.com'
    }
    return jwt.encode(payload, SECRET, algorithm='HS256')

def verify_token(token: str) -> dict:
    return jwt.decode(
        token,
        SECRET,
        algorithms=['HS256'],
        issuer='https://auth.example.com',
        audience='api.example.com'
    )
```

```go
// Go with jwt-go
import (
    "github.com/golang-jwt/jwt/v4"
    "time"
)

type Claims struct {
    Sub         string
    Role        string
    Permissions []string
    jwt.RegisteredClaims
}

func CreateToken(userId, role string) (string, error) {
    claims := &Claims{
        Sub:  userId,
        Role: role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            Issuer:    "https://auth.example.com",
            Audience:  jwt.ClaimStrings{"api.example.com"},
        },
    }

    return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(SECRET))
}
```

### OAuth 2.0 / OpenID Connect

**For delegated authentication (third-party sign-in):**

```
┌─────────────┐                ┌──────────────────┐
│   User      │ ──────────→ │   Auth Provider    │
│             │ ← ──────────  │   (Google, etc)    │
└─────────────┘  Code+Token   └──────────────────┘
       ↓                              ↓
   Redirects to code          Issues token
       ↓                              ↓
┌─────────────────────────────────────────────┐
│ Your Application (Exchange code for token)  │
└─────────────────────────────────────────────┘
       ↓
    JWT issued to client
```

---

## Authorization

### Role-Based Access Control (RBAC)

```json
{
  "roles": {
    "admin": {
      "permissions": ["read:users", "write:users", "delete:users", "read:reports"]
    },
    "user": {
      "permissions": ["read:profile", "write:profile"]
    },
    "guest": {
      "permissions": ["read:public"]
    }
  },
  "users": {
    "user-123": { "role": "admin" },
    "user-456": { "role": "user" }
  }
}
```

**Implementation:**

```typescript
// Node.js middleware
function requirePermission(permission: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user; // From JWT
    
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    if (!user.permissions.includes(permission)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    
    next();
  };
}

app.delete('/users/:id', requirePermission('delete:users'), (req, res) => {
  // User has delete:users permission
});
```

```python
# Python FastAPI
from fastapi import Depends, HTTPException

async def require_permission(permission: str):
    async def check_permission(current_user = Depends(get_current_user)):
        if permission not in current_user.permissions:
            raise HTTPException(status_code=403, detail="Forbidden")
        return current_user
    return check_permission

@app.delete("/users/{user_id}")
async def delete_user(user_id: str, user = Depends(require_permission("delete:users"))):
    # User has delete:users permission
    pass
```

```go
// Go Fiber
func RequirePermission(permission string) fiber.Handler {
    return func(c *fiber.Ctx) error {
        user := c.Locals("user").(*User)
        
        if !hasPermission(user.Permissions, permission) {
            return c.Status(403).JSON(fiber.Map{"error": "Forbidden"})
        }
        
        return c.Next()
    }
}

app.Delete("/users/:id", RequirePermission("delete:users"), func(c *fiber.Ctx) error {
    // User has delete:users permission
    return nil
})
```

### Attribute-Based Access Control (ABAC)

**More granular: based on attributes, not just role:**

```json
{
  "policy": "grant_if(user.role == 'manager' AND resource.department == user.department AND action == 'read')",
  "context": {
    "user": {
      "id": "user-123",
      "role": "manager",
      "department": "engineering"
    },
    "resource": {
      "type": "budget",
      "department": "engineering"
    },
    "action": "read"
  }
}
```

---

## Defense Against OWASP Top 10

### 1. Injection (SQL, NoSQL, Command)

**Prevention:**
```typescript
// ❌ Bad: SQL injection
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ Good: Parameterized query
const query = 'SELECT * FROM users WHERE id = $1';
await db.query(query, [userId]);
```

```python
# ❌ Bad: String formatting
query = f"SELECT * FROM users WHERE id = {user_id}"

# ✅ Good: Parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

```go
// ❌ Bad
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)

// ✅ Good
query := "SELECT * FROM users WHERE id = $1"
db.QueryRow(query, userID)
```

**Rule:** Never concatenate user input into SQL. Always use parameterized queries.

### 2. Broken Authentication

**Prevention:**
```typescript
// ✅ Hash passwords with bcrypt
import bcrypt from 'bcrypt';

const hashedPassword = await bcrypt.hash(password, 10);
const isValid = await bcrypt.compare(inputPassword, hashedPassword);

// ✅ Enforce strong passwords
const strongPassword = /^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,}$/;
if (!strongPassword.test(password)) {
  throw new ValidationError('Password must be 8+ chars with uppercase, digit, special char');
}

// ✅ Rate limit login attempts
const loginAttempts = await redis.incr(`login_attempts:${email}`);
if (loginAttempts > 5) {
  throw new Error('Too many login attempts, try again in 15 minutes');
}
await redis.expire(`login_attempts:${email}`, 900); // 15 minutes
```

### 3. Sensitive Data Exposure

**Prevention:**
```typescript
// ✅ Use HTTPS only
app.use(require('express-enforces-ssl'));

// ✅ Don't log sensitive data
logger.info('User action', {
  userId: user.id,
  action: 'login'
  // ❌ Don't log: email, password, ssn
});

// ✅ Encrypt sensitive fields at rest
const encrypted = encrypt(ssn, process.env.ENCRYPTION_KEY);
await db.user.update({ ssn: encrypted });

// ✅ Remove sensitive data from responses
function sanitizeUser(user) {
  const { password, ssn, ...safe } = user;
  return safe;
}
```

### 4. XML External Entities (XXE)

**Prevention:**
```typescript
// ❌ Bad: Parse XML without protection
const xml = require('xml2js');
xml.parseString(userInput, (err, result) => { /* ... */ });

// ✅ Good: Disable external entities
const parser = new xml2js.Parser({
  strict: true,
  noent: false,  // Disable external entities
  async: true
});
```

### 5. Broken Access Control

**Prevention:**
```typescript
// ❌ Bad: Trust user input for ID
app.delete('/users/:id', async (req, res) => {
  await User.delete({ id: req.params.id });
});

// ✅ Good: Verify ownership
app.delete('/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  
  if (user.id !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Cannot delete other users' });
  }
  
  await user.delete();
});
```

### 6. Security Misconfiguration

**Prevention:**
```typescript
// ✅ Use security headers
app.use(helmet());

// ✅ Enable HTTPS
const https = require('https');
https.createServer(credentials, app).listen(443);

// ✅ Keep dependencies updated
// npm audit fix

// ✅ Disable debug mode in production
app.set('env', process.env.NODE_ENV || 'production');
if (process.env.NODE_ENV !== 'development') {
  app.disable('x-powered-by');
}
```

### 7. Cross-Site Scripting (XSS)

**Prevention:**
```typescript
// ❌ Bad: Direct HTML injection
app.get('/comment/:id', (req, res) => {
  const comment = await Comment.findById(req.params.id);
  res.send(`<h1>${comment.text}</h1>`); // XSS!
});

// ✅ Good: HTML escape / use templating
import xss from 'xss';
res.send(`<h1>${xss(comment.text)}</h1>`);

// ✅ Good: Use frontend framework (escapes by default)
res.json(comment); // React/Vue will escape
```

### 8. Insecure Deserialization

**Prevention:**
```typescript
// ❌ Bad: eval or Function
const obj = eval(userInput); // Never!

// ✅ Good: Parse JSON safely
const obj = JSON.parse(userInput);

// ✅ Validate before deserialization
const schema = Joi.object({
  id: Joi.string().required(),
  email: Joi.string().email().required()
});
const { error, value } = schema.validate(JSON.parse(userInput));
if (error) throw error;
```

### 9. Using Components with Known Vulnerabilities

**Prevention:**
```bash
# Check dependencies for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Review and keep updated
npm outdated
npm update
```

**Automated:**
```yaml
# GitHub dependabot (continuous updates)
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 10. Insufficient Logging & Monitoring

**Prevention:**
```typescript
// ✅ Log security events
logger.warn('Failed login attempt', {
  email,
  ipAddress,
  timestamp: new Date()
});

// ✅ Alert on suspicious activity
if (failedAttempts > 5) {
  alertSecurityTeam('Brute force attempt detected', { email, ipAddress });
}

// ✅ Monitor rate limits
if (requests > rateLimitPerHour) {
  logger.error('Rate limit exceeded', { ipAddress, endpoint });
}
```

---

## Input Validation

### Whitelist Approach (Recommended)

```typescript
// Define what's allowed
const schema = {
  email: {
    type: 'email',
    required: true
  },
  age: {
    type: 'number',
    min: 0,
    max: 150,
    required: true
  },
  status: {
    type: 'enum',
    values: ['active', 'inactive', 'pending'],
    required: true
  }
};

// Validate against schema
function validate(input, schema) {
  for (const [field, rules] of Object.entries(schema)) {
    const value = input[field];
    
    if (rules.required && !value) {
      throw new ValidationError(`${field} is required`);
    }
    
    if (rules.type === 'email' && !isValidEmail(value)) {
      throw new ValidationError(`${field} must be valid email`);
    }
    
    if (rules.min && value < rules.min) {
      throw new ValidationError(`${field} must be >= ${rules.min}`);
    }
    
    if (rules.type === 'enum' && !rules.values.includes(value)) {
      throw new ValidationError(`${field} must be one of: ${rules.values}`);
    }
  }
  
  return true;
}
```

### Libraries

- **Node.js:** `joi`, `yup`, `zod`
- **Python:** `pydantic`, `marshmallow`
- **Go:** `go-playground/validator`

---

## CORS (Cross-Origin Resource Sharing)

**Prevent unauthorized cross-origin requests:**

```typescript
// ✅ Restrict to specific origins
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// ❌ Don't allow all origins
app.use(cors({ origin: '*' })); // Dangerous!
```

---

## Environment Variables & Secrets

**Never commit secrets:**

```bash
# ✅ Store in .env (local development)
DATABASE_URL=postgresql://localhost/mydb
JWT_SECRET=your-secret-key

# ❌ Don't commit .env to git
# Add to .gitignore:
.env
.env.local
secrets/

# ✅ Use secrets manager in production
# AWS Secrets Manager, HashiCorp Vault, Google Secret Manager
```

**Accessing secrets:**

```typescript
// Node.js
const dbUrl = process.env.DATABASE_URL;

// Python
import os
db_url = os.getenv('DATABASE_URL')

// Go
dbURL := os.Getenv("DATABASE_URL")
```

---

## References

- **OWASP Top 10:** https://owasp.org/Top10/
- **OWASP Cheat Sheets:** https://cheatsheetseries.owasp.org/
- **JWT.io:** https://jwt.io/
- **NIST Cybersecurity Framework:** https://www.nist.gov/cyberframework

---

**Status:** ✅ Complete (Phase 5 — Part 3)
