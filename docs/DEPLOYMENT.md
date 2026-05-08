# Deployment Guide

Docker containerization, CI/CD pipelines, environment management, and production deployment strategies.

---

## Containerization with Docker

### Dockerfile Best Practices

**Multi-stage builds (reduce image size):**

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Python multi-stage:**

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Go multi-stage:**

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

FROM alpine:latest
WORKDIR /app

COPY --from=builder /app/main .
EXPOSE 3000
CMD ["./main"]
```

### .dockerignore

```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.local
__pycache__
.pytest_cache
dist
build
*.log
.DS_Store
```

### Docker Compose (Local Development)

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://user:pass@db:5432/mydb
      REDIS_URL: redis://cache:6379
    depends_on:
      - db
      - cache
    volumes:
      - .:/app  # Hot reload
    command: npm run dev

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

---

## Environment Management

### Three-Tier Environment Strategy

```
┌─────────────────────────────────────┐
│ Development (Local)                 │
│ • Fast feedback loop                │
│ • Real database, test data          │
│ • Logs at DEBUG level               │
│ • No rate limiting                  │
└─────────────────────────────────────┘
          ↓
┌─────────────────────────────────────┐
│ Staging                             │
│ • Mirror production setup           │
│ • Real external APIs                │
│ • Logs at INFO level                │
│ • Rate limiting enabled             │
│ • Load testing approved             │
└─────────────────────────────────────┘
          ↓
┌─────────────────────────────────────┐
│ Production                          │
│ • High availability (HA)            │
│ • Database replication              │
│ • Logs at WARN/ERROR only           │
│ • All security measures             │
│ • Monitoring & alerting active      │
└─────────────────────────────────────┘
```

### Environment Variables

**Required (no defaults):**
```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=super-secret-key-min-32-chars
```

**Optional (with defaults):**
```bash
LOG_LEVEL=info
PORT=3000
REDIS_URL=redis://localhost:6379
NODE_ENV=production
```

**Loading strategy:**

```typescript
// Node.js
import dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.NODE_ENV || 'development'}` });

const config = {
  database: {
    url: process.env.DATABASE_URL || 'postgresql://localhost/mydb',
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRY || '1h',
  },
  port: parseInt(process.env.PORT || '3000'),
  env: process.env.NODE_ENV || 'development',
};

if (!config.jwt.secret) {
  throw new Error('JWT_SECRET environment variable is required');
}

export default config;
```

```python
# Python
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    JWT_SECRET: str
    LOG_LEVEL: str = 'info'
    PORT: int = 8000
    REDIS_URL: str = 'redis://localhost:6379'
    
    class Config:
        env_file = f'.env.{os.getenv("ENVIRONMENT", "development")}'
        case_sensitive = True

settings = Settings()
```

```go
// Go
package config

import (
    "log"
    "os"
    "strconv"
)

type Config struct {
    DatabaseURL string
    JWTSecret   string
    LogLevel    string
    Port        int
    RedisURL    string
}

func Load() *Config {
    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        log.Fatal("DATABASE_URL environment variable is required")
    }
    
    jwtSecret := os.Getenv("JWT_SECRET")
    if jwtSecret == "" {
        log.Fatal("JWT_SECRET environment variable is required")
    }
    
    port, _ := strconv.Atoi(getEnv("PORT", "3000"))
    
    return &Config{
        DatabaseURL: dbURL,
        JWTSecret:   jwtSecret,
        LogLevel:    getEnv("LOG_LEVEL", "info"),
        Port:        port,
        RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379"),
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

### Secrets Management

**For local development:**
```bash
# .env (local, not committed)
DATABASE_URL=postgresql://localhost/mydb
JWT_SECRET=dev-secret-key
```

**For production (use secrets manager):**

```bash
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id myapp/db-url --query SecretString

# HashiCorp Vault
vault kv get secret/myapp/jwt-secret

# Google Secret Manager
gcloud secrets versions access latest --secret=myapp-jwt-secret

# Kubernetes Secrets
kubectl get secret myapp-secrets -o jsonpath={.data.jwt_secret} | base64 -d
```

**Application code:**

```typescript
// Node.js with AWS
import AWS from 'aws-sdk';

