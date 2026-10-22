---
paths:
  - "**/*.cs"
  - "**/*.csx"
---
# Pattern C#

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho C#.

## Pattern API Response

```csharp
public sealed record ApiResponse<T>(
    bool Success,
    T? Data = default,
    string? Error = null,
    object? Meta = null);
```

## Repository Pattern

```csharp
public interface IRepository<T>
{
    Task<IReadOnlyList<T>> FindAllAsync(CancellationToken cancellationToken);
    Task<T?> FindByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<T> CreateAsync(T entity, CancellationToken cancellationToken);
    Task<T> UpdateAsync(T entity, CancellationToken cancellationToken);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken);
}
```

## Options Pattern

Dùng options có định kiểu mạnh cho cấu hình thay vì đọc chuỗi thô rải rác khắp codebase.

```csharp
public sealed class PaymentsOptions
{
    public const string SectionName = "Payments";
    public required string BaseUrl { get; init; }
    public required string ApiKeySecretName { get; init; }
}
```

## Dependency Injection

- Phụ thuộc vào interface tại ranh giới service
- Giữ constructor tập trung; nếu một service cần quá nhiều dependency, hãy tách trách nhiệm
- Đăng ký lifetime có chủ đích: singleton cho service stateless/dùng chung, scoped cho dữ liệu theo request, transient cho các worker thuần nhẹ
