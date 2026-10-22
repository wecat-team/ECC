---
description: Áp dụng quy trình TDD cho Go. Viết table-driven test trước, rồi mới triển khai. Xác minh coverage 80%+ bằng go test -cover.
---

# Lệnh Go TDD

Command này áp dụng phương pháp phát triển hướng kiểm thử (TDD) cho code Go, sử dụng các pattern testing idiomatic của Go.

## Command này làm gì

1. **Định nghĩa Type/Interface**: Dựng sườn chữ ký hàm trước
2. **Viết Table-Driven Test**: Tạo các test case toàn diện (RED)
3. **Chạy test**: Xác minh test thất bại đúng lý do
4. **Triển khai code**: Viết code tối thiểu để pass (GREEN)
5. **Refactor**: Cải thiện trong khi giữ test xanh
6. **Kiểm tra coverage**: Đảm bảo coverage từ 80% trở lên

## Khi nào dùng

Dùng `/go-test` khi:
- Triển khai các hàm Go mới
- Bổ sung test coverage cho code hiện có
- Sửa bug (viết test thất bại trước)
- Xây dựng business logic quan trọng
- Học quy trình TDD trong Go

## Chu trình TDD

```
RED     → Write failing table-driven test
GREEN   → Implement minimal code to pass
REFACTOR → Improve code, tests stay green
REPEAT  → Next test case
```

## Phiên làm việc ví dụ

````
User: /go-test I need a function to validate email addresses

Agent:
# TDD Session: Email Validator

## Step 1: Define Interface

```go
// validator/email.go
package validator

// ValidateEmail checks if the given string is a valid email address.
// Returns nil if valid, error describing the issue otherwise.
func ValidateEmail(email string) error {
    panic("not implemented")
}
```

## Step 2: Write Table-Driven Tests (RED)

```go
// validator/email_test.go
package validator

import (
    "testing"
)

func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        // Valid emails
        {"simple email", "user@example.com", false},
        {"with subdomain", "user@mail.example.com", false},
        {"with plus", "user+tag@example.com", false},
        {"with dots", "first.last@example.com", false},

        // Invalid emails
        {"empty string", "", true},
        {"no at sign", "userexample.com", true},
        {"no domain", "user@", true},
        {"no local part", "@example.com", true},
        {"double at", "user@@example.com", true},
        {"spaces", "user @example.com", true},
        {"no tld", "user@example", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr && err == nil {
                t.Errorf("ValidateEmail(%q) = nil; want error", tt.email)
            }
            if !tt.wantErr && err != nil {
                t.Errorf("ValidateEmail(%q) = %v; want nil", tt.email, err)
            }
        })
    }
}
```

## Step 3: Run Tests - Verify FAIL

```bash
$ go test ./validator/...

--- FAIL: TestValidateEmail (0.00s)
    --- FAIL: TestValidateEmail/simple_email (0.00s)
        panic: not implemented

FAIL
```

✓ Tests fail as expected (panic).

## Step 4: Implement Minimal Code (GREEN)

```go
// validator/email.go
package validator

import (
    "errors"
    "regexp"
)

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

var (
    ErrEmailEmpty   = errors.New("email cannot be empty")
    ErrEmailInvalid = errors.New("email format is invalid")
)

func ValidateEmail(email string) error {
    if email == "" {
        return ErrEmailEmpty
    }
    if !emailRegex.MatchString(email) {
        return ErrEmailInvalid
    }
    return nil
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ go test ./validator/...

PASS
ok      project/validator    0.003s
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ go test -cover ./validator/...

PASS
coverage: 100.0% of statements
ok      project/validator    0.003s
```

✓ Coverage: 100%

## TDD Complete!
````

## Các pattern test

### Table-Driven Test
```go
tests := []struct {
    name     string
    input    InputType
    want     OutputType
    wantErr  bool
}{
    {"case 1", input1, want1, false},
    {"case 2", input2, want2, true},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Function(tt.input)
        // assertions
    })
}
```

### Parallel Test
```go
for _, tt := range tests {
    tt := tt // Capture
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // test body
    })
}
```

### Test Helper
```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db := createDB()
    t.Cleanup(func() { db.Close() })
    return db
}
```

## Các lệnh coverage

```bash
# Basic coverage
go test -cover ./...

# Coverage profile
go test -coverprofile=coverage.out ./...

# View in browser
go tool cover -html=coverage.out

# Coverage by function
go tool cover -func=coverage.out

# With race detection
go test -race -cover ./...
```

## Mục tiêu coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Business logic quan trọng | 100% |
| API công khai | 90%+ |
| Code thông thường | 80%+ |
| Code được sinh tự động | Loại trừ |

## Best practice của TDD

**NÊN:**
- Viết test TRƯỚC, trước bất kỳ phần triển khai nào
- Chạy test sau mỗi thay đổi
- Dùng table-driven test để có coverage toàn diện
- Test hành vi, không test chi tiết triển khai
- Bao gồm các edge case (rỗng, nil, giá trị tối đa)

**KHÔNG NÊN:**
- Viết phần triển khai trước test
- Bỏ qua pha RED
- Test trực tiếp các hàm private
- Dùng `time.Sleep` trong test
- Bỏ qua các flaky test

## Các command liên quan

- `/go-build` - Sửa lỗi build
- `/go-review` - Review code sau khi triển khai
- skill `verification-loop` - Chạy vòng lặp xác minh đầy đủ

## Liên quan

- Skill: `skills/golang-testing/`
- Skill: `skills/tdd-workflow/`
