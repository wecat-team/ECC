---
description: Code review toàn diện cho Go về pattern idiomatic, an toàn đồng thời (concurrency), xử lý lỗi và bảo mật. Gọi agent go-reviewer.
---

# Go Code Review

Command này gọi agent **go-reviewer** để code review toàn diện dành riêng cho Go.

## Command này làm gì

1. **Xác định thay đổi Go**: Tìm các file `.go` đã sửa qua `git diff`
2. **Chạy phân tích tĩnh**: Thực thi `go vet`, `staticcheck` và `golangci-lint`
3. **Quét bảo mật**: Kiểm tra SQL injection, command injection, race condition
4. **Review concurrency**: Phân tích độ an toàn của goroutine, cách dùng channel, pattern mutex
5. **Kiểm tra Go idiomatic**: Xác minh code tuân theo quy ước và best practice của Go
6. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng

## Khi nào dùng

Dùng `/go-review` khi:
- Sau khi viết hoặc sửa code Go
- Trước khi commit các thay đổi Go
- Review pull request có code Go
- Làm quen với một codebase Go mới
- Học các pattern Go idiomatic

## Các nhóm review

### CRITICAL (PHẢI sửa)
- Lỗ hổng SQL/Command injection
- Race condition không có đồng bộ hóa
- Rò rỉ goroutine
- Credential bị hardcode
- Dùng unsafe pointer
- Bỏ qua lỗi ở các đường dẫn quan trọng

### HIGH (Nên sửa)
- Thiếu error wrapping kèm context
- Dùng panic thay vì trả về error
- Context không được truyền đi
- Unbuffered channel gây deadlock
- Lỗi interface không được thỏa mãn
- Thiếu bảo vệ bằng mutex

### MEDIUM (Cân nhắc)
- Pattern code không idiomatic
- Thiếu godoc comment cho các thành phần export
- Nối chuỗi kém hiệu quả
- Slice không được cấp phát trước
- Không dùng table-driven test

## Các kiểm tra tự động được chạy

```bash
# Static analysis
go vet ./...

# Advanced checks (if installed)
staticcheck ./...
golangci-lint run

# Race detection
go build -race ./...

# Security vulnerabilities
govulncheck ./...
```

## Ví dụ sử dụng

```text
User: /go-review

Agent:
# Go Code Review Report

## Files Reviewed
- internal/handler/user.go (modified)
- internal/service/auth.go (modified)

## Static Analysis Results
✓ go vet: No issues
✓ staticcheck: No issues

## Issues Found

[CRITICAL] Race Condition
File: internal/service/auth.go:45
Issue: Shared map accessed without synchronization
```go
var cache = map[string]*Session{}  // Concurrent access!

func GetSession(id string) *Session {
    return cache[id]  // Race condition
}
```
Fix: Use sync.RWMutex or sync.Map
```go
var (
    cache   = map[string]*Session{}
    cacheMu sync.RWMutex
)

func GetSession(id string) *Session {
    cacheMu.RLock()
    defer cacheMu.RUnlock()
    return cache[id]
}
```

[HIGH] Missing Error Context
File: internal/handler/user.go:28
Issue: Error returned without context
```go
return err  // No context
```
Fix: Wrap with context
```go
return fmt.Errorf("get user %s: %w", userID, err)
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
```

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|--------|-----------|
| PASS: Approve | Không có vấn đề CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| FAIL: Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các command khác

- Dùng `/go-test` trước để đảm bảo test thành công
- Dùng `/go-build` nếu có lỗi build
- Dùng `/go-review` trước khi commit
- Dùng `/code-review` cho các mối quan tâm không đặc thù của Go

## Liên quan

- Agent: `agents/go-reviewer.md`
- Skills: `skills/golang-patterns/`, `skills/golang-testing/`
