---
name: clickhouse-io
description: Các pattern cho cơ sở dữ liệu ClickHouse, tối ưu query, analytics và best practice về data engineering cho các workload phân tích hiệu năng cao. Dùng khi viết schema hoặc query ClickHouse, hoặc khi một analytical query quá chậm.
metadata:
  origin: ECC
---

# Các pattern Analytics với ClickHouse

Các pattern đặc thù của ClickHouse cho analytics hiệu năng cao và data engineering.

## Khi nào kích hoạt

- Thiết kế schema bảng ClickHouse (chọn engine MergeTree)
- Viết analytical query (aggregation, window function, join)
- Tối ưu hiệu năng query (partition pruning, projection, materialized view)
- Ingest khối lượng dữ liệu lớn (batch insert, tích hợp Kafka)
- Migrate từ PostgreSQL/MySQL sang ClickHouse cho analytics
- Triển khai dashboard real-time hoặc time-series analytics

## Tổng quan

ClickHouse là hệ quản trị cơ sở dữ liệu (DBMS) hướng cột cho xử lý phân tích trực tuyến (OLAP). Nó được tối ưu cho các analytical query nhanh trên tập dữ liệu lớn.

**Tính năng chính:**
- Lưu trữ hướng cột
- Nén dữ liệu
- Thực thi query song song
- Query phân tán
- Analytics real-time

## Các pattern thiết kế bảng

### MergeTree Engine (Phổ biến nhất)

```sql
CREATE TABLE markets_analytics (
    date Date,
    market_id String,
    market_name String,
    volume UInt64,
    trades UInt32,
    unique_traders UInt32,
    avg_trade_size Float64,
    created_at DateTime
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, market_id)
SETTINGS index_granularity = 8192;
```

### ReplacingMergeTree (Khử trùng lặp)

```sql
-- For data that may have duplicates (e.g., from multiple sources)
CREATE TABLE user_events (
    event_id String,
    user_id String,
    event_type String,
    timestamp DateTime,
    properties String
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (user_id, event_id, timestamp)
PRIMARY KEY (user_id, event_id);
```

### AggregatingMergeTree (Tiền tổng hợp)

```sql
-- For maintaining aggregated metrics
CREATE TABLE market_stats_hourly (
    hour DateTime,
    market_id String,
    total_volume AggregateFunction(sum, UInt64),
    total_trades AggregateFunction(count, UInt32),
    unique_users AggregateFunction(uniq, String)
) ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, market_id);

-- Query aggregated data
SELECT
    hour,
    market_id,
    sumMerge(total_volume) AS volume,
    countMerge(total_trades) AS trades,
    uniqMerge(unique_users) AS users
FROM market_stats_hourly
WHERE hour >= toStartOfHour(now() - INTERVAL 24 HOUR)
GROUP BY hour, market_id
ORDER BY hour DESC;
```

## Các pattern tối ưu query

### Lọc hiệu quả

```sql
-- PASS: GOOD: Use indexed columns first
SELECT *
FROM markets_analytics
WHERE date >= '2025-01-01'
  AND market_id = 'market-123'
  AND volume > 1000
ORDER BY date DESC
LIMIT 100;

-- FAIL: BAD: Filter on non-indexed columns first
SELECT *
FROM markets_analytics
WHERE volume > 1000
  AND market_name LIKE '%election%'
  AND date >= '2025-01-01';
```

### Aggregation

```sql
-- PASS: GOOD: Use ClickHouse-specific aggregation functions
SELECT
    toStartOfDay(created_at) AS day,
    market_id,
    sum(volume) AS total_volume,
    count() AS total_trades,
    uniq(trader_id) AS unique_traders,
    avg(trade_size) AS avg_size
FROM trades
WHERE created_at >= today() - INTERVAL 7 DAY
GROUP BY day, market_id
ORDER BY day DESC, total_volume DESC;

-- PASS: Use quantile for percentiles (more efficient than percentile)
SELECT
    quantile(0.50)(trade_size) AS median,
    quantile(0.95)(trade_size) AS p95,
    quantile(0.99)(trade_size) AS p99
FROM trades
WHERE created_at >= now() - INTERVAL 1 HOUR;
```

