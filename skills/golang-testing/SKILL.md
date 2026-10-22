---
name: golang-testing
description: Pattern testing Go gồm table-driven test, subtest, benchmark, fuzzing và test coverage. Tuân theo phương pháp TDD với thực hành Go idiomatic. Dùng khi viết test Go — table-driven case, subtest, benchmark, fuzzing hoặc coverage.
metadata:
  origin: ECC
---

# Pattern Testing Go

Các pattern testing Go toàn diện để viết test đáng tin cậy, dễ bảo trì theo phương pháp TDD.

## Khi nào kích hoạt

- Viết hàm hoặc method Go mới
- Bổ sung test coverage cho code hiện có
- Tạo benchmark cho code quan trọng về hiệu năng
- Triển khai fuzz test cho input validation
- Theo workflow TDD trong các project Go

## Workflow TDD cho Go

### Chu trình RED-GREEN-REFACTOR

```
RED     → Write a failing test first
GREEN   → Write minimal code to pass the test
REFACTOR → Improve code while keeping tests green
REPEAT  → Continue with next requirement
```

### TDD từng bước trong Go

```go
// Bước 1: Định nghĩa interface/signature
// calculator.go
package calculator

func Add(a, b int) int {
    panic("not implemented") // Placeholder
}

// Bước 2: Viết test thất bại (RED)
// calculator_test.go
package calculator

import "testing"

func TestAdd(t *testing.T) {
    got := Add(2, 3)
    want := 5
    if got != want {
        t.Errorf("Add(2, 3) = %d; want %d", got, want)
    }
}

// Bước 3: Chạy test - xác minh FAIL
// $ go test
// --- FAIL: TestAdd (0.00s)
// panic: not implemented

// Bước 4: Triển khai code tối thiểu (GREEN)
func Add(a, b int) int {
    return a + b
}

// Bước 5: Chạy test - xác minh PASS
// $ go test
// PASS

// Bước 6: Refactor nếu cần, xác minh test vẫn pass
```

## Table-Driven Test

Pattern chuẩn cho test Go. Cho phép coverage toàn diện với lượng code tối thiểu.

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -1, -2, -3},
        {"zero values", 0, 0, 0},
        {"mixed signs", -1, 1, 0},
        {"large numbers", 1000000, 2000000, 3000000},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Table-Driven Test với các trường hợp lỗi

```go
func TestParseConfig(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *Config
        wantErr bool
    }{
        {
            name:  "valid config",
            input: `{"host": "localhost", "port": 8080}`,
            want:  &Config{Host: "localhost", Port: 8080},
        },
        {
            name:    "invalid JSON",
            input:   `{invalid}`,
            wantErr: true,
        },
        {
            name:    "empty input",
            input:   "",
            wantErr: true,
        },
        {
            name:  "minimal config",
            input: `{}`,
            want:  &Config{}, // Zero value config
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseConfig(tt.input)

            if tt.wantErr {
                if err == nil {
                    t.Error("expected error, got nil")
                }
                return
            }

            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }

            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v; want %+v", got, tt.want)
            }
        })
    }
}
```

## Subtest và Sub-benchmark

### Tổ chức các test liên quan

```go
func TestUser(t *testing.T) {
    // Setup dùng chung cho mọi subtest
    db := setupTestDB(t)

    t.Run("Create", func(t *testing.T) {
        user := &User{Name: "Alice"}
        err := db.CreateUser(user)
        if err != nil {
            t.Fatalf("CreateUser failed: %v", err)
        }
        if user.ID == "" {
            t.Error("expected user ID to be set")
        }
    })

    t.Run("Get", func(t *testing.T) {
        user, err := db.GetUser("alice-id")
        if err != nil {
            t.Fatalf("GetUser failed: %v", err)
        }
        if user.Name != "Alice" {
            t.Errorf("got name %q; want %q", user.Name, "Alice")
        }
    })

    t.Run("Update", func(t *testing.T) {
        // ...
    })

    t.Run("Delete", func(t *testing.T) {
        // ...
    })
}
```

