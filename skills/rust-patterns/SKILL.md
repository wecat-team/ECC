---
name: rust-patterns
description: Các pattern Rust idiomatic, ownership, xử lý lỗi, trait, concurrency và best practice để xây dựng ứng dụng an toàn, hiệu năng cao. Dùng khi viết hoặc review code Rust và có vấn đề về ownership, xử lý lỗi, trait hoặc concurrency.
metadata:
  origin: ECC
---

# Pattern phát triển Rust

Các pattern Rust idiomatic và best practice để xây dựng ứng dụng an toàn, hiệu năng cao và dễ bảo trì.

## Khi nào dùng

- Viết code Rust mới
- Review code Rust
- Refactor code Rust hiện có
- Thiết kế cấu trúc crate và bố cục module

## Cách hoạt động

Skill này thực thi các quy ước Rust idiomatic trên sáu lĩnh vực chính: ownership và borrowing để ngăn data race ngay lúc compile, lan truyền lỗi bằng `Result`/`?` với `thiserror` cho thư viện và `anyhow` cho ứng dụng, enum và exhaustive pattern matching để biến các trạng thái không hợp lệ thành không thể biểu diễn, trait và generic cho abstraction không tốn chi phí (zero-cost), concurrency an toàn qua `Arc<Mutex<T>>`, channel và async/await, cùng bề mặt `pub` tối thiểu được tổ chức theo domain.

## Nguyên tắc cốt lõi

### 1. Ownership và Borrowing

Hệ thống ownership của Rust ngăn data race và lỗi bộ nhớ ngay lúc compile.

```rust
// Good: Pass references when you don't need ownership
fn process(data: &[u8]) -> usize {
    data.len()
}

// Good: Take ownership only when you need to store or consume
fn store(data: Vec<u8>) -> Record {
    Record { payload: data }
}

// Bad: Cloning unnecessarily to avoid borrow checker
fn process_bad(data: &Vec<u8>) -> usize {
    let cloned = data.clone(); // Wasteful — just borrow
    cloned.len()
}
```

### Dùng `Cow` cho ownership linh hoạt

```rust
use std::borrow::Cow;

fn normalize(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        Cow::Owned(input.replace(' ', "_"))
    } else {
        Cow::Borrowed(input) // Zero-cost when no mutation needed
    }
}
```

## Xử lý lỗi

### Dùng `Result` và `?` — KHÔNG BAO GIỜ dùng `unwrap()` trong production

```rust
// Good: Propagate errors with context
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {path}"))?;
    let config: Config = toml::from_str(&content)
        .with_context(|| format!("failed to parse config from {path}"))?;
    Ok(config)
}

// Bad: Panics on error
fn load_config_bad(path: &str) -> Config {
    let content = std::fs::read_to_string(path).unwrap(); // Panics!
    toml::from_str(&content).unwrap()
}
```

### Lỗi của thư viện dùng `thiserror`, lỗi của ứng dụng dùng `anyhow`

```rust
// Library code: structured, typed errors
use thiserror::Error;

#[derive(Debug, Error)]
pub enum StorageError {
    #[error("record not found: {id}")]
    NotFound { id: String },
    #[error("connection failed")]
    Connection(#[from] std::io::Error),
    #[error("invalid data: {0}")]
    InvalidData(String),
}

// Application code: flexible error handling
use anyhow::{bail, Result};

fn run() -> Result<()> {
    let config = load_config("app.toml")?;
    if config.workers == 0 {
        bail!("worker count must be > 0");
    }
    Ok(())
}
```

### Dùng combinator của `Option` thay vì matching lồng nhau

```rust
// Good: Combinator chain
fn find_user_email(users: &[User], id: u64) -> Option<String> {
    users.iter()
        .find(|u| u.id == id)
        .map(|u| u.email.clone())
}

// Bad: Deeply nested matching
fn find_user_email_bad(users: &[User], id: u64) -> Option<String> {
    match users.iter().find(|u| u.id == id) {
        Some(user) => match &user.email {
            email => Some(email.clone()),
        },
        None => None,
    }
}
```

## Enum và Pattern Matching

### Mô hình hóa trạng thái bằng Enum

```rust
// Good: Impossible states are unrepresentable
enum ConnectionState {
    Disconnected,
    Connecting { attempt: u32 },
    Connected { session_id: String },
    Failed { reason: String, retries: u32 },
}

fn handle(state: &ConnectionState) {
    match state {
        ConnectionState::Disconnected => connect(),
        ConnectionState::Connecting { attempt } if *attempt > 3 => abort(),
        ConnectionState::Connecting { .. } => wait(),
        ConnectionState::Connected { session_id } => use_session(session_id),
        ConnectionState::Failed { retries, .. } if *retries < 5 => retry(),
        ConnectionState::Failed { reason, .. } => log_failure(reason),
    }
}
```

### Exhaustive Matching — Không dùng catch-all cho business logic

