---
name: mysql-patterns
description: Các pattern về schema, truy vấn, indexing, transaction, replication và connection pool của MySQL và MariaDB cho backend production. Dùng khi thiết kế schema và index cho MySQL hoặc MariaDB, hoặc khi một truy vấn, transaction hay replica bị lag.
metadata:
  origin: ECC
---

# MySQL Patterns

Dùng skill này khi làm việc với thiết kế schema, migration, điều tra slow query,
transaction kiểu queue, connection pool hoặc cấu hình database production của
MySQL hoặc MariaDB. Nên kiểm tra phiên bản chính xác trước khi áp dụng một
pattern riêng cho từng tính năng vì MySQL và MariaDB đã khác nhau ở nhiều chi tiết
SQL.

## Kích hoạt

- Thiết kế bảng, index và constraint cho MySQL hoặc MariaDB
- Review migration trước khi chạy trên các bảng production lớn
- Debug slow query, lock wait, deadlock hoặc cạn kiệt connection
- Thêm keyset pagination, upsert, full-text search, cột JSON hoặc queue
- Cấu hình connection pool của ứng dụng, read replica, TLS hoặc slow log

## Kiểm tra phiên bản

Bắt đầu bằng việc xác định engine và phiên bản:

```sql
SELECT VERSION();
SHOW VARIABLES LIKE 'version_comment';
```

Giữ hướng dẫn cho MySQL và MariaDB tách biệt khi cú pháp khác nhau:

- MySQL ghi tài liệu row alias là sự thay thế cho `VALUES(col)` trong
  `ON DUPLICATE KEY UPDATE`; `VALUES(col)` bị deprecated ở đó.
- MariaDB ghi tài liệu `VALUES(col)` là cách được hỗ trợ để tham chiếu các giá trị
  được chèn trong `ON DUPLICATE KEY UPDATE`; dùng nó để tương thích giữa các engine.
- `SKIP LOCKED` chỉ phù hợp cho công việc kiểu queue. Nó bỏ qua các dòng bị khóa
  và có thể trả về một góc nhìn không nhất quán, nên đừng dùng nó cho các lần đọc
  kế toán chung hoặc nhạy cảm với tính toàn vẹn.

## Mặc định của Schema

```sql
CREATE TABLE orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(32) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_orders_account_status_created (account_id, status, created_at),
    KEY idx_orders_active (account_id, deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Các lựa chọn mặc định:

| Trường hợp dùng | Nên dùng | Tránh |
| --- | --- | --- |
| Surrogate primary key | `BIGINT UNSIGNED AUTO_INCREMENT` | `INT` cho các bảng có thể vượt quá 2 tỷ dòng |
| UUID lookup key | `BINARY(16)` kèm helper chuyển đổi | Primary key `VARCHAR(36)` trên các bảng nóng |
| Tiền và số lượng chính xác | `DECIMAL(p, s)` | `FLOAT` hoặc `DOUBLE` |
| Văn bản hiển thị cho người dùng | Bảng và index `utf8mb4` | Mặc định `utf8` / `utf8mb3` của MySQL |
| Timestamp của ứng dụng | `DATETIME` với UTC do app quản lý | Giả định `DATETIME` lưu metadata múi giờ |
| Soft delete | `deleted_at DATETIME NULL` cùng các index có phạm vi | Lọc các dòng soft-delete mà không có index |
| Giá trị status có thể mở rộng | bảng lookup hoặc `VARCHAR` có ràng buộc | `ENUM` khi giá trị thay đổi thường xuyên |

## Indexing

Thứ tự composite index thường theo các điều kiện bằng (equality) trước, rồi đến các cột range hoặc
sort:

```sql
CREATE INDEX idx_orders_account_status_created
    ON orders (account_id, status, created_at);

SELECT id, total
FROM orders
WHERE account_id = ?
  AND status = 'pending'
  AND created_at >= ?
ORDER BY created_at DESC
LIMIT 50;
```

Dùng `EXPLAIN` trước khi thêm hoặc thay đổi một index:

```sql
EXPLAIN
SELECT id, total
FROM orders
WHERE account_id = 123 AND status = 'pending'
ORDER BY created_at DESC
LIMIT 50;
```

Các tín hiệu cần điều tra:

| Trường | Tín hiệu rủi ro |
| --- | --- |
| `type` | `ALL` trên một bảng lớn |
| `key` | `NULL` khi tồn tại điều kiện có tính chọn lọc |
| `rows` | Ước tính số dòng rất cao cho một đường tương tác |
| `Extra` | `Using temporary`, `Using filesort`, hoặc `Using where` rộng |

Tránh thêm index một cách mù quáng. Mỗi index làm tăng chi phí ghi, thời gian migration,
kích thước backup và áp lực lên buffer-pool.

## Pattern truy vấn

### Upsert

Dạng tương thích giữa các engine:

```sql
INSERT INTO user_settings (user_id, setting_key, setting_value)
VALUES (?, ?, ?)
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    updated_at = CURRENT_TIMESTAMP;
```

Dạng row-alias của MySQL:

```sql
INSERT INTO user_settings (user_id, setting_key, setting_value)
VALUES (?, ?, ?) AS new
ON DUPLICATE KEY UPDATE
    setting_value = new.setting_value,
    updated_at = CURRENT_TIMESTAMP;