### Window Function

```sql
-- Calculate running totals
SELECT
    date,
    market_id,
    volume,
    sum(volume) OVER (
        PARTITION BY market_id
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_volume
FROM markets_analytics
WHERE date >= today() - INTERVAL 30 DAY
ORDER BY market_id, date;
```

## Các pattern chèn dữ liệu

### Bulk Insert (Khuyến nghị)

```typescript
import { createClient } from '@clickhouse/client'

const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL ?? 'http://localhost:8123',
  username: process.env.CLICKHOUSE_USER,
  password: process.env.CLICKHOUSE_PASSWORD
})

// PASS: Batch insert (efficient)
async function bulkInsertTrades(trades: Trade[]) {
  await clickhouse.insert({
    table: 'trades',
    values: trades.map(trade => ({
      id: trade.id,
      market_id: trade.market_id,
      user_id: trade.user_id,
      amount: trade.amount,
      timestamp: trade.timestamp.toISOString()
    })),
    format: 'JSONEachRow'
  })
}

// FAIL: Individual inserts (slow)
async function insertTrade(trade: Trade) {
  // Don't do this in a loop!
  await clickhouse.insert({
    table: 'trades',
    values: [{
      id: trade.id,
      market_id: trade.market_id,
      user_id: trade.user_id,
      amount: trade.amount,
      timestamp: trade.timestamp.toISOString()
    }],
    format: 'JSONEachRow'
  })
}
```

### Streaming Insert

```typescript
// For continuous data ingestion
import { Readable } from 'node:stream'

async function streamInserts(dataSource: AsyncIterable<Record<string, unknown>>) {
  await clickhouse.insert({
    table: 'trades',
    values: Readable.from(dataSource, { objectMode: true }),
    format: 'JSONEachRow'
  })
}
```

## Materialized View

### Aggregation real-time

```sql
-- Create materialized view for hourly stats
CREATE MATERIALIZED VIEW market_stats_hourly_mv
TO market_stats_hourly
AS SELECT
    toStartOfHour(timestamp) AS hour,
    market_id,
    sumState(amount) AS total_volume,
    countState() AS total_trades,
    uniqState(user_id) AS unique_users
FROM trades
GROUP BY hour, market_id;

-- Query the materialized view
SELECT
    hour,
    market_id,
    sumMerge(total_volume) AS volume,
    countMerge(total_trades) AS trades,
    uniqMerge(unique_users) AS users
FROM market_stats_hourly
WHERE hour >= now() - INTERVAL 24 HOUR
GROUP BY hour, market_id;
```

## Giám sát hiệu năng

### Hiệu năng query

```sql
-- Check slow queries
SELECT
    query_id,
    user,
    query,
    query_duration_ms,
    read_rows,
    read_bytes,
    memory_usage
FROM system.query_log
WHERE type = 'QueryFinish'
  AND query_duration_ms > 1000
  AND event_time >= now() - INTERVAL 1 HOUR
ORDER BY query_duration_ms DESC
LIMIT 10;
```

### Thống kê bảng

```sql
-- Check table sizes
SELECT
    database,
    table,
    formatReadableSize(sum(bytes)) AS size,
    sum(rows) AS rows,
    max(modification_time) AS latest_modification
FROM system.parts
WHERE active
GROUP BY database, table
ORDER BY sum(bytes) DESC;
```

## Các query analytics phổ biến

### Phân tích chuỗi thời gian (Time Series)

```sql
-- Daily active users
SELECT
    toDate(timestamp) AS date,
    uniq(user_id) AS daily_active_users
FROM events
WHERE timestamp >= today() - INTERVAL 30 DAY
GROUP BY date
ORDER BY date;

-- Retention analysis
SELECT
    signup_date,
    countIf(days_since_signup = 0) AS day_0,
    countIf(days_since_signup = 1) AS day_1,
    countIf(days_since_signup = 7) AS day_7,
    countIf(days_since_signup = 30) AS day_30
FROM (
    SELECT
        user_id,
        min(toDate(timestamp)) AS signup_date,
        toDate(timestamp) AS activity_date,
        dateDiff('day', signup_date, activity_date) AS days_since_signup
    FROM events
    GROUP BY user_id, activity_date
)
GROUP BY signup_date
ORDER BY signup_date DESC;
```

