---
name: redis-patterns
description: Các pattern cấu trúc dữ liệu Redis, chiến lược caching, distributed lock, rate limiting, pub/sub và quản lý connection cho ứng dụng production. Dùng khi thêm caching, distributed lock, rate limiting hoặc pub/sub với Redis, hoặc khi cần review thiết kế key.
metadata:
  origin: ECC
---

# Redis Patterns

Tài liệu tham khảo nhanh về best practice của Redis cho các use case backend phổ biến.

## Cách hoạt động

Redis là một kho cấu trúc dữ liệu in-memory, hỗ trợ string, hash, list, set, sorted set, stream và nhiều kiểu khác. Từng lệnh Redis riêng lẻ là atomic trên một instance; các workflow nhiều bước cần Lua script, transaction MULTI/EXEC hoặc đồng bộ hóa tường minh để giữ tính atomic. Dữ liệu có thể được lưu bền qua snapshot RDB hoặc log AOF. Client giao tiếp qua TCP bằng giao thức RESP; connection pool là bắt buộc để tránh chi phí handshake cho mỗi request.

## Khi nào kích hoạt

- Thêm caching vào ứng dụng
- Triển khai rate limiting hoặc throttling
- Xây dựng distributed lock hoặc cơ chế điều phối
- Thiết lập lưu trữ session hoặc token
- Dùng Pub/Sub hoặc Redis Streams để truyền thông điệp
- Cấu hình Redis trong production (pooling, eviction, clustering)

## Bảng tra nhanh cấu trúc dữ liệu

| Use Case | Cấu trúc | Key ví dụ |
|----------|-----------|-------------|
| Cache đơn giản | String | `product:123` |
| Session người dùng | Hash | `session:abc` |
| Bảng xếp hạng | Sorted Set | `scores:weekly` |
| Khách truy cập duy nhất | Set | `visitors:2024-01-01` |
| Activity feed | List | `feed:user:456` |
| Event stream | Stream | `events:orders` |
| Bộ đếm / rate limit | String (INCR) | `ratelimit:user:123` |
| Bloom filter / HLL | HyperLogLog | `hll:pageviews` |

## Các pattern cốt lõi

### Cache-Aside (Lazy Loading)

```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_product(product_id: int):
    cache_key = f"product:{product_id}"
    cached = r.get(cache_key)

    if cached:
        return json.loads(cached)

    product = db.query("SELECT * FROM products WHERE id = %s", product_id)
    r.setex(cache_key, 3600, json.dumps(product))  # TTL: 1 hour
    return product
```

### Write-Through Cache

```python
def update_product(product_id: int, data: dict):
    # Write to DB first
    db.execute("UPDATE products SET ... WHERE id = %s", product_id)

    # Immediately update cache
    cache_key = f"product:{product_id}"
    r.setex(cache_key, 3600, json.dumps(data))
```

### Cache Invalidation

```python
# Tag-based invalidation — group related keys under a set
def cache_product(product_id: int, category_id: int, data: dict):
    key = f"product:{product_id}"
    tag = f"tag:category:{category_id}"
    pipe = r.pipeline(transaction=True)
    pipe.setex(key, 3600, json.dumps(data))
    pipe.sadd(tag, key)
    pipe.expire(tag, 3600)
    pipe.execute()

def invalidate_category(category_id: int):
    tag = f"tag:category:{category_id}"
    keys = r.smembers(tag)
    if keys:
        r.delete(*keys)
    r.delete(tag)
```

### Session Storage

```python
import time
import uuid

def create_session(user_id: int, ttl: int = 86400) -> str:
    session_id = str(uuid.uuid4())
    key = f"session:{session_id}"
    pipe = r.pipeline(transaction=True)
    pipe.hset(key, mapping={
        "user_id": user_id,
        "created_at": int(time.time()),
    })
    pipe.expire(key, ttl)
    pipe.execute()
    return session_id

def get_session(session_id: str) -> dict | None:
    data = r.hgetall(f"session:{session_id}")
    return data if data else None

def delete_session(session_id: str):
    r.delete(f"session:{session_id}")
```

## Rate Limiting

### Fixed Window (đơn giản)

```python
def is_rate_limited(user_id: int, limit: int = 100, window: int = 60) -> bool:
    key = f"ratelimit:{user_id}:{int(time.time()) // window}"
    pipe = r.pipeline(transaction=True)
    pipe.incr(key)
    pipe.expire(key, window)
    count, _ = pipe.execute()
    return count > limit
```

### Sliding Window (Lua — Atomic)

