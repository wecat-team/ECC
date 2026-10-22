---
name: api-design
description: Các pattern thiết kế REST API gồm đặt tên resource, status code, pagination, filtering, error response, versioning và rate limiting cho API production. Dùng khi thiết kế hoặc review REST endpoint, tên resource, status code, pagination hoặc versioning.
metadata:
  origin: ECC
---

# Các Pattern thiết kế API

Quy ước và best practice để thiết kế REST API nhất quán, thân thiện với developer.

## Khi nào kích hoạt

- Thiết kế API endpoint mới
- Review các API contract hiện có
- Thêm pagination, filtering hoặc sorting
- Triển khai xử lý lỗi cho API
- Lập kế hoạch chiến lược versioning cho API
- Xây dựng API công khai hoặc API dành cho đối tác

## Thiết kế Resource

### Cấu trúc URL

```
# Resources are nouns, plural, lowercase, kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# Sub-resources for relationships
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# Actions that don't map to CRUD (use verbs sparingly)
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### Quy tắc đặt tên

```
# GOOD
/api/v1/team-members          # kebab-case for multi-word resources
/api/v1/orders?status=active  # query params for filtering
/api/v1/users/123/orders      # nested resources for ownership

# BAD
/api/v1/getUsers              # verb in URL
/api/v1/user                  # singular (use plural)
/api/v1/team_members          # snake_case in URLs
/api/v1/users/123/getOrders   # verb in nested resource
```

## HTTP Method và Status Code

### Ngữ nghĩa của Method

| Method | Idempotent | Safe | Dùng cho |
|--------|-----------|------|---------|
| GET | Có | Có | Lấy resource |
| POST | Không | Không | Tạo resource, kích hoạt action |
| PUT | Có | Không | Thay thế toàn bộ một resource |
| PATCH | Không* | Không | Cập nhật một phần resource |
| DELETE | Có | Không | Xóa một resource |

*PATCH có thể được làm idempotent nếu triển khai đúng cách

### Tham chiếu Status Code

```
# Success
200 OK                    — GET, PUT, PATCH (with response body)
201 Created               — POST (include Location header)
204 No Content            — DELETE, PUT (no response body)

# Client Errors
400 Bad Request           — Validation failure, malformed JSON
401 Unauthorized          — Missing or invalid authentication
403 Forbidden             — Authenticated but not authorized
404 Not Found             — Resource doesn't exist
409 Conflict              — Duplicate entry, state conflict
422 Unprocessable Entity  — Semantically invalid (valid JSON, bad data)
429 Too Many Requests     — Rate limit exceeded

# Server Errors
500 Internal Server Error — Unexpected failure (never expose details)
502 Bad Gateway           — Upstream service failed
503 Service Unavailable   — Temporary overload, include Retry-After
```

### Các lỗi thường gặp

```
# BAD: 200 for everything
{ "status": 200, "success": false, "error": "Not found" }

# GOOD: Use HTTP status codes semantically
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }

# BAD: 500 for validation errors
# GOOD: 400 or 422 with field-level details

# BAD: 200 for created resources
# GOOD: 201 with Location header
HTTP/1.1 201 Created
Location: /api/v1/users/abc-123
```

## Định dạng Response

### Success Response

```json
{
  "data": {
    "id": "abc-123",
    "email": "alice@example.com",
    "name": "Alice",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

### Collection Response (kèm Pagination)

```json
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": {
    "total": 142,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1&per_page=20",
    "next": "/api/v1/users?page=2&per_page=20",
    "last": "/api/v1/users?page=8&per_page=20"
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "code": "invalid_format"
      },
      {
        "field": "age",
        "message": "Must be between 0 and 150",
        "code": "out_of_range"
      }
    ]
  }
}
```

### Các biến thể Response Envelope

```typescript
// Option A: Envelope with data wrapper (recommended for public APIs)
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
  links?: PaginationLinks;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: FieldError[];
  };
}

// Option B: Flat response (simpler, common for internal APIs)
// Success: just return the resource directly
// Error: return error object
// Distinguish by HTTP status code
```

## Pagination

### Dựa trên Offset (Đơn giản)

```
GET /api/v1/users?page=2&per_page=20

# Implementation
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

**Ưu điểm:** Dễ triển khai, hỗ trợ "nhảy tới trang N"
**Nhược điểm:** Chậm khi offset lớn (OFFSET 100000), không nhất quán khi có insert đồng thời

### Dựa trên Cursor (Khả năng mở rộng)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

# Implementation
SELECT * FROM users
WHERE id > :cursor_id
ORDER BY id ASC
LIMIT 21;  -- fetch one extra to determine has_next
```

```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTQzfQ"
  }
}
```

**Ưu điểm:** Hiệu năng ổn định bất kể vị trí, ổn định khi có insert đồng thời
**Nhược điểm:** Không thể nhảy tới trang tùy ý, cursor là opaque (không đọc được)

### Khi nào dùng loại nào

| Trường hợp | Loại Pagination |
|----------|----------------|
| Dashboard quản trị, dataset nhỏ (<10K) | Offset |
| Infinite scroll, feed, dataset lớn | Cursor |
| API công khai | Cursor (mặc định) kèm offset (tùy chọn) |
| Kết quả tìm kiếm | Offset (người dùng kỳ vọng có số trang) |

## Filtering, Sorting và Search

### Filtering

```
# Simple equality
GET /api/v1/orders?status=active&customer_id=abc-123

# Comparison operators (use bracket notation)
GET /api/v1/products?price[gte]=10&price[lte]=100
GET /api/v1/orders?created_at[after]=2025-01-01

# Multiple values (comma-separated)
GET /api/v1/products?category=electronics,clothing

# Nested fields (dot notation)
GET /api/v1/orders?customer.country=US
```

### Sorting

```
# Single field (prefix - for descending)
GET /api/v1/products?sort=-created_at

# Multiple fields (comma-separated)
GET /api/v1/products?sort=-featured,price,-created_at
```

### Full-Text Search

```
# Search query parameter
GET /api/v1/products?q=wireless+headphones

# Field-specific search
GET /api/v1/users?email=alice
```

### Sparse Fieldset

```
# Return only specified fields (reduces payload)
GET /api/v1/users?fields=id,name,email
GET /api/v1/orders?fields=id,total,status&include=customer.name
```

## Authentication và Authorization

### Token-Based Auth

```
# Bearer token in Authorization header
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API key (for server-to-server)
GET /api/v1/data
X-API-Key: sk_live_...
```

### Các Pattern Authorization

```typescript
// Resource-level: check ownership
app.get("/api/v1/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: { code: "not_found" } });
  if (order.userId !== req.user.id) return res.status(403).json({ error: { code: "forbidden" } });
  return res.json({ data: order });
});

// Role-based: check permissions
app.delete("/api/v1/users/:id", requireRole("admin"), async (req, res) => {
  await User.delete(req.params.id);
  return res.status(204).send();
});
```

## Rate Limiting

### Header

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

# When exceeded
HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds."
  }
}
```

### Các bậc Rate Limit

| Bậc | Giới hạn | Cửa sổ | Trường hợp dùng |
|------|-------|--------|----------|
| Anonymous | 30/min | Theo IP | Endpoint công khai |
| Authenticated | 100/min | Theo người dùng | Truy cập API tiêu chuẩn |
| Premium | 1000/min | Theo API key | Gói API trả phí |
| Internal | 10000/min | Theo service | Service-to-service |

## Versioning

### Versioning theo URL Path (Khuyến nghị)

```
/api/v1/users
/api/v2/users
```

**Ưu điểm:** Tường minh, dễ routing, có thể cache
**Nhược điểm:** URL thay đổi giữa các phiên bản

### Versioning theo Header

```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**Ưu điểm:** URL gọn gàng
**Nhược điểm:** Khó test hơn, dễ quên

