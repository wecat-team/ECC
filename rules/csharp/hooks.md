---
paths:
  - "**/*.cs"
  - "**/*.csx"
  - "**/*.csproj"
  - "**/*.sln"
  - "**/Directory.Build.props"
  - "**/Directory.Build.targets"
---
# Hook cho C#

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho C#.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **dotnet format**: Tự động format các file C# đã sửa và áp dụng các bản sửa của analyzer
- **dotnet build**: Xác minh solution hoặc project vẫn biên dịch được sau khi sửa
- **dotnet test --no-build**: Chạy lại project test liên quan gần nhất sau khi hành vi thay đổi

## Hook Stop

- Chạy `dotnet build` lần cuối trước khi kết thúc phiên có thay đổi C# trên diện rộng
- Cảnh báo khi các file `appsettings*.json` bị sửa để secret không bị commit nhầm
