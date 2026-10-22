---
paths:
  - "**/*.fs"
  - "**/*.fsx"
---
# Pattern F#

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho F#.

## Result Type cho xử lý lỗi

Dùng `Result<'T, 'TError>` với railway-oriented programming thay vì exception cho các lỗi có thể dự đoán.

```fsharp
type OrderError =
    | InvalidCustomer of string
    | EmptyItems
    | ItemOutOfStock of sku: string

let validateOrder (request: CreateOrderRequest) : Result<ValidatedOrder, OrderError> =
    if String.IsNullOrWhiteSpace request.CustomerId then
        Error(InvalidCustomer "CustomerId is required")
    elif request.Items |> List.isEmpty then
        Error EmptyItems
    else
        Ok { CustomerId = request.CustomerId; Items = request.Items }
```

## Option cho giá trị bị thiếu

Ưu tiên `Option<'T>` hơn null. Dùng `Option.map`, `Option.bind` và `Option.defaultValue` để biến đổi.

```fsharp
let findUser (id: Guid) : User option =
    users |> Map.tryFind id

let getUserEmail userId =
    findUser userId
    |> Option.map (fun u -> u.Email)
    |> Option.defaultValue "unknown@example.com"
```

## Discriminated Union để mô hình hóa Domain

Mô hình hóa các trạng thái nghiệp vụ một cách tường minh. Compiler ép buộc xử lý đầy đủ mọi trường hợp.

```fsharp
type PaymentState =
    | AwaitingPayment of amount: decimal
    | Paid of paidAt: DateTimeOffset * transactionId: string
    | Refunded of refundedAt: DateTimeOffset * reason: string
    | Failed of error: string

let describePayment = function
    | AwaitingPayment amount -> $"Awaiting payment of {amount:C}"
    | Paid (at, txn) -> $"Paid at {at} (txn: {txn})"
    | Refunded (at, reason) -> $"Refunded at {at}: {reason}"
    | Failed error -> $"Payment failed: {error}"
```

## Computation Expression

Dùng computation expression để đơn giản hóa các thao tác tuần tự có thể thất bại.

```fsharp
let placeOrder request =
    result {
        let! validated = validateOrder request
        let! inventory = checkInventory validated.Items
        let! order = createOrder validated inventory
        return order
    }
```

## Tổ chức Module

- Nhóm các hàm liên quan trong module thay vì class
- Dùng `[<RequireQualifiedAccess>]` để tránh xung đột tên
- Giữ module nhỏ và tập trung vào một trách nhiệm duy nhất

```fsharp
[<RequireQualifiedAccess>]
module Order =
    let create customerId items = { Id = Guid.NewGuid(); CustomerId = customerId; Items = items; Status = Pending }
    let confirm order = { order with Status = Confirmed(DateTimeOffset.UtcNow) }
    let cancel reason order = { order with Status = Cancelled reason }
```

## Dependency Injection

- Định nghĩa dependency dưới dạng tham số hàm hoặc record-of-functions
- Dùng interface một cách hạn chế, chủ yếu ở ranh giới với các thư viện .NET
- Ưu tiên partial application để inject dependency vào pipeline

```fsharp
type OrderDeps =
    { FindOrder: Guid -> Task<Order option>
      SaveOrder: Order -> Task<unit>
      SendNotification: Order -> Task<unit> }

let processOrder (deps: OrderDeps) orderId =
    task {
        match! deps.FindOrder orderId with
        | None -> return Error "Order not found"
        | Some order ->
            let confirmed = Order.confirm order
            do! deps.SaveOrder confirmed
            do! deps.SendNotification confirmed
            return Ok confirmed
    }
```
