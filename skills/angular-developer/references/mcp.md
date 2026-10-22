# Angular CLI MCP Server

Angular CLI bao gồm một server Model Context Protocol (MCP) cho phép các trợ lý AI (như Cursor, Gemini CLI, JetBrains AI, v.v.) tương tác trực tiếp với Angular CLI. Nó cung cấp các tool để sinh code, hiện đại hóa code, lấy ví dụ, và chạy build/test.

## Các Tool khả dụng (Mặc định)

Khi MCP server được bật, các AI agent có quyền truy cập các tool sau:

| Tên                         | Mô tả                                                                                                                  |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------- |
| `ai_tutor`                  | Khởi chạy một gia sư Angular tương tác chạy bằng AI.                                                                   |
| `find_examples`             | Tìm các ví dụ code chuẩn mực, theo best practice cho các tính năng Angular hiện đại.                                   |
| `get_best_practices`        | Lấy Angular Best Practices Guide (rất quan trọng cho standalone component, typed form, v.v.).                          |
| `list_projects`             | Liệt kê mọi ứng dụng và thư viện trong workspace bằng cách đọc `angular.json`.                                         |
| `onpush_zoneless_migration` | Phân tích code và đưa ra kế hoạch migrate sang change detection `OnPush` (điều kiện tiên quyết cho zoneless).          |
| `search_documentation`      | Tìm kiếm tài liệu chính thức tại `https://angular.dev`.                                                                |

## Các Tool thử nghiệm (Experimental)

Một số tool phải được bật tường minh bằng cờ `--experimental-tool` (hoặc `-E`).

| Tên                        | Mô tả                                                                         |
| :------------------------- | :---------------------------------------------------------------------------- |
| `build`                    | Thực hiện một lần build bằng `ng build`.                                      |
| `devserver.start`          | Khởi động dev server (`ng serve`) bất đồng bộ. Trả về ngay lập tức.           |
| `devserver.stop`           | Dừng dev server.                                                              |
| `devserver.wait_for_build` | Trả về log của lần build gần nhất trong một dev server đang chạy.             |
| `e2e`                      | Thực thi các end-to-end test.                                                 |
| `modernize`                | Thực hiện các code migration để phù hợp với best practice và cú pháp mới nhất. |
| `test`                     | Chạy các unit test của dự án.                                                 |

## Cấu hình

Để dùng MCP server, bạn cấu hình môi trường host (IDE hoặc CLI) để chạy `npx @angular/cli mcp`.

### Antigravity IDE

Tạo file tên `.antigravity/mcp.json` ở thư mục gốc của dự án:

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### Gemini CLI

Tạo `.gemini/settings.json` ở thư mục gốc của dự án:

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### Cursor

Tạo `.cursor/mcp.json` ở thư mục gốc của dự án (hoặc toàn cục tại `~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### VS Code

Tạo `.vscode/mcp.json`:

```json
{
  "servers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

## Tùy chọn lệnh

Bạn có thể truyền tham số cho MCP server trong mảng `args` của cấu hình:

- `--read-only`: Chỉ đăng ký các tool không sửa đổi dự án.
- `--local-only`: Chỉ đăng ký các tool không cần kết nối internet.
- `--experimental-tool` (`-E`): Bật các tool thử nghiệm cụ thể (ví dụ: `-E build`, `-E devserver`).

Ví dụ cho chế độ read-only với các tool thử nghiệm được bật:

```json
"args": ["-y", "@angular/cli", "mcp", "--read-only", "-E", "build", "-E", "modernize"]
```
