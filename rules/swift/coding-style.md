---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Coding Style Swift

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho Swift.

## Định dạng

- **SwiftFormat** để tự động định dạng, **SwiftLint** để thực thi style
- `swift-format` được đi kèm trong Xcode 16+ như một lựa chọn thay thế

## Bất biến (Immutability)

- Ưu tiên `let` hơn `var` — định nghĩa mọi thứ bằng `let` và chỉ đổi sang `var` nếu compiler yêu cầu
- Mặc định dùng `struct` với value semantics; chỉ dùng `class` khi cần identity hoặc reference semantics

## Đặt tên

Tuân theo [Apple API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):

- Rõ ràng tại điểm sử dụng — bỏ các từ thừa
- Đặt tên method và property theo vai trò của chúng, không theo type
- Dùng `static let` cho hằng số thay vì hằng số toàn cục

## Xử lý lỗi

Dùng typed throws (Swift 6+) và pattern matching:

```swift
func load(id: String) throws(LoadError) -> Item {
    guard let data = try? read(from: path) else {
        throw .fileNotFound(id)
    }
    return try decode(data)
}
```

## Concurrency

Bật kiểm tra strict concurrency của Swift 6. Ưu tiên:

- Value type `Sendable` cho dữ liệu đi qua ranh giới isolation
- Actor cho shared mutable state
- Structured concurrency (`async let`, `TaskGroup`) hơn `Task {}` không có cấu trúc
