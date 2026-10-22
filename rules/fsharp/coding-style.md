---
paths:
  - "**/*.fs"
  - "**/*.fsx"
---
# Phong cách code F#

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho F#.

## Tiêu chuẩn

- Tuân theo các quy ước F# chuẩn và tận dụng hệ thống kiểu để đảm bảo tính đúng đắn
- Mặc định ưu tiên bất biến (immutability); chỉ dùng `mutable` khi có lý do về hiệu năng
- Giữ module tập trung và gắn kết

## Type và Model

- Ưu tiên discriminated union để mô hình hóa domain thay vì hệ phân cấp class
- Dùng record cho dữ liệu có các field được đặt tên
- Dùng single-case union làm wrapper an toàn kiểu quanh các kiểu nguyên thủy
- Tránh class trừ khi interop hoặc mutable state đòi hỏi

```fsharp
type EmailAddress = EmailAddress of string

type OrderStatus =
    | Pending
    | Confirmed of confirmedAt: DateTimeOffset
    | Shipped of trackingNumber: string
    | Cancelled of reason: string

type Order =
    { Id: Guid
      CustomerId: string
      Status: OrderStatus
      Items: OrderItem list }
```

## Bất biến (Immutability)

- Record mặc định là bất biến; dùng biểu thức `with` để cập nhật
- Ưu tiên `list`, `map`, `set` hơn các collection khả biến
- Tránh `ref` cell và field mutable trong domain logic

```fsharp
let rename (profile: UserProfile) newName =
    { profile with Name = newName }
```

## Phong cách hàm

- Ưu tiên các hàm nhỏ, có thể kết hợp thay vì method lớn
- Dùng pipe operator `|>` để xây dựng data pipeline dễ đọc
- Ưu tiên pattern matching hơn chuỗi if/else
- Dùng `Option` thay cho null; dùng `Result` cho các thao tác có thể thất bại

```fsharp
let processOrder order =
    order
    |> validateItems
    |> Result.bind calculateTotal
    |> Result.map applyDiscount
    |> Result.mapError OrderError
```

## Async và xử lý lỗi

- Dùng `task { }` để interop với các API async của .NET
- Dùng `async { }` cho các workflow async gốc của F#
- Truyền `CancellationToken` qua các API async public
- Ưu tiên `Result` và railway-oriented programming hơn exception cho các lỗi có thể dự đoán

```fsharp
let loadOrderAsync (orderId: Guid) (ct: CancellationToken) =
    task {
        let! order = repository.FindAsync(orderId, ct)
        return
            order
            |> Option.defaultWith (fun () ->
                failwith $"Order {orderId} was not found.")
    }
```

## Định dạng

- Dùng `fantomas` để format tự động
- Ưu tiên significant whitespace; tránh dấu ngoặc không cần thiết
- Xóa các khai báo `open` không dùng

### Thứ tự khai báo Open

Nhóm các câu lệnh `open` thành bốn phần cách nhau bằng một dòng trống, mỗi phần được sắp xếp theo thứ tự từ điển bên trong nó:

1. `System.*`
2. `Microsoft.*`
3. Namespace của bên thứ ba
4. Namespace nội bộ / của dự án

```fsharp
open System
open System.Collections.Generic
open System.Threading.Tasks

open Microsoft.AspNetCore.Http
open Microsoft.Extensions.Logging

open FsCheck.Xunit
open Swensen.Unquote

open MyApp.Domain
open MyApp.Infrastructure
```