```lua
-- sliding_window.lua
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])

redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
local count = redis.call('ZCARD', key)

if count < limit then
    -- Use unique member (now + sequence) to avoid collisions within the same millisecond
    local seq_key = key .. ':seq'
    local seq = redis.call('INCR', seq_key)
    redis.call('EXPIRE', seq_key, math.ceil(window / 1000))
    redis.call('ZADD', key, now, now .. '-' .. seq)
    redis.call('EXPIRE', key, math.ceil(window / 1000))
    return 1
end
return 0
```

```python
sliding_window = r.register_script(open('sliding_window.lua').read())

def allow_request(user_id: int) -> bool:
    key = f"ratelimit:sliding:{user_id}"
    now = int(time.time() * 1000)
    return bool(sliding_window(keys=[key], args=[now, 60000, 100]))
```

## Distributed Lock

### Distributed Lock (Single Node — SET NX PX)

```python
import uuid

def acquire_lock(resource: str, ttl_ms: int = 5000) -> str | None:
    lock_key = f"lock:{resource}"
    token = str(uuid.uuid4())
    acquired = r.set(lock_key, token, px=ttl_ms, nx=True)
    return token if acquired else None

def release_lock(resource: str, token: str) -> bool:
    release_script = """
    if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
    else
        return 0
    end
    """
    result = r.eval(release_script, 1, f"lock:{resource}", token)
    return bool(result)

# Usage
token = acquire_lock("order:payment:123")
if token:
    try:
        process_payment()
    finally:
        release_lock("order:payment:123", token)
```

> Với setup nhiều node, hãy dùng thư viện `redlock-py` triển khai đầy đủ thuật toán Redlock.

## Pub/Sub & Streams

### Pub/Sub (Fire-and-Forget)

```python
# Publisher
def publish_event(channel: str, payload: dict):
    r.publish(channel, json.dumps(payload))

# Subscriber (blocking — run in separate thread/process)
def subscribe_events(channel: str):
    pubsub = r.pubsub()
    pubsub.subscribe(channel)
    for message in pubsub.listen():
        if message['type'] == 'message':
            handle(json.loads(message['data']))
```

### Redis Streams (Durable Queue)

```python
# Producer
def emit(stream: str, event: dict):
    r.xadd(stream, event, maxlen=10000)  # Cap stream length

# Consumer group — guarantees at-least-once delivery
try:
    r.xgroup_create('events:orders', 'processor', id='0', mkstream=True)
except Exception:
    pass  # Group already exists

def consume(stream: str, group: str, consumer: str):
    while True:
        messages = r.xreadgroup(group, consumer, {stream: '>'}, count=10, block=2000)
        for _, entries in (messages or []):
            for msg_id, data in entries:
                process(data)
                r.xack(stream, group, msg_id)
```

> Ưu tiên **Streams** hơn Pub/Sub khi cần đảm bảo giao nhận, consumer group hoặc replay.

## Thiết kế Key

### Quy ước đặt tên

```
# Pattern: resource:id:field
user:123:profile
order:456:status
cache:product:789

# Pattern: namespace:resource:id
myapp:session:abc123
myapp:ratelimit:user:123

# Pattern: resource:date (time-bound keys)
stats:pageviews:2024-01-01
```

### Chiến lược TTL

| Loại dữ liệu | TTL đề xuất |
|-----------|--------------|
| Session người dùng | 24h (`86400`) |
| Cache response API | 5–15 phút |
| Cửa sổ rate limit | Khớp với kích thước cửa sổ |
| Token ngắn hạn | 5–10 phút |
| Bảng xếp hạng | 1h–24h |
| Dữ liệu tĩnh/tham chiếu | 1h–1 tuần |

Luôn đặt TTL. Key không có TTL sẽ tích tụ vô hạn và gây áp lực bộ nhớ.

## Quản lý Connection

### Connection Pooling

```python
from redis import ConnectionPool, Redis

pool = ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=20,
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
)

r = Redis(connection_pool=pool)
```

### Cluster Mode

```python
from redis.cluster import RedisCluster

r = RedisCluster(
    startup_nodes=[{"host": "redis-1", "port": 6379}],
    decode_responses=True,
    skip_full_coverage_check=True,
)
```

### Sentinel (High Availability)

```python
from redis.sentinel import Sentinel

sentinel = Sentinel(
    [('sentinel-1', 26379), ('sentinel-2', 26379)],
    socket_timeout=0.5,
)
master = sentinel.master_for('mymaster', decode_responses=True)
replica = sentinel.slave_for('mymaster', decode_responses=True)
```

