---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Bảo mật Go

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Go.

## Quản lý Secret

```go
apiKey := os.Getenv("OPENAI_API_KEY")
if apiKey == "" {
    log.Fatal("OPENAI_API_KEY not configured")
}
```

## Quét bảo mật

- Dùng **gosec** để phân tích bảo mật tĩnh:
  ```bash
  gosec ./...
  ```

## Context & Timeout

Luôn dùng `context.Context` để kiểm soát timeout:

```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
```
