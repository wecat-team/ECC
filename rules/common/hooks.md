# Hệ thống Hook

## Các loại Hook

- **PreToolUse**: Trước khi thực thi tool (validation, sửa tham số)
- **PostToolUse**: Sau khi thực thi tool (auto-format, kiểm tra)
- **Stop**: Khi phiên kết thúc (xác minh cuối cùng)

## Auto-Accept Permissions

Dùng thận trọng:
- Bật cho các kế hoạch đáng tin cậy, được định nghĩa rõ
- Tắt khi làm việc mang tính khám phá
- KHÔNG BAO GIỜ dùng flag dangerously-skip-permissions
- Thay vào đó, hãy cấu hình các rule `permissions.allow` trong `~/.claude/settings.json` (hoặc `.claude/settings.json` của dự án)

## Best Practice với TodoWrite

Dùng tool TodoWrite để:
- Theo dõi tiến độ của các task nhiều bước
- Xác minh việc hiểu đúng hướng dẫn
- Cho phép điều hướng theo thời gian thực
- Hiển thị các bước triển khai chi tiết

Danh sách todo cho thấy:
- Các bước sai thứ tự
- Các mục bị thiếu
- Các mục thừa không cần thiết
- Độ chi tiết sai
- Yêu cầu bị hiểu sai
