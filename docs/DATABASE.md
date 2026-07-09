# Database Guide

Schema design, migrations, transactions, indexing, and optimization patterns.

---

## Database Selection

### Relational (SQL)

**Use for:**
- Structured data with relationships
- ACID transactions required
- Complex queries/joins
- Regulated data (financial, healthcare)

**Examples:** PostgreSQL, MySQL, MariaDB, SQLite

### NoSQL

**Document (MongoDB, Firebase):**
- Flexible schema
- Nested data structures
- Horizontal scaling

**Key-Value (Redis, Memcached):**
- In-memory caching
- Sessions, tokens
- Real-time data

**Time-Series (InfluxDB, Prometheus):**
- Metrics, logs
- High write volume
- Time-ordered data

**Graph (Neo4j):**
- Relationship-heavy data
- Social networks, recommendations

**Decision:** Start with PostgreSQL (relational) for business apps. Add caching layer (Redis) if needed.

---

## Schema Design

### Normalization

**1NF (First Normal Form):** Atomic values, no repeating groups
```sql
-- ❌ Bad: Phone numbers in single column
users:
  id | name          | phones
  1  | John Doe      | 555-1234, 555-5678

-- ✅ Good: Separate table
users:
  id | name
  1  | John Doe

user_phones:
  id | user_id | phone
  1  | 1       | 555-1234
  2  | 1       | 555-5678
```

**2NF (Second Normal Form):** No partial dependencies
```sql
-- ❌ Bad: Order info in OrderItems
order_items:
  order_id | product_id | order_date | quantity

-- ✅ Good: Order info separate
orders:
  id | order_date

order_items:
  id | order_id | product_id | quantity
```

**3NF (Third Normal Form):** No transitive dependencies
```sql
-- ❌ Bad: Category name depends on CategoryID not ProductID
products:
  id | name | category_id | category_name

-- ✅ Good: Category in separate table
products:
  id | name | category_id

categories:
  id | name
```

**Rule:** Normalize to 3NF for production. Denormalize only for specific performance reasons.

### Primary Keys

```sql
-- ✅ Recommended: UUID (distributed systems)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL
);

-- ✅ Alternative: Auto-incrementing integer (monolith)
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL
);

-- ❌ Avoid: Natural keys that can change
CREATE TABLE users (
  email VARCHAR(255) PRIMARY KEY,  -- Don't do this
  name VARCHAR(255) NOT NULL
);
```

### Foreign Keys

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ON DELETE options:
-- CASCADE: Delete order if user deleted
-- SET NULL: Set user_id to NULL if user deleted
-- RESTRICT: Prevent user deletion if orders exist
-- NO ACTION: Same as RESTRICT (default)
```

### Timestamps

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Update trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();
```

### Enums

```sql
-- ✅ Good: Use ENUM for fixed values
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'pending');

CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  status user_status DEFAULT 'pending' NOT NULL
);

-- ✅ Alternative: Use CHECK constraint (more portable)
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'inactive', 'pending'))
);
```

---

## Migrations

### Migration Structure

```
migrations/
├── 001_create_users_table.sql
├── 002_create_orders_table.sql
├── 003_add_status_to_users.sql
└── 004_add_index_on_orders_user_id.sql
```

### Migration File Format

```sql
-- migrations/001_create_users_table.sql

-- UP: Applied when migrating forward
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_users_email ON users(email);

-- DOWN: Applied when rolling back
-- DROP TABLE users;
```

### Migration Tools

**Node.js:**
```bash
# TypeORM migrations
npm install -D typeorm

typeorm migration:create src/migrations/InitialSchema
typeorm migration:run
typeorm migration:revert
```

**Python:**
```bash
# Alembic migrations
pip install alembic

alembic init migrations
alembic revision --autogenerate -m "Create users table"
alembic upgrade head
alembic downgrade -1
```

**Go:**
```bash
# golang-migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

migrate -path migrations -database "postgresql://..." up
migrate -path migrations -database "postgresql://..." down 1
```

