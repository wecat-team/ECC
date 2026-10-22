---
paths:
  - "**/*.fs"
  - "**/*.fsx"
  - "**/*.fsproj"
---
# Kiểm thử F#

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho F#.

## Test Framework

- Ưu tiên **xUnit** với **FsUnit.xUnit** để có assertion thân thiện với F#
- Dùng **Unquote** cho assertion dựa trên quotation với thông báo lỗi rõ ràng
- Dùng **FsCheck.xUnit** cho property-based testing
- Dùng **NSubstitute** hoặc function stub để mock dependency
- Dùng **Testcontainers** khi integration test cần hạ tầng thật

## Tổ chức Test

- Phản chiếu cấu trúc `src/` dưới `tests/`
- Tách biệt rõ phần unit, integration và end-to-end
- Đặt tên test theo hành vi, không theo chi tiết triển khai

```fsharp
open Xunit
open Swensen.Unquote

[<Fact>]
let ``PlaceOrder returns success when request is valid`` () =
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    test <@ Result.isOk result @>

[<Fact>]
let ``PlaceOrder returns error when items are empty`` () =
    let request = { CustomerId = "cust-123"; Items = [] }
    let result = OrderService.placeOrder request
    test <@ Result.isError result @>
```

## Property-Based Testing với FsCheck

```fsharp
open FsCheck.Xunit

[<Property>]
let ``order total is never negative`` (items: OrderItem list) =
    let total = Order.calculateTotal items
    total >= 0m
```

## Integration Test ASP.NET Core

- Dùng `WebApplicationFactory<TEntryPoint>` để kiểm thử integration cho API
- Test auth, validation và serialization qua HTTP, không bằng cách bỏ qua middleware

## Coverage

- Mục tiêu line coverage 80%+
- Tập trung coverage vào domain logic, validation, auth và các đường lỗi
- Chạy `dotnet test` trong CI với việc thu thập coverage được bật khi có thể
