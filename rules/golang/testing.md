---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Kiểm thử Go

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Go.

## Framework

Dùng `go test` chuẩn với **table-driven test**.

## Phát hiện Race

Luôn chạy với flag `-race`:

```bash
go test -race ./...
```

## Coverage

```bash
go test -cover ./...
```

## Tham chiếu

Xem skill: `golang-testing` để có các pattern và helper kiểm thử Go chi tiết.