### Safety Rules

1. **One change per migration**
   ```sql
   -- ✅ Good: One migration
   CREATE TABLE users (...)
   
   -- ❌ Bad: Multiple changes
   CREATE TABLE users (...);
   CREATE TABLE orders (...);
   ALTER TABLE products ADD ...;
   ```

2. **Make migrations reversible**
   ```sql
   -- ✅ Good: DOWN rollback included
   -- UP:
   ALTER TABLE users ADD phone VARCHAR(20);
   
   -- DOWN:
   ALTER TABLE users DROP COLUMN phone;
   ```

3. **Test rollbacks locally**
   ```bash
   npm run migrate:up
   npm run migrate:down
   npm run migrate:up  # Verify works again
   ```

4. **Never modify old migrations**
   ```bash
   # ✅ Create new migration for changes
   npm run migrate:create "Add phone to users"
   
   # ❌ Don't edit old migration
   # vim src/migrations/001_create_users.sql
   ```

---

## Transactions

### ACID Properties

```
A: Atomicity  — All or nothing
C: Consistency — Valid state to valid state
I: Isolation  — Concurrent isolation
D: Durability — Persisted on disk
```

### Implementation

```typescript
// Node.js with Knex
const trx = await db.transaction();
try {
  await trx('accounts').where('id', 1).decrement('balance', 100);
  await trx('accounts').where('id', 2).increment('balance', 100);
  await trx.commit();
} catch (error) {
  await trx.rollback();
  throw error;
}
```

```python
# Python with SQLAlchemy
from sqlalchemy.orm import Session

def transfer_money(db: Session, from_id: str, to_id: str, amount: float):
    try:
        account1 = db.query(Account).filter(Account.id == from_id).with_for_update().first()
        account2 = db.query(Account).filter(Account.id == to_id).with_for_update().first()
        
        account1.balance -= amount
        account2.balance += amount
        
        db.commit()
    except Exception as e:
        db.rollback()
        raise e
```

```go
// Go with database/sql
func transferMoney(db *sql.DB, fromID, toID string, amount float64) error {
    tx, err := db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    _, err = tx.Exec("UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, fromID)
    if err != nil {
        return err
    }
    
    _, err = tx.Exec("UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, toID)
    if err != nil {
        return err
    }
    
    return tx.Commit().Error
}
```

### Isolation Levels

| Level | Dirty Read | Non-repeatable Read | Phantom Read |
|-------|---|---|---|
| **Read Uncommitted** | ✅ | ✅ | ✅ |
| **Read Committed** | ❌ | ✅ | ✅ |
| **Repeatable Read** | ❌ | ❌ | ✅ |
| **Serializable** | ❌ | ❌ | ❌ |

**Use:** REPEATABLE READ (PostgreSQL default) for most cases.

---

## Indexing

### When to Index

```sql
-- ✅ Index columns used in WHERE
CREATE INDEX idx_users_status ON users(status);
SELECT * FROM users WHERE status = 'active';

-- ✅ Index foreign keys
CREATE INDEX idx_orders_user_id ON orders(user_id);
SELECT * FROM orders WHERE user_id = $1;

-- ✅ Index for sorting (if not covered by other index)
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- ❌ Don't index small tables
CREATE INDEX ... ON countries(name);  -- Table has 200 rows

-- ❌ Don't index low cardinality columns
CREATE INDEX idx_users_gender ON users(gender);  -- Only 'M' or 'F'
```

### Composite Indexes

```sql
-- Query: WHERE user_id = ? AND created_at > ?
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);

-- This index is used for:
SELECT * FROM orders WHERE user_id = $1;
SELECT * FROM orders WHERE user_id = $1 AND created_at > $2;

-- But NOT for:
SELECT * FROM orders WHERE created_at > $1;  -- created_at not first
```

### Index Monitoring