async function getSecret(secretName: string): Promise<string> {
  const client = new AWS.SecretsManager({ region: 'us-east-1' });
  const result = await client.getSecretValue({ SecretId: secretName }).promise();
  return result.SecretString || '';
}

const jwtSecret = await getSecret('myapp/jwt-secret');
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npm run lint
      
      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
      
      - name: Build
        run: npm run build

  build-and-push:
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy to production
        run: |
          # Deploy to Kubernetes, ECS, App Engine, etc.
          kubectl set image deployment/myapp \
            myapp=ghcr.io/${{ github.repository }}:latest \
            --namespace=production
```

### Deployment Stages

**1. Code Quality Checks**
```yaml
lint:
  run: npm run lint
  
type-check:
  run: npm run type-check
  
security-audit:
  run: npm audit --production
```

**2. Testing**
```yaml
unit-tests:
  run: npm test -- --coverage
  
integration-tests:
  run: npm run test:integration
  
e2e-tests:
  run: npm run test:e2e
  services:
    - postgres
    - redis
```

**3. Build**
```yaml
build:
  run: npm run build
  artifacts:
    - dist/
```

**4. Container Image**
```yaml
docker-build:
  run: docker build -t myapp:${{ github.sha }} .
  
docker-push:
  run: docker push myapp:${{ github.sha }}
```

**5. Deploy**
```yaml
deploy-staging:
  if: pull_request
  run: kubectl apply -f k8s/staging/ --selector version=pr-${{ github.event.number }}

deploy-production:
  if: main branch
  run: kubectl apply -f k8s/production/ --selector version=${{ github.sha }}
  requires:
    - smoke-tests-passed
```

### Pre-deployment Checks

```bash
# Health check
curl -f http://localhost:3000/health/ready || exit 1

# Database migrations
npm run migrate:up

# Cache warm-up
curl -X POST http://localhost:3000/admin/cache/warm

# Smoke tests
npm run test:smoke
```

---

## Kubernetes Deployment

### Manifest Structure

```
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── development/
│   │   ├── kustomization.yaml
│   │   └── patch-*.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patch-*.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── patch-*.yaml
```

### Deployment Manifest

```yaml
# k8s/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        
        env:
        - name: NODE_ENV
          value: production
        - name: PORT
          value: "3000"
        
        envFrom:
        - configMapRef:
            name: myapp-config
        - secretRef:
            name: myapp-secrets
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
```

### Service Manifest

```yaml
# k8s/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: myapp
  sessionAffinity: None
```

### ConfigMap & Secrets

```yaml
# k8s/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  LOG_LEVEL: "info"
  ENVIRONMENT: "production"
```

```bash
# Create secrets from literal
kubectl create secret generic myapp-secrets \
  --from-literal=JWT_SECRET=your-secret-key \
  --from-literal=DATABASE_URL=postgresql://... \
  -n production

# Or from file
kubectl create secret generic myapp-secrets \
  --from-file=.env.production \
  -n production
```

---

## Scaling Strategy

### Horizontal Scaling

```
Load Balancer
    ↓
  ┌─────────────────┐
  │ Kubernetes      │
  │ ReplicaSet: 3   │
  ├─────────────────┤
  │ Pod 1           │ ← 1000 req/s
  │ Pod 2           │ ← 1000 req/s
  │ Pod 3           │ ← 1000 req/s
  └─────────────────┘
     ↓
  Database (connection pool)
```

**Horizontal Pod Autoscaler:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Scaling

**Increase per-pod resources:**

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

---

## Blue-Green Deployment

### Strategy

```
┌───────────────────┐         ┌───────────────────┐
│ Blue (Current)    │         │ Green (New)       │
│ v1.2.3            │         │ v1.2.4            │
│ 100% traffic      │ ──→     │ 0% traffic        │
└───────────────────┘         └───────────────────┘
        ↓
   (all tests pass on green)
        ↓
┌───────────────────┐         ┌───────────────────┐
│ Blue (Current)    │         │ Green (New)       │
│ v1.2.3            │         │ v1.2.4            │
│ 0% traffic        │ ←──     │ 100% traffic      │
└───────────────────┘         └───────────────────┘
        ↓
   (rollback instantly if needed)
