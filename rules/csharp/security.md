---
paths:
  - "**/*.cs"
  - "**/*.csx"
  - "**/*.csproj"
  - "**/appsettings*.json"
---
# Bảo mật C#

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho C#.

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode API key, token hoặc connection string trong source code
- Dùng biến môi trường, user secrets cho phát triển cục bộ, và secret manager trong production
- Giữ `appsettings.*.json` không chứa credential thật

```csharp
// BAD
const string ApiKey = "sk-live-123";

// GOOD
var apiKey = builder.Configuration["OpenAI:ApiKey"]
    ?? throw new InvalidOperationException("OpenAI:ApiKey is not configured.");
```

## Phòng chống SQL Injection

- Luôn dùng truy vấn tham số hóa với ADO.NET, Dapper hoặc EF Core
- KHÔNG BAO GIỜ nối input của người dùng vào chuỗi SQL
- Validate các trường sắp xếp và toán tử lọc trước khi dùng cách dựng truy vấn động

```csharp
const string sql = "SELECT * FROM Orders WHERE CustomerId = @customerId";
await connection.QueryAsync<Order>(sql, new { customerId });
```

## Kiểm tra đầu vào (Input Validation)

- Validate DTO tại ranh giới ứng dụng
- Dùng data annotation, FluentValidation hoặc guard clause tường minh
- Từ chối model state không hợp lệ trước khi chạy business logic

## Authentication và Authorization

- Ưu tiên auth handler của framework thay vì tự parse token
- Áp dụng authorization policy tại ranh giới endpoint hoặc handler
- KHÔNG BAO GIỜ log token thô, mật khẩu hoặc PII

## Xử lý lỗi

- Trả về thông báo an toàn cho phía client
- Log exception chi tiết kèm ngữ cảnh có cấu trúc ở phía server
- Không để lộ stack trace, nội dung SQL hoặc đường dẫn filesystem trong API response

## Tham chiếu

Xem skill: `security-review` để có các checklist security review ứng dụng rộng hơn.