```sql
-- Find unused indexes
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;

-- Find expensive queries
SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;

-- Check index size
SELECT indexname, pg_size_pretty(pg_relation_size(indexrelid)) 
FROM pg_stat_user_indexes 
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## Query Optimization

### EXPLAIN Plan

```sql
-- Analyze query execution
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = $1;

-- Output:
-- Seq Scan on orders (cost=0.00..1000.00)
--   Filter: (user_id = 'abc')
--   Rows: 150
-- Planning time: 0.1ms
-- Execution time: 5.2ms

-- ✅ Good: Uses index
EXPLAIN SELECT * FROM orders WHERE user_id = $1;
-- Index Scan using idx_orders_user_id (cost=0.29..8.31)
```

### N+1 Query Problem

```typescript
// ❌ Bad: N+1 queries
const orders = await Order.find();
for (const order of orders) {
  order.user = await User.findById(order.userId);  // N queries
}

// ✅ Good: Single query with JOIN
const orders = await Order.find()
  .leftJoinAndSelect("order.user", "user");

// ✅ Good: Single query with IN
const orderIds = orders.map(o => o.id);
const orders = await Order.find({ where: { id: In(orderIds) } });
const users = await User.find({ where: { id: In(userIds) } });
```

### Pagination Performance

```sql
-- ❌ Bad: OFFSET is expensive on large datasets
SELECT * FROM orders ORDER BY created_at DESC OFFSET 1000000 LIMIT 20;
-- Must scan first 1,000,020 rows

-- ✅ Good: Keyset pagination (cursor-based)
SELECT * FROM orders WHERE created_at < $1 ORDER BY created_at DESC LIMIT 20;
-- Uses index, scans only needed rows
```

---

## Connection Pooling

### Configuration

```typescript
// Node.js with Knex
const db = require('knex')({
  client: 'postgresql',
  connection: process.env.DATABASE_URL,
  pool: {
    min: 2,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  }
});
```

```python
# Python with SQLAlchemy
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Test connection before using
    pool_recycle=3600,   # Recycle connections after 1 hour
)
```

```go
// Go with database/sql
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(5 * time.Minute)
```

**Rules:**
- **pool_size:** Number of permanent connections (default 10)
- **max_overflow:** Additional connections under load (default 10)
- **idle_timeout:** Close unused connections (default 30s)

---

## Data Consistency

### Unique Constraints

```sql
-- Single column unique
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL
);

-- Composite unique (email + company_id)
CREATE TABLE team_members (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  company_id UUID NOT NULL,
  UNIQUE(user_id, company_id)
);
```

### Check Constraints

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY,
  price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
  quantity INT NOT NULL CHECK (quantity >= 0),
  status VARCHAR(20) CHECK (status IN ('active', 'inactive', 'archived'))
);
```

### Soft Deletes

```sql
-- Instead of DELETE, set deleted_at
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  deleted_at TIMESTAMP NULL
);

-- Query active users
SELECT * FROM users WHERE deleted_at IS NULL;

-- Restore user
UPDATE users SET deleted_at = NULL WHERE id = $1;
```

---

## Backup & Recovery

### Backup Strategy

```bash
# PostgreSQL: Daily full backup
pg_dump -U postgres -d mydb -F custom > backup_$(date +%Y%m%d).dump

# Restore
pg_restore -U postgres -d mydb backup_20260508.dump

# Continuous archiving (WAL)
wal_level = replica
archive_mode = on
archive_command = 'cp %p /archive/%f'
```

### Recovery Testing

1. **Weekly:** Restore from backup to test database
2. **Monthly:** Full production simulation
3. **Document:** Recovery time objective (RTO), recovery point objective (RPO)

**Example SLA:**
- RTO: 4 hours (acceptable downtime)
- RPO: 1 hour (acceptable data loss)

---

## References

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **MySQL Documentation:** https://dev.mysql.com/doc/
- **Database Design:** "Database Design Manual" by Adamski
- **Query Optimization:** Use EXPLAIN and monitoring tools

---

**Status:** ✅ Complete (Phase 5 — Part 4)
