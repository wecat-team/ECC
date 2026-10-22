---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Phong cách code Go

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Go.

## Định dạng

- **gofmt** và **goimports** là bắt buộc — không tranh cãi về style

## Nguyên tắc thiết kế

- Nhận interface, trả về struct
- Giữ interface nhỏ (1-3 method)

## Xử lý lỗi

Luôn bọc lỗi kèm ngữ cảnh:

```go
if err != nil {
    return fmt.Errorf("failed to create user: %w", err)
}
```

## Tham chiếu

Xem skill: `golang-patterns` để có các idiom và pattern Go toàn diện.
