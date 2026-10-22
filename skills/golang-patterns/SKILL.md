---
name: golang-patterns
description: Pattern Go idiomatic, best practice và quy ước để xây dựng ứng dụng Go mạnh mẽ, hiệu quả và dễ bảo trì. Dùng khi viết hoặc review code Go và có thắc mắc về cấu trúc idiomatic hay quy ước.
metadata:
  origin: ECC
---

# Pattern phát triển Go

Các pattern Go idiomatic và best practice để xây dựng ứng dụng mạnh mẽ, hiệu quả và dễ bảo trì.

## Khi nào kích hoạt

- Viết code Go mới
- Review code Go
- Refactor code Go hiện có
- Thiết kế package/module Go

## Nguyên tắc cốt lõi

### 1. Đơn giản và rõ ràng

Go ưu tiên sự đơn giản hơn sự khéo léo. Code phải hiển nhiên và dễ đọc.

```go
// Good: Rõ ràng và trực tiếp
func GetUser(id string) (*User, error) {
    user, err := db.FindUser(id)
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return user, nil
}

// Bad: Quá khéo léo
func GetUser(id string) (*User, error) {
    return func() (*User, error) {
        if u, e := db.FindUser(id); e == nil {
            return u, nil
        } else {
            return nil, e
        }
    }()
}
```

### 2. Làm cho Zero Value hữu ích

Thiết kế type sao cho zero value của nó dùng được ngay mà không cần khởi tạo.

```go
// Good: Zero value hữu ích
type Counter struct {
    mu    sync.Mutex
    count int // zero value is 0, ready to use
}

func (c *Counter) Inc() {
    c.mu.Lock()
    c.count++
    c.mu.Unlock()
}

// Good: bytes.Buffer hoạt động với zero value
var buf bytes.Buffer
buf.WriteString("hello")

// Bad: Đòi hỏi khởi tạo
type BadCounter struct {
    counts map[string]int // nil map will panic
}
```

### 3. Nhận Interface, trả về Struct

Hàm nên nhận tham số là interface và trả về kiểu cụ thể.

```go
// Good: Nhận interface, trả về kiểu cụ thể
func ProcessData(r io.Reader) (*Result, error) {
    data, err := io.ReadAll(r)
    if err != nil {
        return nil, err
    }
    return &Result{Data: data}, nil
}

// Bad: Trả về interface (che giấu chi tiết triển khai một cách không cần thiết)
func ProcessData(r io.Reader) (io.Reader, error) {
    // ...
}
```

## Pattern xử lý lỗi

### Bọc lỗi (Error Wrapping) kèm ngữ cảnh

```go
// Good: Bọc lỗi kèm ngữ cảnh
func LoadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("load config %s: %w", path, err)
    }

    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parse config %s: %w", path, err)
    }

    return &cfg, nil
}
```

### Kiểu lỗi tùy chỉnh

```go
// Định nghĩa lỗi đặc thù theo domain
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Sentinel error cho các trường hợp phổ biến
var (
    ErrNotFound     = errors.New("resource not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrInvalidInput = errors.New("invalid input")
)
```

### Kiểm tra lỗi với errors.Is và errors.As

```go
func HandleError(err error) {
    // Kiểm tra lỗi cụ thể
    if errors.Is(err, sql.ErrNoRows) {
        log.Println("No records found")
        return
    }

    // Kiểm tra kiểu lỗi
    var validationErr *ValidationError
    if errors.As(err, &validationErr) {
        log.Printf("Validation error on field %s: %s",
            validationErr.Field, validationErr.Message)
        return
    }

    // Lỗi không xác định
    log.Printf("Unexpected error: %v", err)
}
```

### KHÔNG BAO GIỜ bỏ qua lỗi

```go
// Bad: Bỏ qua lỗi bằng blank identifier
result, _ := doSomething()

// Good: Xử lý hoặc ghi chú rõ ràng lý do vì sao bỏ qua là an toàn
result, err := doSomething()
if err != nil {
    return err
}

// Chấp nhận được: Khi lỗi thực sự không quan trọng (hiếm)
_ = writer.Close() // Best-effort cleanup, error logged elsewhere
```

## Pattern Concurrency

### Worker Pool

```go
func WorkerPool(jobs <-chan Job, results chan<- Result, numWorkers int) {
    var wg sync.WaitGroup

    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                results <- process(job)
            }
        }()
    }

    wg.Wait()
    close(results)
}
```

