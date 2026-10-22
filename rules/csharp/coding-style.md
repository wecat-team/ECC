---
paths:
  - "**/*.cs"
  - "**/*.csx"
---
# Phong cách code C#

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho C#.

## Tiêu chuẩn

- Tuân theo các quy ước .NET hiện hành và bật nullable reference type
- Ưu tiên access modifier tường minh cho các API public và internal
- Giữ file khớp với type chính mà nó định nghĩa

## Type và Model

- Ưu tiên `record` hoặc `record struct` cho các model bất biến kiểu giá trị
- Dùng `class` cho entity hoặc các type có danh tính (identity) và vòng đời
- Dùng `interface` cho ranh giới service và abstraction
- Tránh `dynamic` trong code ứng dụng; ưu tiên generic hoặc model tường minh

```csharp
public sealed record UserDto(Guid Id, string Email);

public interface IUserRepository
{
    Task<UserDto?> FindByIdAsync(Guid id, CancellationToken cancellationToken);
}
```

## Bất biến (Immutability)

- Ưu tiên setter `init`, tham số constructor và collection bất biến cho state dùng chung
- Không mutate trực tiếp model đầu vào khi tạo state đã cập nhật

```csharp
public sealed record UserProfile(string Name, string Email);

public static UserProfile Rename(UserProfile profile, string name) =>
    profile with { Name = name };
```

## Async và xử lý lỗi

- Ưu tiên `async`/`await` hơn các lời gọi chặn như `.Result` hoặc `.Wait()`
- Truyền `CancellationToken` qua các API async public
- Throw exception cụ thể và log kèm các thuộc tính có cấu trúc

```csharp
public async Task<Order> LoadOrderAsync(
    Guid orderId,
    CancellationToken cancellationToken)
{
    try
    {
        return await repository.FindAsync(orderId, cancellationToken)
            ?? throw new InvalidOperationException($"Order {orderId} was not found.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to load order {OrderId}", orderId);
        throw;
    }
}
```

## Định dạng

- Dùng `dotnet format` để format và áp dụng các bản sửa của analyzer
- Giữ các directive `using` có tổ chức và xóa import không dùng
- Chỉ ưu tiên expression-bodied member khi chúng vẫn dễ đọc
