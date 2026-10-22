---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Pattern Swift

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung riêng cho Swift.

## Thiết kế hướng Protocol

Định nghĩa các protocol nhỏ, tập trung. Dùng protocol extension cho các mặc định dùng chung:

```swift
protocol Repository: Sendable {
    associatedtype Item: Identifiable & Sendable
    func find(by id: Item.ID) async throws -> Item?
    func save(_ item: Item) async throws
}
```

## Value Type

- Dùng struct cho data transfer object và model
- Dùng enum với associated value để mô hình hóa các trạng thái riêng biệt:

```swift
enum LoadState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}
```

## Actor Pattern

Dùng actor cho shared mutable state thay vì lock hoặc dispatch queue:

```swift
actor Cache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    func get(_ key: Key) -> Value? { storage[key] }
    func set(_ key: Key, value: Value) { storage[key] = value }
}
```

## Dependency Injection

Inject protocol với tham số mặc định — production dùng mặc định, test inject mock:

```swift
struct UserService {
    private let repository: any UserRepository

    init(repository: any UserRepository = DefaultUserRepository()) {
        self.repository = repository
    }
}
```

## Tham chiếu

Xem skill: `swift-actor-persistence` để biết các pattern persistence dựa trên actor.
Xem skill: `swift-protocol-di-testing` để biết DI và kiểm thử dựa trên protocol.
