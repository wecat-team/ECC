---
paths:
  - "**/*.rs"
---
# Coding Style Rust

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho Rust.

## Định dạng

- **rustfmt** để thực thi — luôn chạy `cargo fmt` trước khi commit
- **clippy** cho lint — `cargo clippy -- -D warnings` (coi cảnh báo là lỗi)
- Thụt lề 4 dấu cách (mặc định của rustfmt)
- Độ rộng dòng tối đa: 100 ký tự (mặc định của rustfmt)

## Bất biến (Immutability)

Biến trong Rust mặc định là bất biến (immutable) — hãy tận dụng điều này:

- Mặc định dùng `let`; chỉ dùng `let mut` khi cần thay đổi
- Ưu tiên trả về giá trị mới hơn là thay đổi tại chỗ
- Dùng `Cow<'_, T>` khi một hàm có thể cần hoặc không cần cấp phát

```rust
use std::borrow::Cow;

// GOOD — mặc định bất biến, trả về giá trị mới
fn normalize(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        Cow::Owned(input.replace(' ', "_"))
    } else {
        Cow::Borrowed(input)
    }
}

// BAD — thay đổi không cần thiết
fn normalize_bad(input: &mut String) {
    *input = input.replace(' ', "_");
}
```

## Đặt tên

Tuân theo quy ước chuẩn của Rust:
- `snake_case` cho hàm, method, biến, module, crate
- `PascalCase` (UpperCamelCase) cho type, trait, enum, type parameter
- `SCREAMING_SNAKE_CASE` cho hằng và static
- Lifetime: chữ thường ngắn (`'a`, `'de`) — dùng tên mô tả cho các trường hợp phức tạp (`'input`)

## Ownership và Borrowing

- Mặc định mượn (`&T`); chỉ lấy ownership khi cần lưu trữ hoặc tiêu thụ
- Không bao giờ clone chỉ để thỏa mãn borrow checker mà không hiểu nguyên nhân gốc
- Nhận `&str` thay vì `String`, `&[T]` thay vì `Vec<T>` trong tham số hàm
- Dùng `impl Into<String>` cho constructor cần sở hữu một `String`

```rust
// GOOD — mượn khi không cần ownership
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

// GOOD — lấy ownership trong constructor qua Into
fn new(name: impl Into<String>) -> Self {
    Self { name: name.into() }
}

// BAD — nhận String trong khi &str là đủ
fn word_count_bad(text: String) -> usize {
    text.split_whitespace().count()
}
```

## Xử lý lỗi

- Dùng `Result<T, E>` và `?` để lan truyền lỗi — không bao giờ `unwrap()` trong code production
- **Thư viện (library)**: định nghĩa lỗi có type bằng `thiserror`
- **Ứng dụng (application)**: dùng `anyhow` để có context lỗi linh hoạt
- Thêm context bằng `.with_context(|| format!("failed to ..."))?`
- Chỉ dành `unwrap()` / `expect()` cho test và các trạng thái thực sự không thể đạt tới

```rust
// GOOD — lỗi của library với thiserror
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("failed to read config: {0}")]
    Io(#[from] std::io::Error),
    #[error("invalid config format: {0}")]
    Parse(String),
}

// GOOD — lỗi của application với anyhow
use anyhow::Context;

fn load_config(path: &str) -> anyhow::Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {path}"))?;
    toml::from_str(&content)
        .with_context(|| format!("failed to parse {path}"))
}
```

## Iterator thay vì vòng lặp

Ưu tiên chuỗi iterator cho các phép biến đổi; dùng vòng lặp cho luồng điều khiển phức tạp:

```rust
// GOOD — khai báo (declarative) và dễ kết hợp
let active_emails: Vec<&str> = users.iter()
    .filter(|u| u.is_active)
    .map(|u| u.email.as_str())
    .collect();

// GOOD — vòng lặp cho logic phức tạp có early return
for user in &users {
    if let Some(verified) = verify_email(&user.email)? {
        send_welcome(&verified)?;
    }
}
```

## Tổ chức module

Tổ chức theo domain, không theo loại:

```text
src/
├── main.rs
├── lib.rs
├── auth/           # Domain module
│   ├── mod.rs
│   ├── token.rs
│   └── middleware.rs
├── orders/         # Domain module
│   ├── mod.rs
│   ├── model.rs
│   └── service.rs
└── db/             # Infrastructure
    ├── mod.rs
    └── pool.rs
```

## Khả năng hiển thị (Visibility)

- Mặc định là private; dùng `pub(crate)` để chia sẻ nội bộ
- Chỉ đánh dấu `pub` những gì thuộc API công khai của crate
- Re-export API công khai từ `lib.rs`

## Tham chiếu

Xem skill: `rust-patterns` để biết đầy đủ idiom và pattern của Rust.
