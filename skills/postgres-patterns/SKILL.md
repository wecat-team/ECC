---
name: postgres-patterns
description: Các pattern cơ sở dữ liệu PostgreSQL cho tối ưu query, thiết kế schema, indexing và bảo mật. Dựa trên best practice của Supabase. Dùng khi thiết kế schema, index hoặc RLS policy cho PostgreSQL, hoặc khi một query quá chậm.
metadata:
  origin: ECC
---

# PostgreSQL Patterns

Tham khảo nhanh các best practice của PostgreSQL. Để có hướng dẫn chi tiết, hãy dùng agent `database-reviewer`.

## Khi nào kích hoạt

- Viết SQL query hoặc migration
- Thiết kế database schema
- Xử lý sự cố query chậm
- Triển khai Row Level Security
- Thiết lập connection pooling

## Tham khảo nhanh

### Bảng tra cứu Index

| Pattern của query | Loại index | Ví dụ |
|--------------|------------|---------|
| `WHERE col = value` | B-tree (mặc định) | `CREATE INDEX idx ON t (col)` |
| `WHERE col > value` | B-tree | `CREATE INDEX idx ON t (col)` |
| `WHERE a = x AND b > y` | Composite | `CREATE INDEX idx ON t (a, b)` |
| `WHERE jsonb @> '{}'` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| `WHERE tsv @@ query` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| Khoảng thời gian (time-series) | BRIN | `CREATE INDEX idx ON t USING brin (col)` |

### Tham khảo nhanh kiểu dữ liệu

| Trường hợp dùng | Kiểu đúng | Nên tránh |
|----------|-------------|-------|
| ID | `bigint` | `int`, random UUID |
| Chuỗi | `text` | `varchar(255)` |
| Timestamp | `timestamptz` | `timestamp` |
| Tiền tệ | `numeric(10,2)` | `float` |
| Cờ (flag) | `boolean` | `varchar`, `int` |

### Các pattern thường gặp

**Thứ tự Composite Index:**
```sql
-- Equality columns first, then range columns
CREATE INDEX idx ON orders (status, created_at);
-- Works for: WHERE status = 'pending' AND created_at > '2024-01-01'
```

**Covering Index:**
```sql
CREATE INDEX idx ON users (email) INCLUDE (name, created_at);
-- Avoids table lookup for SELECT email, name, created_at
```

**Partial Index:**
```sql
CREATE INDEX idx ON users (email) WHERE deleted_at IS NULL;
-- Smaller index, only includes active users
```

**RLS Policy (đã tối ưu):**
```sql
CREATE POLICY policy ON orders
  USING ((SELECT auth.uid()) = user_id);  -- Wrap in SELECT!
```

**UPSERT:**
```sql
INSERT INTO settings (user_id, key, value)
VALUES (123, 'theme', 'dark')
ON CONFLICT (user_id, key)
DO UPDATE SET value = EXCLUDED.value;
```

**Cursor Pagination (phân trang bằng cursor):**
```sql
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;
-- O(1) vs OFFSET which is O(n)
```

**Xử lý queue:**
```sql
UPDATE jobs SET status = 'processing'
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

### Phát hiện anti-pattern

```sql
-- Find unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Check table bloat
SELECT relname, n_dead_tup, last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Mẫu cấu hình

```sql
-- Connection limits (adjust for RAM)
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';

-- Timeouts
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET statement_timeout = '30s';

-- Monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Security defaults
REVOKE ALL ON SCHEMA public FROM public;

SELECT pg_reload_conf();
```

## Liên quan

- Agent: `database-reviewer` - Quy trình review database đầy đủ
- Skill: `clickhouse-io` - Các pattern phân tích dữ liệu với ClickHouse
- Skill: `backend-patterns` - Các pattern cho API và backend

---

*Dựa trên Supabase Agent Skills (ghi công: đội ngũ Supabase) (MIT License)*
