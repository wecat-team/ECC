---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Pattern Go

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Go.

## Functional Options

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

## Interface nhỏ

Định nghĩa interface ở nơi chúng được dùng, không phải nơi chúng được triển khai.

## Dependency Injection

Dùng constructor function để inject dependency:

```go
func NewUserService(repo UserRepository, logger Logger) *UserService {
    return &UserService{repo: repo, logger: logger}
}
```

## Tham chiếu

Xem skill: `golang-patterns` để có các pattern Go toàn diện, bao gồm concurrency, xử lý lỗi và tổ chức package.
