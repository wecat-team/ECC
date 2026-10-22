---
name: error-handling
description: "Các pattern xử lý lỗi (error handling) vững chắc cho TypeScript, Python và Go. Bao gồm typed error, error boundary, retry, circuit breaker và thông báo lỗi hướng tới người dùng. Dùng khi thiết kế error type, retry, circuit breaker hoặc thông báo lỗi cho người dùng trong TypeScript, Python hoặc Go."
metadata:
  origin: ECC
---

# Pattern xử lý lỗi

Các pattern xử lý lỗi nhất quán, vững chắc cho ứng dụng production.

## Khi nào kích hoạt

- Thiết kế error type hoặc phân cấp exception cho module hoặc service mới
- Thêm logic retry hoặc circuit breaker cho các dependency bên ngoài không đáng tin cậy
- Review API endpoint thiếu xử lý lỗi
- Triển khai thông báo lỗi và phản hồi cho người dùng
- Debug lỗi dây chuyền (cascading failure) hoặc lỗi bị nuốt âm thầm

## Nguyên tắc cốt lõi

1. **Fail fast và fail rõ ràng** — đưa lỗi lên ngay tại ranh giới nơi chúng xảy ra; đừng chôn vùi chúng
2. **Typed error hơn thông báo dạng chuỗi** — lỗi là giá trị hạng nhất (first-class) có cấu trúc
3. **Thông báo cho người dùng ≠ thông báo cho developer** — hiển thị văn bản thân thiện cho người dùng, log đầy đủ ngữ cảnh phía server
4. **KHÔNG BAO GIỜ nuốt lỗi âm thầm** — mọi khối `catch` PHẢI xử lý, re-throw hoặc log
5. **Lỗi là một phần của API contract** — ghi tài liệu mọi mã lỗi mà client có thể nhận

## TypeScript / JavaScript

### Typed Error Class

```typescript
// Define an error hierarchy for your domain
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly details?: unknown,
  ) {
    super(message)
    this.name = this.constructor.name
    // Maintain correct prototype chain in transpiled ES5 JavaScript.
    // Required for `instanceof` checks (e.g., `error instanceof NotFoundError`)
    // to work correctly when extending the built-in Error class.
    Object.setPrototypeOf(this, new.target.prototype)
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404)
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details: { field: string; message: string }[]) {
    super(message, 'VALIDATION_ERROR', 422, details)
  }
}

export class UnauthorizedError extends AppError {
  constructor(reason = 'Authentication required') {
    super(reason, 'UNAUTHORIZED', 401)
  }
}

export class RateLimitError extends AppError {
  constructor(public readonly retryAfterMs: number) {
    super('Rate limit exceeded', 'RATE_LIMITED', 429)
  }
}
```

### Result Pattern (kiểu không throw)

Cho các thao tác mà thất bại là điều dự kiến và phổ biến (parsing, gọi bên ngoài):

```typescript
type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

function ok<T>(value: T): Result<T> {
  return { ok: true, value }
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error }
}

// Usage
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.users.findUnique({ where: { id } })
    if (!user) return err(new NotFoundError('User', id))
    return ok(user)
  } catch (e) {
    return err(new AppError('Database error', 'DB_ERROR'))
  }
}

const result = await fetchUser('abc-123')
if (!result.ok) {
  // TypeScript knows result.error here
  logger.error('Failed to fetch user', { error: result.error })
  return
}
// TypeScript knows result.value here
console.log(result.value.email)
```

### API Error Handler (Next.js / Express)

```typescript
import { NextRequest, NextResponse } from 'next/server'

function handleApiError(error: unknown): NextResponse {
  // Known application error
  if (error instanceof AppError) {
    return NextResponse.json(
      {
        error: {
          code: error.code,
          message: error.message,
          ...(error.details ? { details: error.details } : {}),
        },
      },
      { status: error.statusCode },
    )
  }

  // Zod validation error
  if (error instanceof z.ZodError) {
    return NextResponse.json(
      {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: error.issues.map(i => ({
            field: i.path.join('.'),
            message: i.message,
          })),
        },
      },
      { status: 422 },
    )
  }

  // Unexpected error — log details, return generic message
  console.error('Unexpected error:', error)
  return NextResponse.json(
    { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } },
    { status: 500 },
  )
}

export async function POST(req: NextRequest) {
  try {
    // ... handler logic
  } catch (error) {
    return handleApiError(error)
  }
}
```

### React Error Boundary

```typescript
import { Component, ErrorInfo, ReactNode } from 'react'

interface Props {
  fallback: ReactNode
  onError?: (error: Error, info: ErrorInfo) => void
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    this.props.onError?.(error, info)
    console.error('Unhandled React error:', error, info)
  }

  render() {
    if (this.state.hasError) return this.props.fallback
    return this.props.children
  }
}

// Usage
<ErrorBoundary fallback={<p>Something went wrong. Please refresh.</p>}>
  <MyComponent />
</ErrorBoundary>
```

