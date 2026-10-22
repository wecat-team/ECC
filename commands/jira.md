---
description: Lấy một ticket Jira, phân tích yêu cầu, cập nhật trạng thái hoặc thêm comment. Dùng skill jira-integration và MCP hoặc REST API.
---

# Lệnh Jira

Tương tác với ticket Jira trực tiếp từ workflow của bạn — lấy ticket, phân tích yêu cầu, thêm comment và chuyển trạng thái.

## Cách dùng

```
/jira get <TICKET-KEY>          # Fetch and analyze a ticket
/jira comment <TICKET-KEY>      # Add a progress comment
/jira transition <TICKET-KEY>   # Change ticket status
/jira search <JQL>              # Search issues with JQL
```

## Command này làm gì

1. **Get & Analyze** — Lấy một ticket Jira và trích xuất yêu cầu, tiêu chí chấp nhận (acceptance criteria), kịch bản test và dependency
2. **Comment** — Thêm các cập nhật tiến độ có cấu trúc vào ticket
3. **Transition** — Chuyển ticket qua các trạng thái workflow (To Do → In Progress → Done)
4. **Search** — Tìm issue bằng truy vấn JQL

## Cách hoạt động

### `/jira get <TICKET-KEY>`

1. Lấy ticket từ Jira (qua MCP `jira_get_issue` hoặc REST API)
2. Trích xuất mọi trường: summary, description, acceptance criteria, priority, label, linked issue
3. Có thể lấy thêm comment để có thêm context
4. Tạo bản phân tích có cấu trúc:

```
Ticket: PROJ-1234
Summary: [title]
Status: [status]
Priority: [priority]
Type: [Story/Bug/Task]

Requirements:
1. [extracted requirement]
2. [extracted requirement]

Acceptance Criteria:
- [ ] [criterion from ticket]

Test Scenarios:
- Happy Path: [description]
- Error Case: [description]
- Edge Case: [description]

Dependencies:
- [linked issues, APIs, services]

Recommended Next Steps:
- /plan to create implementation plan
- `tdd-workflow` skill to implement with tests first
```

### `/jira comment <TICKET-KEY>`

1. Tóm tắt tiến độ của phiên hiện tại (đã xây dựng, test, commit những gì)
2. Định dạng thành comment có cấu trúc
3. Đăng lên ticket Jira

### `/jira transition <TICKET-KEY>`

1. Lấy các transition khả dụng cho ticket
2. Hiển thị các lựa chọn cho người dùng
3. Thực hiện transition đã chọn

### `/jira search <JQL>`

1. Thực thi truy vấn JQL trên Jira
2. Trả về bảng tóm tắt các issue khớp

## Điều kiện tiên quyết

Command này yêu cầu credential Jira. Chọn một:

**Lựa chọn A — MCP Server (khuyến nghị):**
Thêm `jira` vào cấu hình `mcpServers` của bạn (xem `mcp-configs/mcp-servers.json` để lấy template).

**Lựa chọn B — Biến môi trường:**
```bash
export JIRA_URL="https://yourorg.atlassian.net"
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_TOKEN="your-api-token"
```

Nếu thiếu credential, hãy dừng lại và hướng dẫn người dùng thiết lập chúng.

## Tích hợp với các command khác

Sau khi phân tích một ticket:
- Dùng `/plan` để tạo kế hoạch triển khai từ các yêu cầu
- Dùng skill `tdd-workflow` để triển khai theo hướng kiểm thử (TDD)
- Dùng `/code-review` sau khi triển khai
- Dùng `/jira comment` để đăng tiến độ trở lại ticket
- Dùng `/jira transition` để chuyển ticket khi công việc hoàn tất

## Liên quan

- **Skill:** `skills/jira-integration/`
- **MCP config:** `mcp-configs/mcp-servers.json` → `jira`
