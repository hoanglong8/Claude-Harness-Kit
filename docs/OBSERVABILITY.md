# Observability Guide

Logging, metrics, tracing, and monitoring patterns for production systems.

---

## Observability Pillars

```
┌─────────────────────────────────┐
│    Observability (Observing)    │
├─────────────────────────────────┤
│ Logs    │ Metrics  │ Traces     │
│ What    │ How much │ Where      │
│ Text    │ Numbers  │ Causality  │
└─────────────────────────────────┘
```

---

## Logging

### Log Levels

| Level | Use Case | Examples |
|-------|----------|----------|
| **ERROR** | Failures, exceptions | Failed DB query, external API error |
| **WARN** | Unexpected but recoverable | Retry attempt, deprecated feature |
| **INFO** | Important events | User login, order created, deployment |
| **DEBUG** | Development details | Variable values, function entry/exit |
| **TRACE** | Verbose debugging | Loop iterations, pointer values |

**Production rule:** Only log ERROR and INFO in production. DEBUG/TRACE in local development only.

### Structured Logging

**Bad (unstructured):**
```
2026-05-08 10:30:45 User login failed for user123 from IP 192.168.1.1
```

**Good (structured):**
```json
{
  "timestamp": "2026-05-08T10:30:45.123Z",
  "level": "ERROR",
  "message": "User login failed",
  "userId": "user123",
  "ipAddress": "192.168.1.1",
  "requestId": "req-abc-123",
  "traceId": "trace-xyz-789",
  "error": {
    "type": "AuthenticationError",
    "code": "INVALID_PASSWORD",
    "message": "Password mismatch"
  },
  "service": "auth-service",
  "version": "1.0.0"
}
```

**Benefits:**
- ✅ Searchable and queryable
- ✅ Correlates with metrics & traces
- ✅ Aggregatable across services

### Implementation

```typescript
// Node.js with Winston
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  defaultMeta: {
    service: 'user-service',
    version: '1.0.0'
  },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

logger.error('Login failed', {
  userId: 'user123',
  ipAddress: req.ip,
  requestId: req.headers['x-request-id'],
  error: {
    type: error.constructor.name,
    code: error.code,
    message: error.message
  }
});
```

```python
# Python with structlog
import structlog

logger = structlog.get_logger()

logger.error(
    'login_failed',
    user_id='user123',
    ip_address=request.ip,
    request_id=request.headers.get('X-Request-ID'),
    error={
        'type': type(error).__name__,
        'code': error.code,
        'message': str(error)
    }
)
```

```go
// Go with zap
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Error(
    "login_failed",
    zap.String("user_id", "user123"),
    zap.String("ip_address", r.RemoteAddr),
    zap.String("request_id", r.Header.Get("X-Request-ID")),
    zap.String("error_type", fmt.Sprintf("%T", err)),
    zap.String("error_message", err.Error()),
)
```

### Log Aggregation

**Send logs to:**
- Elasticsearch + Kibana
- Datadog
- CloudWatch (AWS)
- Stackdriver (GCP)
- Splunk
- ELK Stack (self-hosted)

**Indexing:**
```json
{
  "timestamp": "2026-05-08T10:30:45.123Z",
  "level": "ERROR",
  "service": "user-service",        # Index: filter by service
  "userId": "user123",               # Index: correlate events by user
  "requestId": "req-abc-123",        # Index: trace request path
  "message": "Login failed"           # Full-text search
}
```

---

## Metrics

### Key Metrics (RED)

| Metric | Measure | Unit |
|--------|---------|------|
| **Rate** | Requests per second | req/s |
| **Errors** | Failed requests | % or count |
| **Duration** | Latency (p50, p99) | ms |

### Application Metrics

```
http_requests_total{service="user-service", method="POST", path="/login", status="200"} 1523
http_request_duration_ms{service="user-service", method="POST", path="/login"} [10, 15, 12, 18, ...]
db_query_duration_ms{service="user-service", operation="SELECT", table="users"} [5, 8, 6, 9, ...]
cache_hit_ratio{service="user-service", cache="redis"} 0.95
```

### System Metrics

```
cpu_usage_percent 45.2
memory_usage_mb 512
disk_usage_percent 78
network_io_bytes_in 1024000
network_io_bytes_out 512000
```

### Implementation

```typescript
// Node.js with Prometheus
import prometheus from 'prom-client';

const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'path', 'status'],
  buckets: [10, 50, 100, 500, 1000, 5000]
});

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDuration
      .labels(req.method, req.path, res.statusCode)
      .observe(duration);
  });
  next();
});
```

