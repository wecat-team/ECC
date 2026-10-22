---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Kiểm thử Swift

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung riêng cho Swift.

## Framework

Dùng **Swift Testing** (`import Testing`) cho test mới. Dùng `@Test` và `#expect`:

```swift
@Test("User creation validates email")
func userCreationValidatesEmail() throws {
    #expect(throws: ValidationError.invalidEmail) {
        try User(email: "not-an-email")
    }
}
```

## Cô lập test (Test Isolation)

Mỗi test nhận một instance mới — thiết lập trong `init`, dọn dẹp trong `deinit`. Không có shared mutable state giữa các test.

## Test tham số hóa

```swift
@Test("Validates formats", arguments: ["json", "xml", "csv"])
func validatesFormat(format: String) throws {
    let parser = try Parser(format: format)
    #expect(parser.isValid)
}
```

## Coverage

```bash
swift test --enable-code-coverage
```

## Tham chiếu

Xem skill: `swift-protocol-di-testing` để biết dependency injection dựa trên protocol và các pattern mock với Swift Testing.
