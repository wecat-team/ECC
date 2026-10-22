---
description: Chạy workflow đa model tập trung vào frontend cho component, layout, animation và trau chuốt UI.
---

# Frontend - Phát triển tập trung vào Frontend

Workflow tập trung vào frontend (Research → Ideation → Plan → Execute → Optimize → Review), do Antigravity dẫn dắt.

> **Điều kiện tiên quyết:** Yêu cầu runtime `ccg-workflow` bên ngoài, runtime này **không** nằm trong bản cài ECC cơ bản. Khởi tạo nó bằng `npx ccg-workflow` để cấp phát `~/.claude/bin/codeagent-wrapper` và các file vai trò `~/.claude/.ccg/prompts/*` mà command này phụ thuộc. Nếu không có runtime đó, command này sẽ không chạy đúng.

## Cách dùng

```bash
/frontend <UI task description>
```

## Context

- Tác vụ frontend: $ARGUMENTS
- Antigravity dẫn dắt, Codex để tham khảo bổ trợ
- Áp dụng cho: thiết kế component, layout responsive, animation UI, tối ưu style

## Vai trò của bạn

Bạn là **Frontend Orchestrator**, điều phối sự cộng tác đa model cho các tác vụ UI/UX (Research → Ideation → Plan → Execute → Optimize → Review).

**Các model cộng tác**:
- **Antigravity** – UI/UX frontend (**Thẩm quyền về frontend, đáng tin cậy**)
- **Codex** – Góc nhìn backend (**Ý kiến về frontend chỉ để tham khảo**)
- **Claude (chính bạn)** – Điều phối, lập kế hoạch, thực thi, bàn giao

---

## Đặc tả gọi đa model

**Cú pháp gọi**:

```
# New session call
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend antigravity - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})

# Resume session call
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend antigravity resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})
```

**Role Prompt**:

| Giai đoạn | Antigravity |
|-------|--------|
| Phân tích | `~/.claude/.ccg/prompts/antigravity/analyzer.md` |
| Lập kế hoạch | `~/.claude/.ccg/prompts/antigravity/architect.md` |
| Review | `~/.claude/.ccg/prompts/antigravity/reviewer.md` |

**Tái sử dụng session**: Mỗi lần gọi trả về `SESSION_ID: xxx`, dùng `resume xxx` cho các giai đoạn tiếp theo. Lưu `ANTIGRAVITY_SESSION` ở Giai đoạn 2, dùng `resume` ở Giai đoạn 3 và 5.

---

## Hướng dẫn giao tiếp

1. Bắt đầu phản hồi bằng nhãn chế độ `[Mode: X]`, ban đầu là `[Mode: Research]`
2. Tuân thủ nghiêm ngặt thứ tự: `Research → Ideation → Plan → Execute → Optimize → Review`
3. Dùng tool `AskUserQuestion` để tương tác với người dùng khi cần (ví dụ: xác nhận/lựa chọn/phê duyệt)

---

## Workflow cốt lõi

### Giai đoạn 0: Cải thiện prompt (Tùy chọn)

`[Mode: Prepare]` - Nếu ace-tool MCP khả dụng, gọi `mcp__ace-tool__enhance_prompt`, **thay $ARGUMENTS gốc bằng kết quả đã cải thiện cho các lần gọi Antigravity tiếp theo**. Nếu không khả dụng, dùng nguyên `$ARGUMENTS`.

### Giai đoạn 1: Nghiên cứu (Research)

`[Mode: Research]` - Hiểu yêu cầu và thu thập context

1. **Truy xuất code** (nếu ace-tool MCP khả dụng): Gọi `mcp__ace-tool__search_context` để truy xuất các component, style, design system hiện có. Nếu không khả dụng, dùng các tool có sẵn: `Glob` để tìm file, `Grep` để tìm component/style, `Read` để thu thập context, `Task` (Explore agent) để khám phá sâu hơn.
2. Điểm đầy đủ của yêu cầu (0-10): >=7 tiếp tục, <7 dừng lại và bổ sung

### Giai đoạn 2: Ý tưởng (Ideation)

`[Mode: Ideation]` - Phân tích do Antigravity dẫn dắt

**PHẢI gọi Antigravity** (theo đặc tả gọi ở trên):
- ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/analyzer.md`
- Requirement: Yêu cầu đã được cải thiện (hoặc $ARGUMENTS nếu chưa cải thiện)
- Context: Context dự án từ Giai đoạn 1
- OUTPUT: Phân tích tính khả thi của UI, các giải pháp đề xuất (ít nhất 2), đánh giá UX

**Lưu SESSION_ID** (`ANTIGRAVITY_SESSION`) để tái sử dụng ở các giai đoạn sau.

Xuất các giải pháp (ít nhất 2), chờ người dùng lựa chọn.

### Giai đoạn 3: Lập kế hoạch (Planning)

`[Mode: Plan]` - Lập kế hoạch do Antigravity dẫn dắt

**PHẢI gọi Antigravity** (dùng `resume <ANTIGRAVITY_SESSION>` để tái sử dụng session):
- ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/architect.md`
- Requirement: Giải pháp người dùng đã chọn
- Context: Kết quả phân tích từ Giai đoạn 2
- OUTPUT: Cấu trúc component, luồng UI, hướng tiếp cận styling

Claude tổng hợp kế hoạch, lưu vào `.claude/plan/task-name.md` sau khi người dùng phê duyệt.

### Giai đoạn 4: Triển khai (Implementation)

`[Mode: Execute]` - Phát triển code

- Tuân thủ nghiêm ngặt kế hoạch đã được duyệt
- Tuân theo design system và chuẩn code hiện có của dự án
- Đảm bảo tính responsive, accessibility

### Giai đoạn 5: Tối ưu (Optimization)

`[Mode: Optimize]` - Review do Antigravity dẫn dắt

**MUST call Antigravity** (follow call specification above):
- ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/reviewer.md`
- Requirement: Review các thay đổi code frontend sau
- Context: git diff hoặc nội dung code
- OUTPUT: Danh sách vấn đề về accessibility, responsive, hiệu năng, tính nhất quán của thiết kế

Tích hợp phản hồi review, thực hiện tối ưu sau khi người dùng xác nhận.

### Giai đoạn 6: Review chất lượng

`[Mode: Review]` - Đánh giá cuối cùng

- Đối chiếu mức độ hoàn thành với kế hoạch
- Xác minh tính responsive và accessibility
- Báo cáo các vấn đề và khuyến nghị

---

## Quy tắc chính

1. **Ý kiến frontend của Antigravity đáng tin cậy**
2. **Ý kiến frontend của Codex chỉ để tham khảo**
3. Các model bên ngoài **không có quyền ghi filesystem**
4. Claude xử lý mọi thao tác ghi code và file