### Phân tích Funnel

```sql
-- Conversion funnel
SELECT
    countIf(step = 'viewed_market') AS viewed,
    countIf(step = 'clicked_trade') AS clicked,
    countIf(step = 'completed_trade') AS completed,
    round(clicked / viewed * 100, 2) AS view_to_click_rate,
    round(completed / clicked * 100, 2) AS click_to_completion_rate
FROM (
    SELECT
        user_id,
        session_id,
        event_type AS step
    FROM events
    WHERE event_date = today()
)
GROUP BY session_id;
```

### Phân tích Cohort

```sql
-- User cohorts by signup month
SELECT
    toStartOfMonth(signup_date) AS cohort,
    toStartOfMonth(activity_date) AS month,
    dateDiff('month', cohort, month) AS months_since_signup,
    count(DISTINCT user_id) AS active_users
FROM (
    SELECT
        user_id,
        min(toDate(timestamp)) OVER (PARTITION BY user_id) AS signup_date,
        toDate(timestamp) AS activity_date
    FROM events
)
GROUP BY cohort, month, months_since_signup
ORDER BY cohort, months_since_signup;
```

## Các pattern Data Pipeline

### Pattern ETL

```typescript
// Extract, Transform, Load
async function etlPipeline() {
  // 1. Extract from source
  const rawData = await extractFromPostgres()

  // 2. Transform
  const transformed = rawData.map(row => ({
    date: new Date(row.created_at).toISOString().split('T')[0],
    market_id: row.market_slug,
    volume: parseFloat(row.total_volume),
    trades: parseInt(row.trade_count)
  }))

  // 3. Load to ClickHouse
  await bulkInsertToClickHouse(transformed)
}

// Run periodically
setInterval(etlPipeline, 60 * 60 * 1000)  // Every hour
```

### Change Data Capture (CDC)

```typescript
// Listen to PostgreSQL changes and sync to ClickHouse
import { Client } from 'pg'

const pgClient = new Client({ connectionString: process.env.DATABASE_URL })

pgClient.query('LISTEN market_updates')

pgClient.on('notification', async (msg) => {
  const update = JSON.parse(msg.payload)

  await clickhouse.insert({
    table: 'market_updates',
    values: [
      {
        market_id: update.id,
        event_type: update.operation,  // INSERT, UPDATE, DELETE
        timestamp: new Date(),
        data: JSON.stringify(update.new_data)
      }
    ],
    format: 'JSONEachRow'
  })
})
```

## Best Practice

### 1. Chiến lược Partitioning
- Partition theo thời gian (thường là tháng hoặc ngày)
- Tránh quá nhiều partition (ảnh hưởng hiệu năng)
- Dùng kiểu DATE cho partition key

### 2. Ordering Key
- Đặt các cột được lọc thường xuyên nhất lên đầu
- Cân nhắc cardinality (cardinality cao đặt trước)
- Thứ tự ảnh hưởng đến nén

### 3. Kiểu dữ liệu
- Dùng kiểu nhỏ nhất phù hợp (UInt32 so với UInt64)
- Dùng LowCardinality cho các chuỗi lặp lại
- Dùng Enum cho dữ liệu phân loại

### 4. Cần tránh
- SELECT * (hãy chỉ định cột)
- FINAL (thay vào đó hãy merge dữ liệu trước khi query)
- Quá nhiều JOIN (denormalize cho analytics)
- Insert nhỏ và thường xuyên (hãy batch thay vào đó)

### 5. Giám sát
- Theo dõi hiệu năng query
- Giám sát dung lượng đĩa
- Kiểm tra các thao tác merge
- Review slow query log

**Hãy nhớ**: ClickHouse vượt trội với các workload phân tích. Hãy thiết kế bảng theo pattern query của bạn, batch insert, và tận dụng materialized view cho aggregation real-time.