```rust
// Good: Handle every variant explicitly
match command {
    Command::Start => start_service(),
    Command::Stop => stop_service(),
    Command::Restart => restart_service(),
    // Adding a new variant forces handling here
}

// Bad: Wildcard hides new variants
match command {
    Command::Start => start_service(),
    _ => {} // Silently ignores Stop, Restart, and future variants
}
```

## Trait và Generic

### Nhận generic, trả về kiểu cụ thể

```rust
// Good: Generic input, concrete output
fn read_all(reader: &mut impl Read) -> std::io::Result<Vec<u8>> {
    let mut buf = Vec::new();
    reader.read_to_end(&mut buf)?;
    Ok(buf)
}

// Good: Trait bounds for multiple constraints
fn process<T: Display + Send + 'static>(item: T) -> String {
    format!("processed: {item}")
}
```

### Trait Object cho Dynamic Dispatch

```rust
// Use when you need heterogeneous collections or plugin systems
trait Handler: Send + Sync {
    fn handle(&self, request: &Request) -> Response;
}

struct Router {
    handlers: Vec<Box<dyn Handler>>,
}

// Use generics when you need performance (monomorphization)
fn fast_process<H: Handler>(handler: &H, request: &Request) -> Response {
    handler.handle(request)
}
```

### Newtype Pattern cho an toàn kiểu

```rust
// Good: Distinct types prevent mixing up arguments
struct UserId(u64);
struct OrderId(u64);

fn get_order(user: UserId, order: OrderId) -> Result<Order> {
    // Can't accidentally swap user and order IDs
    todo!()
}

// Bad: Easy to swap arguments
fn get_order_bad(user_id: u64, order_id: u64) -> Result<Order> {
    todo!()
}
```

## Struct và mô hình hóa dữ liệu

### Builder Pattern cho việc khởi tạo phức tạp

```rust
struct ServerConfig {
    host: String,
    port: u16,
    max_connections: usize,
}

impl ServerConfig {
    fn builder(host: impl Into<String>, port: u16) -> ServerConfigBuilder {
        ServerConfigBuilder { host: host.into(), port, max_connections: 100 }
    }
}

struct ServerConfigBuilder { host: String, port: u16, max_connections: usize }

impl ServerConfigBuilder {
    fn max_connections(mut self, n: usize) -> Self { self.max_connections = n; self }
    fn build(self) -> ServerConfig {
        ServerConfig { host: self.host, port: self.port, max_connections: self.max_connections }
    }
}

// Usage: ServerConfig::builder("localhost", 8080).max_connections(200).build()
```

## Iterator và Closure

### Ưu tiên chuỗi Iterator hơn vòng lặp thủ công

```rust
// Good: Declarative, lazy, composable
let active_emails: Vec<String> = users.iter()
    .filter(|u| u.is_active)
    .map(|u| u.email.clone())
    .collect();

// Bad: Imperative accumulation
let mut active_emails = Vec::new();
for user in &users {
    if user.is_active {
        active_emails.push(user.email.clone());
    }
}
```

### Dùng `collect()` kèm type annotation

```rust
// Collect into different types
let names: Vec<_> = items.iter().map(|i| &i.name).collect();
let lookup: HashMap<_, _> = items.iter().map(|i| (i.id, i)).collect();
let combined: String = parts.iter().copied().collect();

// Collect Results — short-circuits on first error
let parsed: Result<Vec<i32>, _> = strings.iter().map(|s| s.parse()).collect();
```

## Concurrency

### `Arc<Mutex<T>>` cho mutable state dùng chung

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0));
let handles: Vec<_> = (0..10).map(|_| {
    let counter = Arc::clone(&counter);
    std::thread::spawn(move || {
        let mut num = counter.lock().expect("mutex poisoned");
        *num += 1;
    })
}).collect();

for handle in handles {
    handle.join().expect("worker thread panicked");
}
```

### Channel để truyền thông điệp

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::sync_channel(16); // Bounded channel with backpressure

for i in 0..5 {
    let tx = tx.clone();
    std::thread::spawn(move || {
        tx.send(format!("message {i}")).expect("receiver disconnected");
    });
}
drop(tx); // Close sender so rx iterator terminates

for msg in rx {
    println!("{msg}");
}
```

### Async với Tokio

```rust
use tokio::time::Duration;

async fn fetch_with_timeout(url: &str) -> Result<String> {
    let response = tokio::time::timeout(
        Duration::from_secs(5),
        reqwest::get(url),
    )
    .await
    .context("request timed out")?
    .context("request failed")?;

    response.text().await.context("failed to read body")
}

// Spawn concurrent tasks
async fn fetch_all(urls: Vec<String>) -> Vec<Result<String>> {
    let handles: Vec<_> = urls.into_iter()
        .map(|url| tokio::spawn(async move {
            fetch_with_timeout(&url).await
        }))
        .collect();

    let mut results = Vec::with_capacity(handles.len());
    for handle in handles {
        results.push(handle.await.unwrap_or_else(|e| panic!("spawned task panicked: {e}")));
    }
    results
}
```

