---
paths:
  - "**/*.fs"
  - "**/*.fsx"
  - "**/*.fsproj"
  - "**/appsettings*.json"
---
# Bảo mật F#

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho F#.

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode API key, token hoặc connection string trong source code
- Dùng biến môi trường, user secrets cho phát triển cục bộ, và secret manager trong production
- Giữ `appsettings.*.json` không chứa credential thật

```fsharp
// BAD
let apiKey = "sk-live-123"

// GOOD
let apiKey =
    configuration["OpenAI:ApiKey"]
    |> Option.ofObj
    |> Option.defaultWith (fun () -> failwith "OpenAI:ApiKey is not configured.")
```

## Phòng chống SQL Injection

- Luôn dùng truy vấn tham số hóa với ADO.NET, Dapper hoặc EF Core
- KHÔNG BAO GIỜ nối input của người dùng vào chuỗi SQL
- Validate các trường sắp xếp và toán tử lọc trước khi dùng cách dựng truy vấn động

```fsharp
let findByCustomer (connection: IDbConnection) customerId =
    task {
        let sql = "SELECT * FROM Orders WHERE CustomerId = @customerId"
        return! connection.QueryAsync<Order>(sql, {| customerId = customerId |})
    }
```

## Kiểm tra đầu vào (Input Validation)

- Validate input tại ranh giới ứng dụng bằng cách dùng type
- Dùng single-case discriminated union cho các giá trị đã được validate
- Từ chối input không hợp lệ trước khi nó đi vào domain logic

```fsharp
type ValidatedEmail = private ValidatedEmail of string

module ValidatedEmail =
    let create (input: string) =
        if System.Text.RegularExpressions.Regex.IsMatch(input, @"^[^@]+@[^@]+\.[^@]+$") then
            Ok(ValidatedEmail input)
        else
            Error "Invalid email address"

    let value (ValidatedEmail v) = v
```

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