```python
# Python with Prometheus client
from prometheus_client import Histogram, Counter
import time

request_duration = Histogram(
    'http_request_duration_ms',
    'Duration of HTTP requests in ms',
    ['method', 'path', 'status'],
    buckets=[10, 50, 100, 500, 1000, 5000]
)

@app.middleware("http")
async def track_metrics(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = (time.time() - start) * 1000
    
    request_duration.labels(
        method=request.method,
        path=request.url.path,
        status=response.status_code
    ).observe(duration)
    
    return response
```

```go
// Go with Prometheus
import "github.com/prometheus/client_golang/prometheus"

var (
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_ms",
            Help:    "HTTP request duration in milliseconds",
            Buckets: []float64{10, 50, 100, 500, 1000, 5000},
        },
        []string{"method", "path", "status"},
    )
)

func trackMetrics(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        sw := &statusWriter{ResponseWriter: w}
        
        next.ServeHTTP(sw, r)
        
        duration := float64(time.Since(start).Milliseconds())
        requestDuration.WithLabelValues(
            r.Method,
            r.URL.Path,
            strconv.Itoa(sw.status),
        ).Observe(duration)
    })
}
```

### Metrics Visualization

**Grafana dashboard:**
```
┌─────────────────────────────────────┐
│ Service: user-service               │
├─────────────────────────────────────┤
│ Requests/s │ Error Rate │ Latency(p99)│
│    150     │    2%      │     45ms    │
├─────────────────────────────────────┤
│ ┌─ HTTP Requests (last 1h)         │
│ │ [=========]                        │
├─────────────────────────────────────┤
│ ┌─ Response Time Distribution       │
│ │ 100ms ████████ 75% < 100ms        │
│ │  200ms ████ 20%                    │
│ │  500ms ██ 5%                       │
└─────────────────────────────────────┘
```

---

## Tracing

### Distributed Tracing

**Track request flow across services:**

```
User Request
  └─ API Gateway (span: 10ms)
      └─ Auth Service (span: 5ms)
          └─ User Service (span: 20ms)
              └─ Database Query (span: 8ms)
              └─ Cache Query (span: 2ms)
          └─ Notification Service (span: 3ms)
```

**Trace structure:**
```json
{
  "traceId": "trace-xyz-789",           # Unique across all services
  "spans": [
    {
      "spanId": "span-1",
      "parentSpanId": null,
      "operation": "POST /login",
      "service": "api-gateway",
      "startTime": 1620000000000,
      "endTime": 1620000000010,
      "duration": 10,
      "tags": {
        "http.method": "POST",
        "http.path": "/login",
        "http.status": 200
      },
      "logs": [
        { "timestamp": 1620000000001, "event": "Request received" },
        { "timestamp": 1620000000009, "event": "Response sent" }
      ]
    },
    {
      "spanId": "span-2",
      "parentSpanId": "span-1",
      "operation": "authenticate",
      "service": "auth-service",
      "startTime": 1620000000001,
      "endTime": 1620000000006,
      "duration": 5
    }
  ]
}
```

### Implementation

```typescript
// Node.js with OpenTelemetry
import { BasicTracerProvider } from '@opentelemetry/sdk-trace-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';

const jaegerExporter = new JaegerExporter({
  endpoint: 'http://localhost:14268/api/traces',
});

const tracerProvider = new BasicTracerProvider();
tracerProvider.addSpanProcessor(new BatchSpanProcessor(jaegerExporter));

const tracer = tracerProvider.getTracer('user-service');

app.use((req, res, next) => {
  const span = tracer.startSpan(`${req.method} ${req.path}`);
  
  span.setAttributes({
    'http.method': req.method,
    'http.path': req.path,
    'http.client_ip': req.ip
  });
  
  res.on('finish', () => {
    span.setAttributes({ 'http.status': res.statusCode });
    span.end();
  });
  
  next();
});
```

```python
# Python with OpenTelemetry
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",
    agent_port=6831,
)

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

tracer = trace.get_tracer(__name__)

@app.middleware("http")
async def trace_middleware(request, call_next):
    with tracer.start_as_current_span(f"{request.method} {request.url.path}") as span:
        span.set_attribute("http.method", request.method)
        span.set_attribute("http.path", request.url.path)
        
        response = await call_next(request)
        
        span.set_attribute("http.status", response.status_code)
        return response
```

```go
// Go with OpenTelemetry
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/trace"
)

exp, _ := jaeger.New(jaeger.WithAgentHost("localhost"))
tp := trace.NewTracerProvider(trace.WithBatcher(exp))
otel.SetTracerProvider(tp)

tracer := otel.Tracer("user-service")

func traceMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        ctx, span := tracer.Start(r.Context(), fmt.Sprintf("%s %s", r.Method, r.URL.Path))
        defer span.End()
        
        span.SetAttributes(
            attribute.String("http.method", r.Method),
            attribute.String("http.path", r.URL.Path),
        )
        
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

### Tracing Tools

- **Jaeger** (self-hosted)
- **Zipkin** (self-hosted)
- **DataDog APM** (SaaS)
- **New Relic** (SaaS)
- **AWS X-Ray** (SaaS)

---

## Correlation IDs

**Connect logs, metrics, traces across all layers:**

```
Client Request
  ↓ Header: X-Request-ID: req-abc-123
  
