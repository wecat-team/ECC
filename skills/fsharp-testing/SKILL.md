---
name: fsharp-testing
description: Pattern testing F# với xUnit, FsUnit, Unquote, property-based testing bằng FsCheck, integration test và best practice tổ chức test. Dùng khi viết test F# với xUnit, FsUnit, Unquote hoặc FsCheck.
metadata:
  origin: ECC
---

# Pattern Testing F#

Các pattern testing toàn diện cho ứng dụng F# dùng xUnit, FsUnit, Unquote, FsCheck và thực hành testing .NET hiện đại.

## Khi nào kích hoạt

- Viết test mới cho code F#
- Review chất lượng test và coverage
- Thiết lập hạ tầng test cho project F#
- Debug test flaky hoặc chậm

## Bộ framework test

| Công cụ | Mục đích |
|---|---|
| **xUnit** | Test framework (lựa chọn chuẩn của hệ sinh thái .NET) |
| **FsUnit.xUnit** | Cú pháp assertion thân thiện với F# cho xUnit |
| **Unquote** | Thư viện assertion dùng F# quotation để có thông báo lỗi rõ ràng |
| **FsCheck.xUnit** | Property-based testing tích hợp với xUnit |
| **NSubstitute** | Mock các dependency .NET |
| **Testcontainers** | Hạ tầng thật trong integration test |
| **WebApplicationFactory** | Integration test cho ASP.NET Core |

## Unit Test với xUnit + FsUnit

### Cấu trúc test cơ bản

```fsharp
module OrderServiceTests

open Xunit
open FsUnit.Xunit

[<Fact>]
let ``create sets status to Pending`` () =
    let order = Order.create "cust-1" [ validItem ]
    order.Status |> should equal Pending

[<Fact>]
let ``confirm changes status to Confirmed`` () =
    let order = Order.create "cust-1" [ validItem ]
    let confirmed = Order.confirm order
    confirmed.Status |> should be (ofCase <@ Confirmed @>)
```

### Assertion với Unquote

Unquote dùng F# quotation nên thông báo lỗi hiển thị toàn bộ biểu thức thất bại, không chỉ "expected X got Y".

```fsharp
module OrderValidationTests

open Xunit
open Swensen.Unquote

[<Fact>]
let ``PlaceOrder returns success when request is valid`` () =
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    test <@ Result.isOk result @>

[<Fact>]
let ``order total sums item prices`` () =
    let items = [ { Sku = "A"; Quantity = 2; Price = 10m }
                  { Sku = "B"; Quantity = 1; Price = 5m } ]
    let total = Order.calculateTotal items
    test <@ total = 25m @>

[<Fact>]
let ``validated email rejects empty input`` () =
    let result = ValidatedEmail.create ""
    test <@ Result.isError result @>
```

### Test bất đồng bộ (Async)

```fsharp
[<Fact>]
let ``PlaceOrder returns success when request is valid`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isOk result @>
}

[<Fact>]
let ``PlaceOrder returns error when items are empty`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isError result @>
}
```

### Test tham số hóa với Theory

```fsharp
[<Theory>]
[<InlineData("")>]
[<InlineData("   ")>]
let ``PlaceOrder rejects empty customer ID`` (customerId: string) =
    let request = { CustomerId = customerId; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    result |> should be (ofCase <@ Error @>)

[<Theory>]
[<InlineData("", false)>]
[<InlineData("a", false)>]
[<InlineData("user@example.com", true)>]
[<InlineData("user+tag@example.co.uk", true)>]
let ``IsValidEmail returns expected result`` (email: string, expected: bool) =
    test <@ EmailValidator.isValid email = expected @>
```

## Property-Based Testing với FsCheck

### Dùng FsCheck.xUnit

```fsharp
open FsCheck
open FsCheck.Xunit

[<Property>]
let ``order total is always non-negative`` (items: NonEmptyList<PositiveInt * decimal>) =
    let orderItems =
        items.Get
        |> List.map (fun (qty, price) ->
            { Sku = "SKU"; Quantity = qty.Get; Price = abs price })
    let total = Order.calculateTotal orderItems
    total >= 0m

[<Property>]
let ``serialization roundtrips`` (order: Order) =
    let json = JsonSerializer.Serialize order
    let deserialized = JsonSerializer.Deserialize<Order> json
    deserialized = order
```

