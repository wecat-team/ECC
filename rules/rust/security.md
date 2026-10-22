---
paths:
  - "**/*.rs"
---
# Bảo mật Rust

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho Rust.

## Quản lý secret

- Không bao giờ hardcode API key, token hay credential trong source code
- Dùng biến môi trường: `std::env::var("API_KEY")`
- Fail fast nếu thiếu secret bắt buộc khi khởi động
- Giữ các file `.env` trong `.gitignore`

```rust
// BAD
const API_KEY: &str = "sk-abc123...";

// GOOD — biến môi trường kèm kiểm tra sớm
fn load_api_key() -> anyhow::Result<String> {
    std::env::var("PAYMENT_API_KEY")
        .context("PAYMENT_API_KEY must be set")
}
```

## Ngăn chặn SQL Injection

- Luôn dùng truy vấn tham số hóa — không bao giờ format đầu vào của người dùng vào chuỗi SQL
- Dùng query builder hoặc ORM (sqlx, diesel, sea-orm) với tham số bind

```rust
// BAD — SQL injection via format string
let query = format!("SELECT * FROM users WHERE name = '{name}'");
sqlx::query(&query).fetch_one(&pool).await?;

// GOOD — truy vấn tham số hóa với sqlx
// Cú pháp placeholder khác nhau theo backend: Postgres: $1  |  MySQL: ?  |  SQLite: $1
sqlx::query("SELECT * FROM users WHERE name = $1")
    .bind(&name)
    .fetch_one(&pool)
    .await?;
```

## Kiểm tra đầu vào (Input Validation)

- Validate mọi đầu vào của người dùng tại ranh giới hệ thống trước khi xử lý
- Dùng hệ thống type để thực thi bất biến (invariant) (newtype pattern)
- Parse, don't validate — chuyển dữ liệu phi cấu trúc thành struct có type ngay tại ranh giới
- Từ chối đầu vào không hợp lệ kèm thông báo lỗi rõ ràng

```rust
// Parse, don't validate — trạng thái không hợp lệ không thể biểu diễn
pub struct Email(String);

impl Email {
    pub fn parse(input: &str) -> Result<Self, ValidationError> {
        let trimmed = input.trim();
        let at_pos = trimmed.find('@')
            .filter(|&p| p > 0 && p < trimmed.len() - 1)
            .ok_or_else(|| ValidationError::InvalidEmail(input.to_string()))?;
        let domain = &trimmed[at_pos + 1..];
        if trimmed.len() > 254 || !domain.contains('.') {
            return Err(ValidationError::InvalidEmail(input.to_string()));
        }
        // For production use, prefer a validated email crate (e.g., `email_address`)
        Ok(Self(trimmed.to_string()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

## Code Unsafe

- Tối thiểu hóa các khối `unsafe` — ưu tiên các abstraction an toàn
- Mỗi khối `unsafe` phải có comment `// SAFETY:` giải thích invariant
- Không bao giờ dùng `unsafe` để vượt borrow checker cho tiện
- Audit toàn bộ code `unsafe` trong lúc review — nếu không có lý giải thì đó là dấu hiệu cảnh báo
- Ưu tiên các wrapper FFI `safe` bao quanh thư viện C

```rust
// GOOD — comment safety ghi lại TẤT CẢ invariant bắt buộc
let widget: &Widget = {
    // SAFETY: `ptr` is non-null, aligned, points to an initialized Widget,
    // and no mutable references or mutations exist for its lifetime.
    unsafe { &*ptr }
};

// BAD — không có lý giải về safety
unsafe { &*ptr }
```

## Bảo mật Dependency

- Chạy `cargo audit` để quét các CVE đã biết trong dependency
- Chạy `cargo deny check` để kiểm tra tuân thủ license và advisory
- Dùng `cargo tree` để audit dependency bắc cầu (transitive)
- Giữ dependency luôn cập nhật — thiết lập Dependabot hoặc Renovate
- Tối thiểu hóa số lượng dependency — đánh giá trước khi thêm crate mới

```bash
# Audit bảo mật
cargo audit

# Chặn advisory, phiên bản trùng lặp và license bị hạn chế
cargo deny check

# Xem cây dependency
cargo tree
cargo tree -d  # Show duplicates only
```

## Thông báo lỗi

- Không bao giờ để lộ đường dẫn nội bộ, stack trace hay lỗi database trong response API
- Log lỗi chi tiết ở phía server; trả về thông báo chung chung cho client
- Dùng `tracing` hoặc `log` cho logging có cấu trúc phía server

```rust
// Ánh xạ lỗi sang status code phù hợp và thông báo chung chung
// (Ví dụ dùng axum; hãy điều chỉnh kiểu response cho framework của bạn)
match order_service.find_by_id(id) {
    Ok(order) => Ok((StatusCode::OK, Json(order))),
    Err(ServiceError::NotFound(_)) => {
        tracing::info!(order_id = id, "order not found");
        Err((StatusCode::NOT_FOUND, "Resource not found"))
    }
    Err(e) => {
        tracing::error!(order_id = id, error = %e, "unexpected error");
        Err((StatusCode::INTERNAL_SERVER_ERROR, "Internal server error"))
    }
}
```

## Tham chiếu

Xem skill: `rust-patterns` để biết hướng dẫn về code unsafe và các pattern ownership.
Xem skill: `security-review` để biết các checklist bảo mật chung.