API Gateway (log: req-abc-123)
  ↓ Header: X-Request-ID: req-abc-123
  
User Service (log: req-abc-123)
  ↓ Header: X-Request-ID: req-abc-123
  
Database Query (log: req-abc-123)
```

### Implementation

```typescript
// Node.js Express middleware
import { v4 as uuidv4 } from 'uuid';

app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] || uuidv4();
  req.id = requestId;
  res.setHeader('X-Request-ID', requestId);
  
  // Inject into logger context
  req.log = logger.child({ requestId });
  
  next();
});

// In route handler
app.get('/users/:id', (req, res) => {
  req.log.info('Fetching user', { userId: req.params.id });
  // All logs now have requestId automatically
});
```

```python
# Python FastAPI
from uuid import uuid4
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar('request_id')

@app.middleware("http")
async def add_request_id(request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid4()))
    request_id_var.set(request_id)
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response

# In route
@app.get("/users/{user_id}")
async def get_user(user_id: str):
    request_id = request_id_var.get()
    logger.info("Fetching user", extra={"request_id": request_id})
```

```go
// Go Fiber
import "github.com/google/uuid"

app.Use(func(c *fiber.Ctx) error {
    requestID := c.Get("X-Request-ID")
    if requestID == "" {
        requestID = uuid.New().String()
    }
    
    c.Set("X-Request-ID", requestID)
    c.Locals("requestId", requestID)
    
    return c.Next()
})

// In handler
func GetUser(c *fiber.Ctx) error {
    requestID := c.Locals("requestId").(string)
    logger.Infof("Fetching user [%s]", requestID)
}
```

---

## Alerting

### Alert Rules

**Define thresholds that trigger notifications:**

```yaml
# Prometheus alert rules
groups:
  - name: service_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate is {{ $value }} (5-min average)"
      
      - alert: HighLatency
        expr: histogram_quantile(0.99, http_request_duration_ms) > 500
        for: 10m
        annotations:
          summary: "High latency on {{ $labels.service }}"
          description: "p99 latency is {{ $value }}ms"
      
      - alert: DatabaseDown
        expr: pg_up == 0
        for: 1m
        annotations:
          summary: "Database is down"
```

### Notification Channels

Send alerts to:
- **PagerDuty** — Oncall escalation
- **Slack** — Team notification
- **Email** — Persistent log
- **SMS** — Critical alerts only

**Example:**
```
Alert: HighErrorRate
Service: user-service
Threshold: Error rate > 5%
Actual: 8.2%
Duration: 5+ minutes
Action: Check logs, restart if needed
```

---

## Health Checks

### Liveness vs Readiness

```
┌──────────────────────────────────┐
│     Application Health          │
├──────────────────────────────────┤
│ Liveness   │ Process running?     │
│            │ Can we restart it?   │
├──────────────────────────────────┤
│ Readiness  │ All dependencies OK? │
│            │ Can we route traffic?│
└──────────────────────────────────┘
```

### Implementation

```typescript
// Node.js Express
app.get('/health/live', (req, res) => {
  // Simple check: app is running
  res.json({ status: 'alive' });
});

app.get('/health/ready', async (req, res) => {
  try {
    // Check all dependencies
    await db.query('SELECT 1');
    await cache.ping();
    
    res.json({
      status: 'ready',
      checks: {
        database: 'ok',
        cache: 'ok'
      }
    });
  } catch (error) {
    res.status(503).json({
      status: 'not_ready',
      error: error.message
    });
  }
});
```

```python
# Python FastAPI
@app.get("/health/live")
async def liveness():
    return {"status": "alive"}

@app.get("/health/ready")
async def readiness(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ready", "checks": {"database": "ok"}}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))
```

```go
// Go Fiber
app.Get("/health/live", func(c *fiber.Ctx) error {
    return c.JSON(fiber.Map{"status": "alive"})
})

app.Get("/health/ready", func(c *fiber.Ctx) error {
    if err := db.Ping(c.Context()); err != nil {
        return c.Status(503).JSON(fiber.Map{"error": err.Error()})
    }
    return c.JSON(fiber.Map{"status": "ready"})
})
```

---

## References

- **OpenTelemetry:** https://opentelemetry.io/
- **Prometheus:** https://prometheus.io/
- **Grafana:** https://grafana.com/
- **ELK Stack:** https://www.elastic.co/
- **Google SRE Book:** https://sre.google/sre-book/

---

**Status:** ✅ Complete (Phase 5 — Part 2)