## Code Unsafe

### Khi nào chấp nhận dùng Unsafe

```rust
// Acceptable: FFI boundary with documented invariants (Rust 2024+)
/// # Safety
/// `ptr` must be a valid, aligned pointer to an initialized `Widget`.
unsafe fn widget_from_raw<'a>(ptr: *const Widget) -> &'a Widget {
    // SAFETY: caller guarantees ptr is valid and aligned
    unsafe { &*ptr }
}

// Acceptable: Performance-critical path with proof of correctness
// SAFETY: index is always < len due to the loop bound
unsafe { slice.get_unchecked(index) }
```

### Khi nào KHÔNG chấp nhận dùng Unsafe

```rust
// Bad: Using unsafe to bypass borrow checker
// Bad: Using unsafe for convenience
// Bad: Using unsafe without a Safety comment
// Bad: Transmuting between unrelated types
```

## Hệ thống Module và cấu trúc Crate

### Tổ chức theo Domain, không theo loại

```text
my_app/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── auth/          # Domain module
│   │   ├── mod.rs
│   │   ├── token.rs
│   │   └── middleware.rs
│   ├── orders/        # Domain module
│   │   ├── mod.rs
│   │   ├── model.rs
│   │   └── service.rs
│   └── db/            # Infrastructure
│       ├── mod.rs
│       └── pool.rs
├── tests/             # Integration tests
├── benches/           # Benchmarks
└── Cargo.toml
```

### Visibility — Chỉ expose tối thiểu

```rust
// Good: pub(crate) for internal sharing
pub(crate) fn validate_input(input: &str) -> bool {
    !input.is_empty()
}

// Good: Re-export public API from lib.rs
pub mod auth;
pub use auth::AuthMiddleware;

// Bad: Making everything pub
pub fn internal_helper() {} // Should be pub(crate) or private
```

## Tích hợp công cụ

### Các lệnh thiết yếu

```bash
# Build and check
cargo build
cargo check              # Fast type checking without codegen
cargo clippy             # Lints and suggestions
cargo fmt                # Format code

# Testing
cargo test
cargo test -- --nocapture    # Show println output
cargo test --lib             # Unit tests only
cargo test --test integration # Integration tests only

# Dependencies
cargo audit              # Security audit
cargo tree               # Dependency tree
cargo update             # Update dependencies

# Performance
cargo bench              # Run benchmarks
```

## Tham khảo nhanh: Các idiom của Rust

| Idiom | Mô tả |
|-------|-------------|
| Borrow, đừng clone | Truyền `&T` thay vì clone trừ khi cần ownership |
| Biến trạng thái không hợp lệ thành không thể biểu diễn | Dùng enum để chỉ mô hình hóa các trạng thái hợp lệ |
| `?` thay vì `unwrap()` | Lan truyền lỗi, không bao giờ panic trong code thư viện/production |
| Parse, đừng validate | Chuyển dữ liệu phi cấu trúc thành struct có kiểu ngay tại ranh giới |
| Newtype cho an toàn kiểu | Bọc kiểu nguyên thủy trong newtype để tránh nhầm thứ tự tham số |
| Ưu tiên iterator hơn vòng lặp | Chuỗi khai báo (declarative) rõ ràng hơn và thường nhanh hơn |
| `#[must_use]` trên Result | Đảm bảo bên gọi xử lý giá trị trả về |
| `Cow` cho ownership linh hoạt | Tránh cấp phát khi borrow là đủ |
| Exhaustive matching | Không dùng wildcard `_` cho enum quan trọng về nghiệp vụ |
| Bề mặt `pub` tối thiểu | Dùng `pub(crate)` cho API nội bộ |

## Anti-Pattern cần tránh

```rust
// Bad: .unwrap() in production code
let value = map.get("key").unwrap();

// Bad: .clone() to satisfy borrow checker without understanding why
let data = expensive_data.clone();
process(&original, &data);

// Bad: Using String when &str suffices
fn greet(name: String) { /* should be &str */ }

// Bad: Box<dyn Error> in libraries (use thiserror instead)
fn parse(input: &str) -> Result<Data, Box<dyn std::error::Error>> { todo!() }

// Bad: Ignoring must_use warnings
let _ = validate(input); // Silently discarding a Result

// Bad: Blocking in async context
async fn bad_async() {
    std::thread::sleep(Duration::from_secs(1)); // Blocks the executor!
    // Use: tokio::time::sleep(Duration::from_secs(1)).await;
}
```

**Hãy nhớ**: Nếu nó compile được thì khả năng cao là đúng — nhưng chỉ khi bạn tránh `unwrap()`, hạn chế `unsafe` và để hệ thống kiểu làm việc cho bạn.
