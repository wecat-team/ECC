---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---
# Hook Rust

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung riêng cho Rust.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **cargo fmt**: Tự động định dạng các file `.rs` sau khi sửa
- **cargo clippy**: Chạy kiểm tra lint sau khi sửa file Rust
- **cargo check**: Xác minh biên dịch được sau các thay đổi (nhanh hơn `cargo build`)