### Context cho Cancellation và Timeout

```go
func FetchWithTimeout(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, fmt.Errorf("create request: %w", err)
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("fetch %s: %w", url, err)
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}
```

### Graceful Shutdown

```go
func GracefulShutdown(server *http.Server) {
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

    <-quit
    log.Println("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }

    log.Println("Server exited")
}
```

### errgroup để điều phối Goroutine

```go
import "golang.org/x/sync/errgroup"

func FetchAll(ctx context.Context, urls []string) ([][]byte, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([][]byte, len(urls))

    for i, url := range urls {
        i, url := i, url // Capture loop variables
        g.Go(func() error {
            data, err := FetchWithTimeout(ctx, url)
            if err != nil {
                return err
            }
            results[i] = data
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

### Tránh rò rỉ Goroutine

```go
// Bad: Rò rỉ goroutine nếu context bị cancel
func leakyFetch(ctx context.Context, url string) <-chan []byte {
    ch := make(chan []byte)
    go func() {
        data, _ := fetch(url)
        ch <- data // Blocks forever if no receiver
    }()
    return ch
}

// Good: Xử lý cancellation đúng cách
func safeFetch(ctx context.Context, url string) <-chan []byte {
    ch := make(chan []byte, 1) // Buffered channel
    go func() {
        data, err := fetch(url)
        if err != nil {
            return
        }
        select {
        case ch <- data:
        case <-ctx.Done():
        }
    }()
    return ch
}
```

## Thiết kế Interface

### Interface nhỏ, tập trung

```go
// Good: Interface một method
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type Closer interface {
    Close() error
}

// Kết hợp các interface khi cần
type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}
```

### Định nghĩa Interface ở nơi chúng được dùng

```go
// Trong package của consumer, không phải provider
package service

// UserStore định nghĩa những gì service này cần
type UserStore interface {
    GetUser(id string) (*User, error)
    SaveUser(user *User) error
}

type Service struct {
    store UserStore
}

// Implementation cụ thể có thể nằm ở package khác
// Nó không cần biết về interface này
```

### Hành vi tùy chọn với Type Assertion

```go
type Flusher interface {
    Flush() error
}

func WriteAndFlush(w io.Writer, data []byte) error {
    if _, err := w.Write(data); err != nil {
        return err
    }

    // Flush nếu được hỗ trợ
    if f, ok := w.(Flusher); ok {
        return f.Flush()
    }
    return nil
}
```

## Tổ chức Package

### Bố cục project chuẩn

```text
myproject/
├── cmd/
│   └── myapp/
│       └── main.go           # Entry point
├── internal/
│   ├── handler/              # HTTP handlers
│   ├── service/              # Business logic
│   ├── repository/           # Data access
│   └── config/               # Configuration
├── pkg/
│   └── client/               # Public API client
├── api/
│   └── v1/                   # API definitions (proto, OpenAPI)
├── testdata/                 # Test fixtures
├── go.mod
├── go.sum
└── Makefile
```

### Đặt tên Package

```go
// Good: Ngắn, chữ thường, không có dấu gạch dưới
package http
package json
package user

// Bad: Dài dòng, lẫn chữ hoa thường, hoặc thừa
package httpHandler
package json_parser
package userService // Redundant 'Service' suffix
```

### Tránh State ở cấp Package

```go
// Bad: State toàn cục có thể thay đổi
var db *sql.DB

func init() {
    db, _ = sql.Open("postgres", os.Getenv("DATABASE_URL"))
}

// Good: Dependency injection
type Server struct {
    db *sql.DB
}

func NewServer(db *sql.DB) *Server {
    return &Server{db: db}
}
```

## Thiết kế Struct

### Pattern Functional Options

```go
type Server struct {
    addr    string
    timeout time.Duration
    logger  *log.Logger
}

type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) {
        s.timeout = d
    }
}

