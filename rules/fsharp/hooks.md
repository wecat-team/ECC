---
paths:
  - "**/*.fs"
  - "**/*.fsx"
  - "**/*.fsproj"
  - "**/*.sln"
  - "**/*.slnx"
  - "**/Directory.Build.props"
  - "**/Directory.Build.targets"
---
# Hook cho F#

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho F#.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **fantomas**: Tự động format các file F# đã sửa
- **dotnet build**: Xác minh solution hoặc project vẫn biên dịch được sau khi sửa
- **dotnet test --no-build**: Chạy lại project test liên quan gần nhất sau khi hành vi thay đổi

## Hook Stop

- Chạy `dotnet build` lần cuối trước khi kết thúc phiên có thay đổi F# trên diện rộng
- Cảnh báo khi các file `appsettings*.json` bị sửa để secret không bị commit nhầm
