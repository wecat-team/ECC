---
description: Sửa từng bước các lỗi build Go, warning của go vet và vấn đề linter. Gọi agent go-build-resolver để sửa tối thiểu, chính xác.
---

# Go Build và Fix

Command này gọi agent **go-build-resolver** để sửa từng bước các lỗi build Go với thay đổi tối thiểu.

## Command này làm gì

1. **Chạy chẩn đoán**: Thực thi `go build`, `go vet`, `staticcheck`
2. **Phân tích lỗi**: Nhóm theo file và sắp xếp theo mức độ nghiêm trọng
3. **Sửa từng bước**: Mỗi lần một lỗi
4. **Xác minh từng bản sửa**: Chạy lại build sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Hiển thị những gì đã sửa và những gì còn lại

## Khi nào dùng

Dùng `/go-build` khi:
- `go build ./...` thất bại với lỗi
- `go vet ./...` báo vấn đề
- `golangci-lint run` hiển thị warning
- Module dependency bị hỏng
- Sau khi pull các thay đổi làm hỏng build

## Các lệnh chẩn đoán được chạy

```bash
# Primary build check
go build ./...

# Static analysis
go vet ./...

# Extended linting (if available)
staticcheck ./...
golangci-lint run

# Module issues
go mod verify
go mod tidy -v
```

## Phiên làm việc ví dụ

```text
User: /go-build

Agent:
# Go Build Resolution

## Initial Diagnostics

```bash
$ go build ./...
internal/service/user.go:25:15: undefined: UserRepository
internal/handler/api.go:42:9: cannot use x (type string) as type int
internal/handler/api.go:58:2: missing return at end of function
```

Errors found: 3

## Fix 1: Undefined Identifier

File: internal/service/user.go:25
Error: undefined: UserRepository
Cause: Missing import

```go
// Added import
import "project/internal/repository"

// Changed
var repo UserRepository
// To
var repo repository.UserRepository
```

```bash
$ go build ./...
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: internal/handler/api.go:42
Error: cannot use x (type string) as type int

```go
// Changed
count := params.Get("count")
// To
countStr := params.Get("count")
count, _ := strconv.Atoi(countStr)
```

```bash
$ go build ./...
# 1 error remaining
```

## Fix 3: Missing Return

File: internal/handler/api.go:58
Error: missing return at end of function

```go
func GetUser(id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidID
    }
    user := findUser(id)
    // Added missing return
    return user, nil
}
```

```bash
$ go build ./...
# Build successful!
```

## Final Verification

```bash
$ go vet ./...
# No issues

$ go test ./...
ok      project/internal/service   0.015s
ok      project/internal/handler   0.023s
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Vet warnings fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
```

## Các lỗi thường gặp đã sửa

| Lỗi | Cách sửa điển hình |
|-------|-------------|
| `undefined: X` | Thêm import hoặc sửa lỗi gõ |
| `cannot use X as Y` | Chuyển đổi kiểu hoặc sửa phép gán |
| `missing return` | Thêm câu lệnh return |
| `X does not implement Y` | Thêm method còn thiếu |
| `import cycle` | Tái cấu trúc package |
| `declared but not used` | Xóa hoặc sử dụng biến |
| `cannot find package` | `go get` or `go mod tidy` |

## Chiến lược sửa lỗi

1. **Lỗi build trước** - Code phải compile được
2. **Warning của vet thứ hai** - Sửa các cấu trúc đáng ngờ
3. **Warning của lint thứ ba** - Style và best practice
4. **Mỗi lần một bản sửa** - Xác minh từng thay đổi
5. **Thay đổi tối thiểu** - Không refactor, chỉ sửa

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:
- Cùng một lỗi vẫn còn sau 3 lần thử
- Bản sửa gây thêm lỗi
- Cần thay đổi kiến trúc
- Thiếu dependency bên ngoài

## Các command liên quan

- `/go-test` - Chạy test sau khi build thành công
- `/go-review` - Review chất lượng code
- skill `verification-loop` - Vòng lặp xác minh đầy đủ

## Liên quan

- Agent: `agents/go-build-resolver.md`
- Skill: `skills/golang-patterns/`
