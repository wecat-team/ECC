---
name: mcp-server-patterns
description: Xây dựng MCP server bằng Node/TypeScript SDK — tool, resource, prompt, validation bằng Zod, stdio so với Streamable HTTP. Dùng Context7 hoặc tài liệu MCP chính thức để biết API mới nhất. Dùng khi xây dựng hoặc debug một MCP server — tool, resource, prompt, validation hoặc lựa chọn transport.
metadata:
  origin: ECC
---

# MCP Server Patterns

Model Context Protocol (MCP) cho phép trợ lý AI gọi tool, đọc resource và dùng prompt từ server của bạn. Dùng skill này khi xây dựng hoặc bảo trì MCP server. API của SDK thay đổi theo thời gian; hãy kiểm tra Context7 (query-docs cho "MCP") hoặc tài liệu MCP chính thức để biết tên method và signature hiện hành.

Để biết quyết định định tuyến rộng hơn về việc khi nào một khả năng nên là rule, skill, MCP, hay một workflow CLI/API thuần, xem [docs/capability-surface-selection.md](../../docs/capability-surface-selection.md).

## Khi nào dùng

Dùng khi: triển khai một MCP server mới, thêm tool hoặc resource, chọn stdio hay HTTP, nâng cấp SDK, hoặc debug các vấn đề về đăng ký MCP và transport.

## Cách hoạt động

### Các khái niệm cốt lõi

- **Tools**: Các hành động mà model có thể gọi (ví dụ tìm kiếm, chạy một lệnh). Đăng ký bằng `registerTool()` hoặc `tool()` tùy phiên bản SDK.
- **Resources**: Dữ liệu chỉ đọc mà model có thể lấy (ví dụ nội dung file, phản hồi API). Đăng ký bằng `registerResource()` hoặc `resource()`. Handler thường nhận một đối số `uri`.
- **Prompts**: Các prompt template tái sử dụng, có tham số, mà client có thể hiển thị (ví dụ trong Claude Desktop). Đăng ký bằng `registerPrompt()` hoặc tương đương.
- **Transport**: stdio cho client cục bộ (ví dụ Claude Desktop); Streamable HTTP được ưu tiên cho remote (Cursor, cloud). HTTP/SSE legacy dành cho tương thích ngược.

Node/TypeScript SDK có thể cung cấp `tool()` / `resource()` hoặc `registerTool()` / `registerResource()`; SDK chính thức đã thay đổi theo thời gian. Luôn đối chiếu với [tài liệu MCP](https://modelcontextprotocol.io) hiện hành hoặc Context7.

### Kết nối bằng stdio

Với client cục bộ, tạo một stdio transport và truyền nó vào method connect của server. API chính xác khác nhau tùy phiên bản SDK (ví dụ constructor so với factory). Xem tài liệu MCP chính thức hoặc truy vấn Context7 với "MCP stdio server" để biết pattern hiện hành.

Giữ logic server (tool + resource) độc lập với transport để bạn có thể cắm stdio hoặc HTTP ở entrypoint.

### Remote (Streamable HTTP)

Với Cursor, cloud hoặc các client remote khác, dùng **Streamable HTTP** (một MCP HTTP endpoint duy nhất theo spec hiện hành). Chỉ hỗ trợ HTTP/SSE legacy khi cần tương thích ngược.

## Ví dụ

### Cài đặt và thiết lập server

```bash
npm install @modelcontextprotocol/sdk zod
```

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({ name: "my-server", version: "1.0.0" });
```

Đăng ký tool và resource bằng API mà phiên bản SDK của bạn cung cấp: một số phiên bản dùng `server.tool(name, description, schema, handler)` (đối số theo vị trí), số khác dùng `server.tool({ name, description, inputSchema }, handler)` hoặc `registerTool()`. Resource cũng tương tự — thêm `uri` vào handler khi API cung cấp. Kiểm tra tài liệu MCP chính thức hoặc Context7 để biết signature hiện hành của `@modelcontextprotocol/sdk` nhằm tránh lỗi copy-paste.

Dùng **Zod** (hoặc định dạng schema ưu tiên của SDK) để kiểm tra đầu vào (input validation).

## Best Practice

- **Schema trước**: Định nghĩa input schema cho mọi tool; ghi tài liệu các tham số và hình dạng giá trị trả về.
- **Lỗi**: Trả về lỗi có cấu trúc hoặc thông báo mà model có thể diễn giải; tránh stack trace thô.
- **Idempotency**: Ưu tiên tool idempotent khi có thể để retry an toàn.
- **Rate và chi phí**: Với tool gọi API bên ngoài, cân nhắc rate limit và chi phí; ghi rõ trong mô tả tool.
- **Versioning**: Pin phiên bản SDK trong package.json; xem release note khi nâng cấp.

## SDK và tài liệu chính thức

- **JavaScript/TypeScript**: `@modelcontextprotocol/sdk` (npm). Dùng Context7 với tên thư viện "MCP" để biết pattern đăng ký và transport hiện hành.
- **Go**: SDK Go chính thức trên GitHub (`modelcontextprotocol/go-sdk`).
- **C#**: SDK C# chính thức cho .NET.