### Subtest song song (Parallel)

```go
func TestParallel(t *testing.T) {
    tests := []struct {
        name  string
        input string
    }{
        {"case1", "input1"},
        {"case2", "input2"},
        {"case3", "input3"},
    }

    for _, tt := range tests {
        tt := tt // Capture range variable
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Run subtests in parallel
            result := Process(tt.input)
            // assertions...
            _ = result
        })
    }
}
```

## Test Helper

### Hàm Helper

```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper() // Marks this as a helper function

    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        t.Fatalf("failed to open database: %v", err)
    }

    // Dọn dẹp khi test kết thúc
    t.Cleanup(func() {
        db.Close()
    })

    // Chạy migration
    if _, err := db.Exec(schema); err != nil {
        t.Fatalf("failed to create schema: %v", err)
    }

    return db
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v; want %v", got, want)
    }
}
```

### File và thư mục tạm

```go
func TestFileProcessing(t *testing.T) {
    // Tạo thư mục tạm - tự động được dọn dẹp
    tmpDir := t.TempDir()

    // Tạo file test
    testFile := filepath.Join(tmpDir, "test.txt")
    err := os.WriteFile(testFile, []byte("test content"), 0644)
    if err != nil {
        t.Fatalf("failed to create test file: %v", err)
    }

    // Chạy test
    result, err := ProcessFile(testFile)
    if err != nil {
        t.Fatalf("ProcessFile failed: %v", err)
    }

    // Assert...
    _ = result
}
```

## Golden File

Test dựa trên các file output kỳ vọng được lưu trong `testdata/`.

```go
var update = flag.Bool("update", false, "update golden files")

func TestRender(t *testing.T) {
    tests := []struct {
        name  string
        input Template
    }{
        {"simple", Template{Name: "test"}},
        {"complex", Template{Name: "test", Items: []string{"a", "b"}}},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Render(tt.input)

            golden := filepath.Join("testdata", tt.name+".golden")

            if *update {
                // Cập nhật golden file: go test -update
                err := os.WriteFile(golden, got, 0644)
                if err != nil {
                    t.Fatalf("failed to update golden file: %v", err)
                }
            }

            want, err := os.ReadFile(golden)
            if err != nil {
                t.Fatalf("failed to read golden file: %v", err)
            }

            if !bytes.Equal(got, want) {
                t.Errorf("output mismatch:\ngot:\n%s\nwant:\n%s", got, want)
            }
        })
    }
}
```

## Mocking với Interface

### Mocking dựa trên Interface

```go
// Định nghĩa interface cho các dependency
type UserRepository interface {
    GetUser(id string) (*User, error)
    SaveUser(user *User) error
}

// Implementation cho production
type PostgresUserRepository struct {
    db *sql.DB
}

func (r *PostgresUserRepository) GetUser(id string) (*User, error) {
    // Truy vấn database thật
}

// Implementation mock cho test
type MockUserRepository struct {
    GetUserFunc  func(id string) (*User, error)
    SaveUserFunc func(user *User) error
}

func (m *MockUserRepository) GetUser(id string) (*User, error) {
    return m.GetUserFunc(id)
}

func (m *MockUserRepository) SaveUser(user *User) error {
    return m.SaveUserFunc(user)
}

// Test dùng mock
func TestUserService(t *testing.T) {
    mock := &MockUserRepository{
        GetUserFunc: func(id string) (*User, error) {
            if id == "123" {
                return &User{ID: "123", Name: "Alice"}, nil
            }
            return nil, ErrNotFound
        },
    }

    service := NewUserService(mock)

    user, err := service.GetUserProfile("123")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "Alice" {
        t.Errorf("got name %q; want %q", user.Name, "Alice")
    }
}
```

## Benchmark

### Benchmark cơ bản