### Generator tùy chỉnh

```fsharp
type OrderGenerators =
    static member ValidEmail () =
        gen {
            let! user = Gen.elements [ "alice"; "bob"; "carol" ]
            let! domain = Gen.elements [ "example.com"; "test.org" ]
            return $"{user}@{domain}"
        }
        |> Arb.fromGen

[<Property(Arbitrary = [| typeof<OrderGenerators> |])>]
let ``valid emails pass validation`` (email: string) =
    EmailValidator.isValid email
```

## Mock Dependency

### Function Stub (Ưu tiên)

```fsharp
let createTestDeps () =
    let mutable savedOrders = []
    { FindOrder = fun id -> task { return Map.tryFind id testData }
      SaveOrder = fun order -> task { savedOrders <- order :: savedOrders }
      SendNotification = fun _ -> Task.CompletedTask }

[<Fact>]
let ``PlaceOrder saves the confirmed order`` () = task {
    let mutable saved = []
    let deps =
        { createTestDeps () with
            SaveOrder = fun order -> task { saved <- order :: saved } }

    let! _ = OrderService.placeOrder deps validRequest

    test <@ saved.Length = 1 @>
}
```

### NSubstitute cho Interface .NET

```fsharp
open NSubstitute

[<Fact>]
let ``calls repository with correct ID`` () = task {
    let repo = Substitute.For<IOrderRepository>()
    repo.FindByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
        .Returns(Task.FromResult(Some testOrder))

    let service = OrderService(repo)
    let! _ = service.GetOrder(testOrder.Id, CancellationToken.None)

    do! repo.Received(1).FindByIdAsync(testOrder.Id, Arg.Any<CancellationToken>())
}
```

## Integration Test cho ASP.NET Core

```fsharp
type OrderApiTests (factory: WebApplicationFactory<Program>) =
    interface IClassFixture<WebApplicationFactory<Program>>

    let client =
        factory.WithWebHostBuilder(fun builder ->
            builder.ConfigureServices(fun services ->
                services.RemoveAll<DbContextOptions<AppDbContext>>() |> ignore
                services.AddDbContext<AppDbContext>(fun options ->
                    options.UseInMemoryDatabase("TestDb") |> ignore) |> ignore))
            .CreateClient()

    [<Fact>]
    member _.``GET order returns 404 when not found`` () = task {
        let! response = client.GetAsync($"/api/orders/{Guid.NewGuid()}")
        test <@ response.StatusCode = HttpStatusCode.NotFound @>
    }
```

## Tổ chức Test

```
tests/
  MyApp.Tests/
    Unit/
      OrderServiceTests.fs
      PaymentServiceTests.fs
    Integration/
      OrderApiTests.fs
      OrderRepositoryTests.fs
    Properties/
      OrderPropertyTests.fs
    Helpers/
      TestData.fs
      TestDeps.fs
```

## Anti-Pattern thường gặp

| Anti-Pattern | Cách khắc phục |
|---|---|
| Test chi tiết triển khai | Test hành vi và kết quả |
| State test mutable dùng chung | State mới cho mỗi test |
| `Thread.Sleep` trong test async | Dùng `Task.Delay` kèm timeout, hoặc helper polling |
| Assert trên output của `sprintf` | Assert trên giá trị có kiểu và pattern match |
| Bỏ qua `CancellationToken` | Luôn truyền và xác minh việc hủy |
| Bỏ qua property-based test | Dùng FsCheck cho mọi hàm có invariant rõ ràng |

## Skill liên quan

- `dotnet-patterns` - Pattern .NET idiomatic, dependency injection và kiến trúc
- `csharp-testing` - Pattern testing C# (hạ tầng dùng chung như WebApplicationFactory và Testcontainers cũng áp dụng cho F#)

## Chạy Test

```bash
# Chạy tất cả test
dotnet test

# Chạy với coverage
dotnet test --collect:"XPlat Code Coverage"

# Chạy một project cụ thể
dotnet test tests/MyApp.Tests/

# Lọc theo tên test
dotnet test --filter "FullyQualifiedName~OrderService"

# Chế độ watch trong lúc phát triển
dotnet watch test --project tests/MyApp.Tests/
```