```

Chỉ dùng dạng row-alias sau khi xác nhận target là MySQL. Dùng
`VALUES(col)` cho MariaDB hoặc các fleet hỗn hợp MySQL/MariaDB.

### Keyset Pagination

```sql
SELECT id, name, created_at
FROM products
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

Hậu thuẫn nó bằng một index khớp với cursor:

```sql
CREATE INDEX idx_products_created_id ON products (created_at, id);
```

Không dùng `OFFSET` pagination sâu trên các bảng lớn; nó khiến server quét
và loại bỏ các dòng trước khi trả về trang.

### Trường JSON

Dùng cột JSON cho dữ liệu mở rộng, không dùng cho các trường cần lọc quan hệ
nặng hoặc ràng buộc.

```sql
CREATE TABLE events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payload JSON NOT NULL,
    event_type VARCHAR(64)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(payload, '$.type'))) STORED,
    KEY idx_events_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Với các đường dẫn JSON được truy vấn thường xuyên, hãy tạo một generated column và đánh index
cột đó. Giữ khóa ngoại, quyền sở hữu, tenancy và các trường vòng đời ở dạng quan hệ.

### Full-Text Search

```sql
ALTER TABLE articles ADD FULLTEXT KEY ft_articles_title_body (title, body);

SELECT id, title, MATCH(title, body) AGAINST (? IN NATURAL LANGUAGE MODE) AS score
FROM articles
WHERE MATCH(title, body) AGAINST (? IN NATURAL LANGUAGE MODE)
ORDER BY score DESC
LIMIT 20;
```

Dùng công cụ tìm kiếm bên ngoài khi bạn cần dung sai lỗi chính tả, xếp hạng phức tạp, facet
liên bảng, hoặc phân tích theo ngôn ngữ vượt quá hành vi full-text tích hợp sẵn.

## Transaction

Giữ transaction ngắn và khóa các dòng theo thứ tự nhất quán:

```sql
START TRANSACTION;

SELECT id, balance
FROM accounts
WHERE id IN (?, ?)
ORDER BY id
FOR UPDATE;

UPDATE accounts SET balance = balance - ? WHERE id = ?;
UPDATE accounts SET balance = balance + ? WHERE id = ?;

COMMIT;
```

Checklist về deadlock và lock-wait:

- Khóa các dòng theo thứ tự xác định trên mọi đường code.
- Thực hiện các lời gọi API bên ngoài trước khi mở transaction, không phải bên trong nó.
- Thêm index cho các điều kiện dùng trong `UPDATE`, `DELETE` và các lần đọc có khóa.
- Khi deadlock, rollback và retry toàn bộ transaction với ngân sách retry
  có giới hạn.
- Chụp `SHOW ENGINE INNODB STATUS\G` ngay sau một deadlock; nó bị ghi đè
  bởi các sự kiện sau đó.

Worker claim kiểu queue:

```sql
START TRANSACTION;

SELECT id
FROM jobs
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;

UPDATE jobs
SET status = 'processing', started_at = CURRENT_TIMESTAMP
WHERE id = ?;

COMMIT;
```

Chỉ dùng `SKIP LOCKED` cho các workload kiểu queue nơi việc bỏ qua một dòng bị khóa là
chấp nhận được. Nó không thay thế cho tính nhất quán transaction thông thường.

## Connection Pool

Ví dụ SQLAlchemy:

```python
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+mysqlconnector://app:secret@db.internal/app",
    pool_size=10,
    max_overflow=5,
    pool_timeout=30,
    pool_recycle=240,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 5},
)
```

Ví dụ Node.js `mysql2`:

```javascript
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 30000,
});

const [rows] = await pool.execute(
  'SELECT id, total FROM orders WHERE account_id = ? LIMIT 50',
  [accountId],
);
```

Giữ chu kỳ recycle của pool ứng dụng thấp hơn `wait_timeout` của server. Nếu server
dùng `wait_timeout = 300`, `pool_recycle` khoảng 240 giây là hợp lý;
`pool_pre_ping` vẫn giúp phục hồi sau các sự kiện mạng và failover.

## Chẩn đoán

Các lệnh hữu ích cho lượt kiểm tra đầu tiên:

```sql
SHOW FULL PROCESSLIST;
SHOW ENGINE INNODB STATUS\G;
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
```

Bật slow log trong môi trường có kiểm soát:

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
SET GLOBAL log_queries_not_using_indexes = 'ON';
```