```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData(1000)
    b.ResetTimer() // Don't count setup time

    for i := 0; i < b.N; i++ {
        Process(data)
    }
}

// Chạy: go test -bench=BenchmarkProcess -benchmem
// Kết quả: BenchmarkProcess-8   10000   105234 ns/op   4096 B/op   10 allocs/op
```

### Benchmark với các kích thước khác nhau

```go
func BenchmarkSort(b *testing.B) {
    sizes := []int{100, 1000, 10000, 100000}

    for _, size := range sizes {
        b.Run(fmt.Sprintf("size=%d", size), func(b *testing.B) {
            data := generateRandomSlice(size)
            b.ResetTimer()

            for i := 0; i < b.N; i++ {
                // Tạo bản sao để tránh sort dữ liệu đã được sort
                tmp := make([]int, len(data))
                copy(tmp, data)
                sort.Ints(tmp)
            }
        })
    }
}
```

### Benchmark cấp phát bộ nhớ

```go
func BenchmarkStringConcat(b *testing.B) {
    parts := []string{"hello", "world", "foo", "bar", "baz"}

    b.Run("plus", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            var s string
            for _, p := range parts {
                s += p
            }
            _ = s
        }
    })

    b.Run("builder", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            var sb strings.Builder
            for _, p := range parts {
                sb.WriteString(p)
            }
            _ = sb.String()
        }
    })

    b.Run("join", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            _ = strings.Join(parts, "")
        }
    })
}
```

## Fuzzing (Go 1.18+)

### Fuzz Test cơ bản

```go
func FuzzParseJSON(f *testing.F) {
    // Thêm seed corpus
    f.Add(`{"name": "test"}`)
    f.Add(`{"count": 123}`)
    f.Add(`[]`)
    f.Add(`""`)

    f.Fuzz(func(t *testing.T, input string) {
        var result map[string]interface{}
        err := json.Unmarshal([]byte(input), &result)

        if err != nil {
            // JSON không hợp lệ là điều dự kiến với input ngẫu nhiên
            return
        }

        // Nếu parse thành công, việc encode lại phải hoạt động
        _, err = json.Marshal(result)
        if err != nil {
            t.Errorf("Marshal failed after successful Unmarshal: %v", err)
        }
    })
}

// Chạy: go test -fuzz=FuzzParseJSON -fuzztime=30s
```

### Fuzz Test với nhiều Input

```go
func FuzzCompare(f *testing.F) {
    f.Add("hello", "world")
    f.Add("", "")
    f.Add("abc", "abc")

    f.Fuzz(func(t *testing.T, a, b string) {
        result := Compare(a, b)

        // Property: Compare(a, a) phải luôn bằng 0
        if a == b && result != 0 {
            t.Errorf("Compare(%q, %q) = %d; want 0", a, b, result)
        }

        // Property: Compare(a, b) và Compare(b, a) phải có dấu trái ngược nhau
        reverse := Compare(b, a)
        if (result > 0 && reverse >= 0) || (result < 0 && reverse <= 0) {
            if result != 0 || reverse != 0 {
                t.Errorf("Compare(%q, %q) = %d, Compare(%q, %q) = %d; inconsistent",
                    a, b, result, b, a, reverse)
            }
        }
    })
}
```

## Test Coverage

### Chạy Coverage

```bash
# Coverage cơ bản
go test -cover ./...

# Tạo coverage profile
go test -coverprofile=coverage.out ./...

# Xem coverage trong trình duyệt
go tool cover -html=coverage.out

# Xem coverage theo hàm
go tool cover -func=coverage.out

# Coverage kèm race detection
go test -race -coverprofile=coverage.out ./...
```

### Mục tiêu Coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Business logic quan trọng | 100% |
| Public API | 90%+ |
| Code thông thường | 80%+ |
| Code sinh tự động | Loại trừ |

### Loại trừ code sinh tự động khỏi Coverage

```go
//go:generate mockgen -source=interface.go -destination=mock_interface.go

// Trong coverage profile, loại trừ bằng build tag:
// go test -cover -tags=!generate ./...
```

## Test HTTP Handler