## Python

### Phân cấp Exception tùy chỉnh

```python
class AppError(Exception):
    """Base application error."""
    def __init__(self, message: str, code: str, status_code: int = 500):
        super().__init__(message)
        self.code = code
        self.status_code = status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(f"{resource} not found: {id}", "NOT_FOUND", 404)

class ValidationError(AppError):
    def __init__(self, message: str, details: list[dict] | None = None):
        super().__init__(message, "VALIDATION_ERROR", 422)
        self.details = details or []
```

### FastAPI Global Exception Handler

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": str(exc)}},
    )

@app.exception_handler(Exception)
async def generic_error_handler(request: Request, exc: Exception) -> JSONResponse:
    # Log full details, return generic message
    logger.exception("Unexpected error", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={"error": {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred"}},
    )
```

## Go

### Sentinel Error và Error Wrapping

```go
package domain

import "errors"

// Sentinel errors for type-checking
var (
    ErrNotFound    = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
)

// Wrap errors with context — never lose the original
func (r *UserRepository) FindByID(ctx context.Context, id string) (*User, error) {
    user, err := r.db.QueryRow(ctx, "SELECT * FROM users WHERE id = $1", id)
    if errors.Is(err, sql.ErrNoRows) {
        return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
    }
    if err != nil {
        return nil, fmt.Errorf("querying user %s: %w", id, err)
    }
    return user, nil
}

// At the handler level, unwrap to determine response
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.GetUser(r.Context(), chi.URLParam(r, "id"))
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrNotFound):
            writeError(w, http.StatusNotFound, "not_found", err.Error())
        case errors.Is(err, domain.ErrUnauthorized):
            writeError(w, http.StatusForbidden, "forbidden", "Access denied")
        default:
            slog.Error("unexpected error", "err", err)
            writeError(w, http.StatusInternalServerError, "internal_error", "An unexpected error occurred")
        }
        return
    }
    writeJSON(w, http.StatusOK, user)
}
```

## Retry với Exponential Backoff

```typescript
interface RetryOptions {
  maxAttempts?: number
  baseDelayMs?: number
  maxDelayMs?: number
  retryIf?: (error: unknown) => boolean
}

async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelayMs = 500,
    maxDelayMs = 10_000,
    retryIf = () => true,
  } = options

  let lastError: unknown

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error
      if (attempt === maxAttempts || !retryIf(error)) throw error

      const jitter = Math.random() * baseDelayMs
      const delay = Math.min(baseDelayMs * 2 ** (attempt - 1) + jitter, maxDelayMs)
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }

  throw lastError
}

// Usage: retry transient network errors, not 4xx
const data = await withRetry(() => fetch('/api/data').then(r => r.json()), {
  maxAttempts: 3,
  retryIf: (error) => !(error instanceof AppError && error.statusCode < 500),
})
```

## Thông báo lỗi hướng tới người dùng

Ánh xạ mã lỗi sang thông báo dễ đọc với con người. Giữ chi tiết kỹ thuật ra khỏi văn bản người dùng nhìn thấy.

```typescript
const USER_ERROR_MESSAGES: Record<string, string> = {
  NOT_FOUND: 'The requested item could not be found.',
  UNAUTHORIZED: 'Please sign in to continue.',
  FORBIDDEN: "You don't have permission to do that.",
  VALIDATION_ERROR: 'Please check your input and try again.',
  RATE_LIMITED: 'Too many requests. Please wait a moment and try again.',
  INTERNAL_ERROR: 'Something went wrong on our end. Please try again later.',
}

export function getUserMessage(code: string): string {
  return USER_ERROR_MESSAGES[code] ?? USER_ERROR_MESSAGES.INTERNAL_ERROR
}
```

## Checklist xử lý lỗi

Trước khi merge bất kỳ code nào chạm tới xử lý lỗi:

- [ ] Mọi khối `catch` đều xử lý, re-throw hoặc log — không nuốt lỗi âm thầm
- [ ] Lỗi API tuân theo envelope chuẩn `{ error: { code, message } }`
- [ ] Thông báo hướng tới người dùng không chứa stack trace hay chi tiết nội bộ
- [ ] Ngữ cảnh lỗi đầy đủ được log phía server
- [ ] Custom error class kế thừa một `AppError` cơ sở có trường `code`
- [ ] Hàm async đưa lỗi lên cho caller — không fire-and-forget mà thiếu fallback
- [ ] Logic retry chỉ retry các lỗi có thể retry (không phải lỗi client 4xx)
- [ ] Component React được bọc trong `ErrorBoundary` để xử lý lỗi render
