---
paths:
  - "**/*.cs"
  - "**/*.csx"
  - "**/*.csproj"
---
# Kiểm thử C#

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho C#.

## Test Framework

- Ưu tiên **xUnit** cho unit test và integration test
- Dùng **AwesomeAssertions** để có assertion dễ đọc
- Dùng **Moq** hoặc **NSubstitute** để mock dependency
- Dùng **Testcontainers** khi integration test cần hạ tầng thật

## Tổ chức Test

- Phản chiếu cấu trúc `src/` dưới `tests/`
- Tách biệt rõ phần unit, integration và end-to-end
- Đặt tên test theo hành vi, không theo chi tiết triển khai

```csharp
public sealed class OrderServiceTests
{
    [Fact]
    public async Task FindByIdAsync_ReturnsOrder_WhenOrderExists()
    {
        // Arrange
        // Act
        // Assert
    }
}
```

## Integration Test ASP.NET Core

- Dùng `WebApplicationFactory<TEntryPoint>` để kiểm thử integration cho API
- Test auth, validation và serialization qua HTTP, không bằng cách bỏ qua middleware

## Coverage

- Mục tiêu line coverage 80%+
- Tập trung coverage vào domain logic, validation, auth và các đường lỗi
- Chạy `dotnet test` trong CI với việc thu thập coverage được bật khi có thể