## Chính sách Eviction

| Chính sách | Hành vi | Phù hợp nhất cho |
|--------|----------|----------|
| `noeviction` | Báo lỗi khi ghi lúc đầy bộ nhớ | Queue / dữ liệu quan trọng |
| `allkeys-lru` | Loại bỏ key ít được dùng gần đây nhất | Cache thông thường |
| `volatile-lru` | LRU chỉ trong các key có TTL | Kho dữ liệu hỗn hợp |
| `allkeys-lfu` | Loại bỏ key ít được dùng thường xuyên nhất | Pattern truy cập lệch |
| `volatile-ttl` | Loại bỏ key sắp hết hạn sớm nhất | Ưu tiên dữ liệu sống lâu |

Đặt qua `redis.conf`: `maxmemory-policy allkeys-lru`

## Anti-Pattern

| Anti-Pattern | Vấn đề | Cách sửa |
|---|---|---|
| Key không có TTL | Bộ nhớ tăng không giới hạn | Luôn đặt TTL |
| `KEYS *` trong production | Chặn server (O(N)) | Dùng con trỏ `SCAN` |
| Lưu blob lớn (>100KB) | Serialize chậm, áp lực bộ nhớ | Lưu tham chiếu + lấy từ object store |
| Một Redis cho mọi thứ | Không cô lập giữa cache và queue | Dùng DB hoặc instance riêng |
| Bỏ qua giới hạn connection pool | Cạn kiệt connection khi tải cao | Chỉnh kích thước pool theo workload |
| Không xử lý cache miss stampede | Thundering herd khi cold start | Dùng lock hoặc probabilistic early expiry |
| `FLUSHALL` thiếu suy nghĩ | Xóa sạch toàn bộ instance | Giới hạn phạm vi xóa theo key pattern |

### Ngăn chặn Cache Miss Stampede

```python
import threading

_locks: dict[str, threading.Lock] = {}
_locks_mutex = threading.Lock()

def get_with_lock(key: str, fetch_fn, ttl: int = 300):
    cached = r.get(key)
    if cached:
        return json.loads(cached)

    with _locks_mutex:
        if key not in _locks:
            _locks[key] = threading.Lock()
        lock = _locks[key]
    with lock:
        cached = r.get(key)  # Re-check after acquiring lock
        if cached:
            return json.loads(cached)
        value = fetch_fn()
        r.setex(key, ttl, json.dumps(value))
        return value
```

> Lưu ý: với deployment nhiều process, hãy thay lock trong process bằng `acquire_lock`/`release_lock` từ phần Distributed Lock ở trên.

## Ví dụ

**Thêm caching vào endpoint API Django/Flask:**
Dùng cache-aside với `setex` và TTL 5 phút cho response. Dùng các tham số của request làm key.

**Rate-limit API theo người dùng:**
Dùng fixed-window với `pipeline(transaction=True)` cho endpoint lưu lượng thấp; dùng sliding-window Lua để throttle chính xác theo từng người dùng.

**Điều phối background job giữa các worker:**
Dùng `acquire_lock` với TTL lớn hơn thời lượng job dự kiến. Luôn release trong khối `finally`.

**Fan-out thông báo tới nhiều subscriber:**
Dùng Pub/Sub cho fire-and-forget. Chuyển sang Streams nếu cần đảm bảo giao nhận hoặc replay cho consumer đến muộn.

## Tham khảo nhanh

| Pattern | Khi nào dùng |
|---------|-------------|
| Cache-aside | Đọc nhiều, chấp nhận dữ liệu hơi cũ |
| Write-through | Cần nhất quán mạnh |
| Distributed lock | Ngăn truy cập đồng thời vào một tài nguyên |
| Sliding window rate limit | Throttle chính xác theo từng người dùng |
| Redis Streams | Event queue bền vững với consumer group |
| Pub/Sub | Broadcast, không cần đảm bảo giao nhận |
| Sorted Set leaderboard | Chấm điểm xếp hạng, phân trang |
| HyperLogLog | Đếm số lượng duy nhất xấp xỉ với bộ nhớ thấp |

## Liên quan

- Skill: `postgres-patterns` — pattern cho dữ liệu quan hệ
- Skill: `backend-patterns` — pattern cho tầng API và service
- Skill: `database-migrations` — quản lý phiên bản schema
- Skill: `django-patterns` — tích hợp Django cache framework
- Agent: `database-reviewer` — workflow review database đầy đủ