### Chiến lược Versioning

```
1. Start with /api/v1/ — don't version until you need to
2. Maintain at most 2 active versions (current + previous)
3. Deprecation timeline:
   - Announce deprecation (6 months notice for public APIs)
   - Add Sunset header: Sunset: Sat, 01 Jan 2026 00:00:00 GMT
   - Return 410 Gone after sunset date
4. Non-breaking changes don't need a new version:
   - Adding new fields to responses
   - Adding new optional query parameters
   - Adding new endpoints
5. Breaking changes require a new version:
   - Removing or renaming fields
   - Changing field types
   - Changing URL structure
   - Changing authentication method
```

## Các Pattern triển khai

### TypeScript (Next.js API Route)

```typescript
import { z } from "zod";
import { NextRequest, NextResponse } from "next/server";

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createUserSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({
          field: i.path.join("."),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 });
  }

  const user = await createUser(parsed.data);

  return NextResponse.json(
    { data: user },
    {
      status: 201,
      headers: { Location: `/api/v1/users/${user.id}` },
    },
  );
}
```

### Python (Django REST Framework)

```python
from rest_framework import serializers, viewsets, status
from rest_framework.response import Response

class CreateUserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    name = serializers.CharField(max_length=100)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "name", "created_at"]

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateUserSerializer
        return UserSerializer

    def create(self, request):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = UserService.create(**serializer.validated_data)
        return Response(
            {"data": UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
            headers={"Location": f"/api/v1/users/{user.id}"},
        )
```

### Go (net/http)

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid_json", "Invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "validation_error", err.Error())
        return
    }

    user, err := h.service.Create(r.Context(), req)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrEmailTaken):
            writeError(w, http.StatusConflict, "email_taken", "Email already registered")
        default:
            writeError(w, http.StatusInternalServerError, "internal_error", "Internal error")
        }
        return
    }

    w.Header().Set("Location", fmt.Sprintf("/api/v1/users/%s", user.ID))
    writeJSON(w, http.StatusCreated, map[string]any{"data": user})
}
```

## Checklist thiết kế API

Trước khi ship một endpoint mới:

- [ ] URL resource tuân theo quy ước đặt tên (số nhiều, kebab-case, không có động từ)
- [ ] Dùng đúng HTTP method (GET để đọc, POST để tạo, v.v.)
- [ ] Trả về status code phù hợp (không dùng 200 cho mọi thứ)
- [ ] Input được validate bằng schema (Zod, Pydantic, Bean Validation)
- [ ] Error response tuân theo định dạng chuẩn với code và message
- [ ] Đã triển khai pagination cho các list endpoint (cursor hoặc offset)
- [ ] Yêu cầu authentication (hoặc được đánh dấu tường minh là công khai)
- [ ] Đã kiểm tra authorization (người dùng chỉ truy cập được resource của chính mình)
- [ ] Đã cấu hình rate limiting
- [ ] Response không làm lộ chi tiết nội bộ (stack trace, lỗi SQL)
- [ ] Đặt tên nhất quán với các endpoint hiện có (camelCase so với snake_case)
- [ ] Đã có tài liệu (spec OpenAPI/Swagger đã được cập nhật)