func WithLogger(l *log.Logger) Option {
    return func(s *Server) {
        s.logger = l
    }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{
        addr:    addr,
        timeout: 30 * time.Second, // default
        logger:  log.Default(),    // default
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Cách dùng
server := NewServer(":8080",
    WithTimeout(60*time.Second),
    WithLogger(customLogger),
)
```

### Embedding để Composition

```go
type Logger struct {
    prefix string
}

func (l *Logger) Log(msg string) {
    fmt.Printf("[%s] %s\n", l.prefix, msg)
}

type Server struct {
    *Logger // Embedding - Server gets Log method
    addr    string
}

func NewServer(addr string) *Server {
    return &Server{
        Logger: &Logger{prefix: "SERVER"},
        addr:   addr,
    }
}

// Cách dùng
s := NewServer(":8080")
s.Log("Starting...") // Calls embedded Logger.Log
```

## Bộ nhớ và Hiệu năng

### Cấp phát trước Slice khi biết kích thước

```go
// Bad: Slice phải tăng nhiều lần
func processItems(items []Item) []Result {
    var results []Result
    for _, item := range items {
        results = append(results, process(item))
    }
    return results
}

// Good: Chỉ một lần cấp phát
func processItems(items []Item) []Result {
    results := make([]Result, 0, len(items))
    for _, item := range items {
        results = append(results, process(item))
    }
    return results
}
```

### Dùng sync.Pool cho các cấp phát thường xuyên

```go
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func ProcessRequest(data []byte) []byte {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()

    buf.Write(data)
    // Xử lý...
    return buf.Bytes()
}
```

### Tránh nối chuỗi trong vòng lặp

```go
// Bad: Tạo ra nhiều cấp phát string
func join(parts []string) string {
    var result string
    for _, p := range parts {
        result += p + ","
    }
    return result
}

// Good: Một lần cấp phát với strings.Builder
func join(parts []string) string {
    var sb strings.Builder
    for i, p := range parts {
        if i > 0 {
            sb.WriteString(",")
        }
        sb.WriteString(p)
    }
    return sb.String()
}

// Best: Dùng thư viện chuẩn
func join(parts []string) string {
    return strings.Join(parts, ",")
}
```

## Tích hợp công cụ Go

### Lệnh thiết yếu

```bash
# Build và chạy
go build ./...
go run ./cmd/myapp

# Testing
go test ./...
go test -race ./...
go test -cover ./...

# Phân tích tĩnh
go vet ./...
staticcheck ./...
golangci-lint run

# Quản lý module
go mod tidy
go mod verify

# Định dạng
gofmt -w .
goimports -w .
```

### Cấu hình Linter được khuyến nghị (.golangci.yml)

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - misspell
    - unconvert
    - unparam

linters-settings:
  errcheck:
    check-type-assertions: true
  govet:
    enable:
      - shadow

issues:
  exclude-use-default: false
```

## Tham chiếu nhanh: Go Idiom

| Idiom | Mô tả |
|-------|-------------|
| Accept interfaces, return structs | Hàm nhận tham số interface, trả về kiểu cụ thể |
| Errors are values | Coi lỗi là giá trị hạng nhất, không phải exception |
| Don't communicate by sharing memory | Dùng channel để điều phối giữa các goroutine |
| Make the zero value useful | Type nên hoạt động mà không cần khởi tạo tường minh |
| A little copying is better than a little dependency | Tránh các dependency bên ngoài không cần thiết |
| Clear is better than clever | Ưu tiên độ dễ đọc hơn sự khéo léo |
| gofmt is no one's favorite but everyone's friend | Luôn format bằng gofmt/goimports |
| Return early | Xử lý lỗi trước, giữ happy path không thụt lề |

## Anti-Pattern cần tránh

```go
// Bad: Naked return trong hàm dài
func process() (result int, err error) {
    // ... 50 lines ...
    return // What is being returned?
}

// Bad: Dùng panic cho control flow
func GetUser(id string) *User {
    user, err := db.Find(id)
    if err != nil {
        panic(err) // Don't do this
    }
    return user
}

// Bad: Truyền context trong struct
type Request struct {
    ctx context.Context // Context should be first param
    ID  string
}

// Good: Context là tham số đầu tiên
func ProcessRequest(ctx context.Context, id string) error {
    // ...
}

// Bad: Trộn value receiver và pointer receiver
type Counter struct{ n int }
func (c Counter) Value() int { return c.n }    // Value receiver
func (c *Counter) Increment() { c.n++ }        // Pointer receiver
// Chọn một kiểu và nhất quán
```

**Hãy nhớ**: Code Go nên "nhàm chán" theo nghĩa tốt nhất — dễ đoán, nhất quán và dễ hiểu. Khi phân vân, hãy giữ đơn giản.