```go
func TestHealthHandler(t *testing.T) {
    // Tạo request
    req := httptest.NewRequest(http.MethodGet, "/health", nil)
    w := httptest.NewRecorder()

    // Gọi handler
    HealthHandler(w, req)

    // Kiểm tra response
    resp := w.Result()
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("got status %d; want %d", resp.StatusCode, http.StatusOK)
    }

    body, _ := io.ReadAll(resp.Body)
    if string(body) != "OK" {
        t.Errorf("got body %q; want %q", body, "OK")
    }
}

func TestAPIHandler(t *testing.T) {
    tests := []struct {
        name       string
        method     string
        path       string
        body       string
        wantStatus int
        wantBody   string
    }{
        {
            name:       "get user",
            method:     http.MethodGet,
            path:       "/users/123",
            wantStatus: http.StatusOK,
            wantBody:   `{"id":"123","name":"Alice"}`,
        },
        {
            name:       "not found",
            method:     http.MethodGet,
            path:       "/users/999",
            wantStatus: http.StatusNotFound,
        },
        {
            name:       "create user",
            method:     http.MethodPost,
            path:       "/users",
            body:       `{"name":"Bob"}`,
            wantStatus: http.StatusCreated,
        },
    }

    handler := NewAPIHandler()

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            var body io.Reader
            if tt.body != "" {
                body = strings.NewReader(tt.body)
            }

            req := httptest.NewRequest(tt.method, tt.path, body)
            req.Header.Set("Content-Type", "application/json")
            w := httptest.NewRecorder()

            handler.ServeHTTP(w, req)

            if w.Code != tt.wantStatus {
                t.Errorf("got status %d; want %d", w.Code, tt.wantStatus)
            }

            if tt.wantBody != "" && w.Body.String() != tt.wantBody {
                t.Errorf("got body %q; want %q", w.Body.String(), tt.wantBody)
            }
        })
    }
}
```

## Lệnh Testing

```bash
# Chạy tất cả test
go test ./...

# Chạy test với output chi tiết
go test -v ./...

# Chạy test cụ thể
go test -run TestAdd ./...

# Chạy test khớp pattern
go test -run "TestUser/Create" ./...

# Chạy test với race detector
go test -race ./...

# Chạy test với coverage
go test -cover -coverprofile=coverage.out ./...

# Chỉ chạy short test
go test -short ./...

# Chạy test với timeout
go test -timeout 30s ./...

# Chạy benchmark
go test -bench=. -benchmem ./...

# Chạy fuzzing
go test -fuzz=FuzzParse -fuzztime=30s ./...

# Đếm số lần chạy test (để phát hiện flaky test)
go test -count=10 ./...
```

## Best Practice

**NÊN:**
- Viết test TRƯỚC (TDD)
- Dùng table-driven test để có coverage toàn diện
- Test hành vi, không test implementation
- Dùng `t.Helper()` trong các hàm helper
- Dùng `t.Parallel()` cho các test độc lập
- Dọn dẹp tài nguyên bằng `t.Cleanup()`
- Dùng tên test có ý nghĩa mô tả kịch bản

**KHÔNG NÊN:**
- Test trực tiếp các hàm private (test thông qua public API)
- Dùng `time.Sleep()` trong test (dùng channel hoặc điều kiện)
- Bỏ qua flaky test (sửa hoặc xóa chúng)
- Mock mọi thứ (ưu tiên integration test khi có thể)
- Bỏ qua test đường đi lỗi

## Tích hợp với CI/CD

```yaml
# Ví dụ GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
      with:
        go-version: '1.22'

    - name: Run tests
      run: go test -race -coverprofile=coverage.out ./...

    - name: Check coverage
      run: |
        go tool cover -func=coverage.out | grep total | awk '{print $3}' | \
        awk -F'%' '{if ($1 < 80) exit 1}'
```

**Hãy nhớ**: Test là tài liệu. Chúng cho thấy code của bạn được dùng như thế nào. Hãy viết chúng rõ ràng và luôn cập nhật.
