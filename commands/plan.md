---
description: Diễn đạt lại yêu cầu, đánh giá rủi ro và tạo kế hoạch triển khai từng bước. CHỜ người dùng XÁC NHẬN trước khi đụng vào bất kỳ code nào. Dùng cho kế hoạch triển khai đơn model chạy inline hoặc dựa trên PRD; với kế hoạch hai model (Codex/Antigravity) hãy dùng /multi-plan, và để review trực quan kiểu annotate-and-approve kế hoạch kết quả hãy dùng /plan-canvas.
argument-hint: "[mô tả tính năng | path/to/*.prd.md]"
---

# Lệnh Plan

Command này tạo một kế hoạch triển khai toàn diện trước khi viết bất kỳ code nào. Nó nhận yêu cầu dạng tự do hoặc một file markdown PRD.

Mặc định chạy inline. Không gọi tool Task hay bất kỳ subagent nào theo mặc định. Điều này giữ cho `/plan` dùng được từ các bản cài plugin chỉ có command mà không có file agent.

## Command này làm gì

1. **Diễn đạt lại yêu cầu** - Làm rõ cần xây dựng gì
2. **Xác định rủi ro** - Nêu ra các vấn đề và điểm nghẽn tiềm ẩn
3. **Tạo kế hoạch từng bước** - Chia việc triển khai thành các giai đoạn
4. **Chờ xác nhận** - PHẢI nhận được sự chấp thuận của người dùng trước khi tiếp tục

## Khi nào dùng

Dùng `/plan` khi:
- Bắt đầu một tính năng mới
- Thực hiện các thay đổi kiến trúc đáng kể
- Làm việc với refactor phức tạp
- Nhiều file/component sẽ bị ảnh hưởng
- Yêu cầu chưa rõ ràng hoặc mơ hồ

## Cách hoạt động

Trợ lý sẽ:

1. **Phân tích yêu cầu** và diễn đạt lại các yêu cầu một cách rõ ràng
2. **Neo kế hoạch** vào các pattern liên quan của codebase khi có repo
3. **Chia thành các giai đoạn** với các bước cụ thể, có thể hành động
4. **Xác định dependency** giữa các component
5. **Đánh giá rủi ro** và các điểm nghẽn tiềm ẩn
6. **Ước lượng độ phức tạp** (High/Medium/Low)
7. **Trình bày kế hoạch** và CHỜ sự xác nhận tường minh của bạn

## Chế độ input

| Input | Chế độ | Hành vi |
|---|---|---|
| `path/to/name.prd.md` | Chế độ PRD artifact | Đọc PRD, chọn delivery milestone hoặc giai đoạn triển khai pending kế tiếp, và ghi `.claude/plans/{name}.plan.md` |
| Bất kỳ đường dẫn markdown nào khác | Chế độ tham chiếu | Đọc file làm context và tạo kế hoạch inline |
| Văn bản tự do | Chế độ hội thoại | Tạo kế hoạch inline |
| Input rỗng | Chế độ làm rõ | Hỏi cần lập kế hoạch cho việc gì |

Trong chế độ PRD artifact, tạo `.claude/plans/` nếu cần. Nếu PRD có bảng `Delivery Milestones`, chỉ cập nhật dòng được chọn từ `pending` sang `in-progress` và đặt ô `Plan` của nó thành đường dẫn kế hoạch đã sinh. Nếu PRD dùng định dạng legacy `.claude/PRPs/prds/` với `Implementation Phases`, hãy đọc nó mà không di chuyển đường dẫn.

## Neo vào pattern (Pattern Grounding)

Trước khi viết kế hoạch, hãy tìm trong codebase các quy ước mà phần triển khai nên phản chiếu. Ghi lại ví dụ tiêu biểu nhất cho từng nhóm liên quan kèm tham chiếu file:

| Nhóm | Cần ghi lại gì |
|---|---|
| Đặt tên | Cách đặt tên file, hàm, type, command hoặc script trong khu vực bị ảnh hưởng |
| Xử lý lỗi | Cách lỗi được ném, trả về, ghi log hoặc xử lý êm thấm |
| Logging | Các mức, định dạng và những gì được ghi log |
| Truy cập dữ liệu | Pattern repository, service, query hoặc filesystem |
| Test | Vị trí file test, framework, fixture và phong cách assertion |

Nếu không có code tương tự, hãy nêu rõ điều đó. Không bịa ra một pattern.

## Output PRD Artifact

Khi được gọi với một file `.prd.md`, hãy ghi kế hoạch vào `.claude/plans/{kebab-case-name}.plan.md` theo cấu trúc này:

````markdown
# Plan: {Feature Name}

**Source PRD**: {path}
**Selected Milestone**: {milestone or phase name}
**Complexity**: {Small | Medium | Large}

## Summary
{2-3 sentences}