Chỉ dùng `EXPLAIN ANALYZE` khi việc thực thi truy vấn là an toàn. Nó chạy
statement và có thể tốn kém trên dữ liệu cỡ production.

## Replication

Read replica có thể bị lag. Không định tuyến các đường read-your-own-write, luồng checkout,
kiểm tra quyền hoặc đọc idempotency-key sang replica ngay sau một
lần ghi.

```sql
-- MySQL legacy terminology, still common in existing fleets
SHOW SLAVE STATUS\G;

-- Newer terminology where supported
SHOW REPLICA STATUS\G;
```

Kiểm tra engine/phiên bản trước khi chuẩn hóa theo một lệnh. Giám sát sức khỏe
SQL thread, sức khỏe IO thread và độ lag của replica, không chỉ xem kết nối TCP
còn sống hay không.

## Bảo mật

```sql
CREATE USER 'app'@'%' IDENTIFIED BY 'use-a-secret-manager';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'app'@'%';

ALTER USER 'app'@'%' REQUIRE SSL;

SELECT user, host
FROM mysql.user
WHERE user = '';

DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';
```

Các điểm review bảo mật:

- Không cấp `ALL PRIVILEGES` hoặc `*.*` cho user ứng dụng.
- Yêu cầu TLS cho user ứng dụng khi lưu lượng đi qua các host hoặc mạng.
- Lưu credential trong secret manager của nền tảng, không để trong ví dụ, script hoặc
  file của repository.
- Tách user migration/admin khỏi user ứng dụng chạy runtime.
- Kiểm toán việc phơi bày ra mạng công cộng và các bind address trước khi tinh chỉnh hiệu năng.

## Cấu hình

Ví dụ điểm khởi đầu cho một host database chuyên dụng:

```ini
[mysqld]
innodb_buffer_pool_size = 4G
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1

max_connections = 300
thread_cache_size = 50

wait_timeout = 300
interactive_timeout = 300
innodb_lock_wait_timeout = 10

slow_query_log = ON
long_query_time = 1
log_queries_not_using_indexes = ON

log_bin = mysql-bin
binlog_format = ROW
binlog_expire_logs_seconds = 604800
```

Coi các giá trị cấu hình là gợi ý để review, không phải preset phổ quát. Hãy định cỡ
bộ nhớ, số connection, thời gian lưu log và các thiết lập độ bền từ workload,
phần cứng, chính sách backup và mục tiêu phục hồi.

## Anti-Pattern

| Anti-Pattern | Rủi ro | Pattern tốt hơn |
| --- | --- | --- |
| `SELECT *` trên các đường nóng | Fetch thừa và client dễ vỡ | Chọn các cột tường minh |
| `OFFSET` pagination sâu | Quét tuyến tính và trang chậm | Keyset pagination |
| Không có index cho join khóa ngoại | Join chậm và delete nặng về lock | Đánh index cột FK một cách có chủ đích |
| Transaction dài | Lock wait và lịch sử undo lớn | Commit các đơn vị công việc nhỏ |
| DML trực tiếp trên `mysql.user` | Nguy cơ hỏng bảng grant | Dùng `CREATE USER`, `ALTER USER`, `DROP USER` |
| User ứng dụng có quyền admin | Phạm vi ảnh hưởng lớn | User runtime với quyền tối thiểu |
| Pool recycle cao hơn `wait_timeout` | Connection trong pool đã cũ | Recycle thấp hơn timeout và pre-ping |
| Đọc từ replica sau khi ghi | Trạng thái hiển thị cho người dùng bị cũ | Ghim các luồng read-after-write vào primary |

## Kỳ vọng về đầu ra

Khi skill này được dùng để review, hãy trả về:

1. Các giả định về engine/phiên bản.
2. Các vấn đề rủi ro cao nhất về tính đúng đắn, lock, bảo mật và migration.
3. SQL hoặc thay đổi code chính xác cho đường đi an toàn.
4. Kế hoạch validation: `EXPLAIN`, chạy thử migration (dry run), kiểm tra lock/deadlock, và
   tiêu chí rollback.
5. Mọi khác biệt cú pháp MySQL/MariaDB ảnh hưởng đến khuyến nghị.

## Liên quan

- Skill: `postgres-patterns` - pattern schema và truy vấn riêng cho PostgreSQL
- Skill: `database-migrations` - lập kế hoạch migration và an toàn khi rollout
- Skill: `backend-patterns` - pattern API và tầng service
- Skill: `security-review` - xử lý secret, auth và đặc quyền tối thiểu
- Agent: `database-reviewer` - workflow review database rộng hơn