```

**Implementation:**

```bash
# Deploy new version to green
kubectl apply -f k8s/green/

# Run smoke tests on green
curl http://green.myapp.example.com/health/ready

# Switch traffic
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# Verify
curl http://myapp.example.com/ # Should return v1.2.4

# Cleanup old version
kubectl delete deployment myapp-blue
```

---

## Canary Deployment

### Gradual Traffic Shift

```
           Users
             ↓
    (80% old, 20% new)
    ┌──────────────┐
    │ Service Mesh │ (Istio/Linkerd)
    └──────────────┘
     ↙            ↘
┌────────┐    ┌────────┐
│Blue v1 │    │Green v2│
│80% req │    │20% req │
└────────┘    └────────┘
    ↓              ↓
  Logs    &    Metrics
     ↓
Error Rate: 2% (acceptable)
Latency: +10ms (acceptable)
  ↓
Shift: 50/50 → 90/10 → 0/100
```

**Istio VirtualService:**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: myapp
        subset: v1
      weight: 80
    - destination:
        host: myapp
        subset: v2
      weight: 20
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
```

---

## Monitoring Deployment

### Key Metrics to Track

```
Deployment Phase:
  • Build time (target: < 5 min)
  • Test pass rate (target: 100%)
  • Image size (target: < 200MB)
  • Container startup time (target: < 10s)

Post-Deployment:
  • Error rate (target: < 0.1%)
  • Latency p99 (target: < 500ms)
  • CPU usage (target: < 70%)
  • Memory usage (target: < 80%)
  • Disk usage (target: < 80%)
```

### Health Checks Post-Deployment

```bash
#!/bin/bash
# deploy-health-check.sh

ENDPOINT="https://api.example.com"
TIMEOUT=600  # 10 minutes
INTERVAL=5   # Check every 5 seconds

elapsed=0
while [ $elapsed -lt $TIMEOUT ]; do
  # Liveness check
  if ! curl -f $ENDPOINT/health/live > /dev/null 2>&1; then
    echo "❌ Liveness check failed"
    exit 1
  fi
  
  # Readiness check
  if ! curl -f $ENDPOINT/health/ready > /dev/null 2>&1; then
    echo "⚠️  Not ready yet, waiting..."
    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
    continue
  fi
  
  # Smoke test
  if curl -f -X GET $ENDPOINT/api/users?limit=1 > /dev/null 2>&1; then
    echo "✅ Deployment successful"
    exit 0
  fi
  
  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
done

echo "❌ Deployment health check timeout"
exit 1
```

---

## Rollback Strategy

### Automatic Rollback on Errors

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  progressDeadlineSeconds: 600  # 10 minutes
```

**Manual rollback:**

```bash
# View rollout history
kubectl rollout history deployment/myapp

# Rollback to previous version
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=3

# Verify
kubectl rollout status deployment/myapp
```

---

## Cost Optimization

### Resource Right-Sizing

**Before:**
```yaml
resources:
  requests:
    memory: "1Gi"      # Over-provisioned
    cpu: "1000m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

**After (monitor and adjust):**
```yaml
resources:
  requests:
    memory: "256Mi"    # Actual usage: ~150Mi
    cpu: "250m"        # Actual usage: ~80m
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Spot Instances / Preemptible VMs

**Kubernetes node pool with spot instances:**

```yaml
apiVersion: cloud.google.com/v1
kind: GKENodePool
metadata:
  name: spot-pool
spec:
  nodeCount: 5
  machineType: e2-medium
  diskSizeGb: 50
  preemptible: true  # Google Cloud
  # or
  # spotPrice: true  # AWS
```

---

## References

- **Docker Documentation:** https://docs.docker.com/
- **Kubernetes Documentation:** https://kubernetes.io/docs/
- **GitHub Actions:** https://docs.github.com/en/actions
- **Twelve-Factor App:** https://12factor.net/
- **Heroku Deployment:** https://devcenter.heroku.com/
- **AWS ECS:** https://docs.aws.amazon.com/ecs/
- **Google Cloud Run:** https://cloud.google.com/run/docs

---

**Status:** ✅ Complete (Phase 5 — Part 5)