## Patterns to Mirror
| Category | Source | Pattern |
|---|---|---|
| Naming | `path:line` | {short description} |
| Errors | `path:line` | {short description} |
| Tests | `path:line` | {short description} |

## Files to Change
| File | Action | Why |
|---|---|---|
| `path` | CREATE / UPDATE / DELETE | {reason} |

## Tasks
### Task 1: {name}
- **Action**: {what to do}
- **Mirror**: {pattern to follow}
- **Validate**: {command that proves correctness}

## Validation
```bash
{project-specific validation commands}
```

## Risks
| Risk | Likelihood | Mitigation |
|---|---|---|

## Acceptance
- [ ] All tasks complete
- [ ] Validation passes
- [ ] Patterns mirrored, not reinvented
````

Sau khi ghi artifact, hãy báo cáo đường dẫn của nó và CHỜ xác nhận trước khi viết code.

> **Review trực quan:** thay vì yêu cầu xác nhận bằng cách gõ, bạn có thể mở
> artifact trong Plan Canvas trên trình duyệt (`/plan-canvas`, hoặc skill `plan-canvas`):
> người dùng chú thích kế hoạch ngay tại chỗ và nhấn **Approve plan** hoặc **Request
> changes**, và đó sẽ là tín hiệu xác nhận của bạn.

## Ví dụ sử dụng

```
User: /plan I need to add real-time notifications when markets resolve

Assistant:
# Implementation Plan: Real-Time Market Resolution Notifications

## Requirements Restatement
- Send notifications to users when markets they're watching resolve
- Support multiple notification channels (in-app, email, webhook)
- Ensure notifications are delivered reliably
- Include market outcome and user's position result

## Implementation Phases

### Phase 1: Database Schema
- Add notifications table with columns: id, user_id, market_id, type, status, created_at
- Add user_notification_preferences table for channel preferences
- Create indexes on user_id and market_id for performance

### Phase 2: Notification Service
- Create notification service in lib/notifications.ts
- Implement notification queue using BullMQ/Redis
- Add retry logic for failed deliveries
- Create notification templates

### Phase 3: Integration Points
- Hook into market resolution logic (when status changes to "resolved")
- Query all users with positions in market
- Enqueue notifications for each user

### Phase 4: Frontend Components
- Create NotificationBell component in header
- Add NotificationList modal
- Implement real-time updates via Supabase subscriptions
- Add notification preferences page

## Dependencies
- Redis (for queue)
- Email service (SendGrid/Resend)
- Supabase real-time subscriptions

## Risks
- HIGH: Email deliverability (SPF/DKIM required)
- MEDIUM: Performance with 1000+ users per market
- MEDIUM: Notification spam if markets resolve frequently
- LOW: Real-time subscription overhead

## Estimated Complexity: MEDIUM
- Backend: 4-6 hours
- Frontend: 3-4 hours
- Testing: 2-3 hours
- Total: 9-13 hours

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)
```

## Lưu ý quan trọng

**QUAN TRỌNG**: Command này sẽ **KHÔNG** viết bất kỳ code nào cho đến khi bạn xác nhận tường minh kế hoạch bằng "yes" hoặc "proceed" hoặc một phản hồi đồng ý tương tự.

Nếu bạn muốn thay đổi, hãy phản hồi bằng:
- "modify: [your changes]"
- "different approach: [alternative]"
- "skip phase 2 and do phase 3 first"

## Tích hợp với các command khác

Sau khi lập kế hoạch:
- Dùng `/plan-canvas` để chạy cổng xác nhận một cách trực quan trên trình duyệt (annotate + approve)
- Dùng skill `tdd-workflow` để triển khai theo hướng kiểm thử (TDD)
- Dùng `/build-fix` nếu có lỗi build
- Dùng `/code-review` để review phần triển khai đã hoàn tất
- Dùng `/pr` hoặc `/prp-pr` để mở pull request

> **Cần yêu cầu trước?** Dùng `/plan-prd` để có một PRD gọn tại `.claude/prds/{name}.prd.md`.
>
> **Cần luồng PRP legacy?** Dùng `/prp-plan` để lập kế hoạch PRP chuyên sâu với các artifact `.claude/PRPs/`. Dùng `/prp-implement` để thực thi các kế hoạch đó với các vòng lặp validation nghiêm ngặt.

## Agent Planner tùy chọn

ECC cũng cung cấp một agent `planner` cho các bản cài thủ công có kèm file agent. Chỉ dùng nó khi runtime cục bộ đã cung cấp subagent đó và người dùng tường minh yêu cầu bạn ủy quyền việc lập kế hoạch.

Nếu subagent `planner` không khả dụng, hãy tiếp tục lập kế hoạch inline thay vì đưa ra lỗi "Agent type 'planner' not found".

Với bản cài thủ công, file nguồn nằm tại:
`agents/planner.md`
