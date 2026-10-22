---
description: Tạo kế hoạch triển khai tính năng toàn diện với phân tích codebase và trích xuất pattern
argument-hint: <mô tả tính năng | path/to/prd.md>
---

> Phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

# PRP Plan

Tạo một kế hoạch triển khai chi tiết, tự chứa đủ, ghi lại mọi pattern, quy ước và context của codebase cần thiết để triển khai một tính năng chỉ trong một lượt.

**Triết lý cốt lõi**: Một plan tốt chứa mọi thứ cần thiết để triển khai mà không phải hỏi thêm. Mọi pattern, mọi quy ước, mọi gotcha — được ghi lại một lần, tham chiếu xuyên suốt.

**Quy tắc vàng**: Nếu bạn sẽ phải tìm kiếm trong codebase trong lúc triển khai, hãy ghi lại kiến thức đó NGAY BÂY GIỜ vào plan.

---

## Giai đoạn 0 — DETECT

Xác định loại đầu vào từ `$ARGUMENTS`:

| Mẫu đầu vào | Cách nhận diện | Hành động |
|---|---|---|
| Đường dẫn kết thúc bằng `.prd.md` | Đường dẫn file PRD | Parse PRD, tìm phase pending tiếp theo |
| Đường dẫn tới `.md` có "Implementation Phases" | Tài liệu giống PRD | Parse các phase, tìm phase pending tiếp theo |
| Đường dẫn tới file khác bất kỳ | File tham chiếu | Đọc file để lấy context, coi như free-form |
| Văn bản free-form | Mô tả tính năng | Chuyển thẳng sang Giai đoạn 1 |
| Rỗng / trống | Không có đầu vào | Hỏi người dùng muốn lập plan cho tính năng nào |

### Parse PRD (khi đầu vào là PRD)

1. Đọc file PRD bằng `cat "$PRD_PATH"`
2. Parse section **Implementation Phases**
3. Tìm các phase theo trạng thái:
   - Tìm các phase `pending`
   - Kiểm tra chuỗi dependency (một phase có thể phụ thuộc vào các phase trước đó phải `complete`)
   - Chọn **phase pending đủ điều kiện tiếp theo**
4. Trích xuất từ phase đã chọn:
   - Tên và mô tả phase
   - Tiêu chí chấp nhận (acceptance criteria)
   - Dependency vào các phase trước
   - Mọi ghi chú về phạm vi hoặc ràng buộc
5. Dùng mô tả của phase làm tính năng cần lập plan

Nếu không còn phase pending nào, hãy báo cáo rằng tất cả các phase đã hoàn thành.

---

## Giai đoạn 1 — PARSE

Trích xuất và làm rõ các yêu cầu của tính năng.

### Hiểu tính năng

Từ đầu vào (phase của PRD hoặc mô tả free-form), xác định:

- **Cái gì** đang được xây dựng (sản phẩm bàn giao cụ thể)
- **Tại sao** nó quan trọng (giá trị cho người dùng)
- **Ai** dùng nó (người dùng/hệ thống mục tiêu)
- **Ở đâu** nó phù hợp (phần nào của codebase)

### User Story

Định dạng:
```
As a [type of user],
I want [capability],
So that [benefit].
```

### Đánh giá độ phức tạp

| Mức | Dấu hiệu | Phạm vi điển hình |
|---|---|---|
| **Small** | Một file, thay đổi cô lập, không có dependency mới | 1-3 file, <100 dòng |
| **Medium** | Nhiều file, theo pattern hiện có, khái niệm mới nhỏ | 3-10 file, 100-500 dòng |
| **Large** | Mối quan tâm xuyên suốt (cross-cutting), pattern mới, tích hợp bên ngoài | 10+ file, 500+ dòng |
| **XL** | Thay đổi kiến trúc, subsystem mới, cần migration | 20+ file, cân nhắc tách nhỏ |

### Cổng chống mơ hồ (Ambiguity Gate)

Nếu bất kỳ điều nào sau đây chưa rõ, **DỪNG và hỏi người dùng** trước khi tiếp tục:

- Sản phẩm bàn giao cốt lõi còn mơ hồ
- Tiêu chí thành công chưa được định nghĩa
- Có nhiều cách diễn giải hợp lệ
- Hướng tiếp cận kỹ thuật còn nhiều ẩn số lớn

KHÔNG đoán. Hãy hỏi. Một plan xây trên các giả định sẽ thất bại trong lúc triển khai.

---

## Giai đoạn 2 — EXPLORE

Thu thập thông tin sâu về codebase. Tìm kiếm trực tiếp trong codebase cho từng nhóm bên dưới.

### Tìm kiếm trong Codebase (8 nhóm)

Với mỗi nhóm, tìm bằng grep, find và đọc file:

1. **Similar Implementations** — Tìm các tính năng hiện có giống với tính năng đang lập plan. Tìm các pattern, endpoint, component hoặc module tương tự.

2. **Naming Conventions** — Xác định cách đặt tên file, function, biến, class và export trong khu vực liên quan của codebase.

3. **Error Handling** — Tìm cách lỗi được bắt, lan truyền, ghi log và trả về cho người dùng trong các luồng code tương tự.

4. **Logging Patterns** — Xác định cái gì được log, ở mức nào và theo định dạng nào.

5. **Type Definitions** — Tìm các type, interface, schema liên quan và cách chúng được tổ chức.

6. **Test Patterns** — Tìm cách các tính năng tương tự được test. Ghi lại vị trí file test, cách đặt tên, pattern setup/teardown và kiểu assertion.

7. **Configuration** — Tìm các file config, biến môi trường và feature flag liên quan.

8. **Dependencies** — Xác định các package, import và module nội bộ được các tính năng tương tự sử dụng.

### Phân tích Codebase (5 luồng truy vết)

Đọc các file liên quan để truy vết:

1. **Entry Points** — Một request/hành động đi vào hệ thống và đến khu vực bạn đang sửa bằng cách nào?
2. **Data Flow** — Dữ liệu di chuyển qua các luồng code liên quan như thế nào?
3. **State Changes** — State nào được thay đổi và ở đâu?
4. **Contracts** — Những interface, API hoặc giao thức nào phải được tuân thủ?
5. **Patterns** — Những pattern kiến trúc nào được dùng (repository, service, controller, v.v.)?

### Bảng khám phá hợp nhất (Unified Discovery Table)

Tổng hợp các phát hiện vào một bảng tham chiếu duy nhất:

| Nhóm | File:Dòng | Pattern | Đoạn code chính |
|---|---|---|---|
| Naming | `src/services/userService.ts:1-5` | camelCase cho service, PascalCase cho type | `export class UserService` |
| Error | `src/middleware/errorHandler.ts:10-25` | Class AppError tùy chỉnh | `throw new AppError(...)` |
| ... | ... | ... | ... |

---

## Giai đoạn 3 — RESEARCH

Nếu tính năng liên quan đến thư viện bên ngoài, API hoặc công nghệ chưa quen thuộc:

1. Tìm tài liệu chính thức trên web
2. Tìm các ví dụ sử dụng và best practice
3. Xác định các gotcha riêng theo phiên bản

Định dạng mỗi phát hiện như sau:

```
KEY_INSIGHT: [what you learned]
APPLIES_TO: [which part of the plan this affects]
GOTCHA: [any warnings or version-specific issues]
```

Nếu tính năng chỉ dùng các pattern nội bộ đã được hiểu rõ, bỏ qua giai đoạn này và ghi chú: "No external research needed — feature uses established internal patterns."

---

## Giai đoạn 4 — DESIGN

### Chuyển đổi UX (nếu áp dụng)

Ghi lại trải nghiệm người dùng trước/sau:

**Before:**
```
┌─────────────────────────────┐
│  [Current user experience]  │
│  Show the current flow,     │
│  what the user sees/does    │
└─────────────────────────────┘
```

**After:**
```
┌─────────────────────────────┐
│  [New user experience]      │
│  Show the improved flow,    │
│  what changes for the user  │
└─────────────────────────────┘
```

### Thay đổi tương tác

| Điểm chạm | Trước | Sau | Ghi chú |
|---|---|---|---|
| ... | ... | ... | ... |

Nếu tính năng thuần backend/nội bộ và không có thay đổi UX, ghi chú: "Internal change — no user-facing UX transformation."

---

## Giai đoạn 5 — ARCHITECT

### Thiết kế chiến lược

Định nghĩa hướng tiếp cận triển khai:

- **Approach**: Chiến lược ở mức cao (ví dụ: "Add new service layer following existing repository pattern")
- **Alternatives Considered**: Những hướng tiếp cận khác đã được đánh giá và lý do bị loại
- **Scope**: Ranh giới cụ thể của những gì SẼ được xây dựng
- **NOT Building**: Danh sách tường minh những gì NẰM NGOÀI PHẠM VI (ngăn scope creep trong lúc triển khai)

---

## Giai đoạn 6 — GENERATE

Viết toàn bộ tài liệu plan theo template bên dưới. Lưu vào `.claude/PRPs/plans/{kebab-case-feature-name}.plan.md`.

Tạo thư mục nếu chưa tồn tại:
```bash
mkdir -p .claude/PRPs/plans
```

### Plan Template

````markdown
# Plan: [Feature Name]

## Summary
[2-3 sentence overview]

## User Story
As a [user], I want [capability], so that [benefit].

## Problem → Solution
[Current state] → [Desired state]

## Metadata
- **Complexity**: [Small | Medium | Large | XL]
- **Source PRD**: [path or "N/A"]
- **PRD Phase**: [phase name or "N/A"]
- **Estimated Files**: [count]

---

## UX Design

### Before
[ASCII diagram or "N/A — internal change"]

### After
[ASCII diagram or "N/A — internal change"]

### Interaction Changes
| Touchpoint | Before | After | Notes |
|---|---|---|---|

---

## Mandatory Reading

Files that MUST be read before implementing:

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 (critical) | `path/to/file` | 1-50 | Core pattern to follow |
| P1 (important) | `path/to/file` | 10-30 | Related types |
| P2 (reference) | `path/to/file` | all | Similar implementation |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| ... | ... | ... |

---

## Patterns to Mirror

Code patterns discovered in the codebase. Follow these exactly.

### NAMING_CONVENTION
// SOURCE: [file:lines]
[actual code snippet showing the naming pattern]

### ERROR_HANDLING
// SOURCE: [file:lines]
[actual code snippet showing error handling]

### LOGGING_PATTERN
// SOURCE: [file:lines]
[actual code snippet showing logging]

### REPOSITORY_PATTERN
// SOURCE: [file:lines]
[actual code snippet showing data access]

### SERVICE_PATTERN
// SOURCE: [file:lines]
[actual code snippet showing service layer]

### TEST_STRUCTURE
// SOURCE: [file:lines]
[actual code snippet showing test setup]

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `path/to/file.ts` | CREATE | New service for feature |
| `path/to/existing.ts` | UPDATE | Add new method |

## NOT Building

- [Explicit item 1 that is out of scope]
- [Explicit item 2 that is out of scope]

---

## Step-by-Step Tasks

### Task 1: [Name]
- **ACTION**: [What to do]
- **IMPLEMENT**: [Specific code/logic to write]
- **MIRROR**: [Pattern from Patterns to Mirror section to follow]
- **IMPORTS**: [Required imports]
- **GOTCHA**: [Known pitfall to avoid]
- **VALIDATE**: [How to verify this task is correct]

### Task 2: [Name]
- **ACTION**: ...
- **IMPLEMENT**: ...
- **MIRROR**: ...
- **IMPORTS**: ...
- **GOTCHA**: ...
- **VALIDATE**: ...

[Continue for all tasks...]

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| ... | ... | ... | ... |

### Edge Cases Checklist
- [ ] Empty input
- [ ] Maximum size input
- [ ] Invalid types
- [ ] Concurrent access
- [ ] Network failure (if applicable)
- [ ] Permission denied

---

## Validation Commands

### Static Analysis
```bash
# Run type checker
[project-specific type check command]
```
EXPECT: Zero type errors

### Unit Tests
```bash
# Run tests for affected area
[project-specific test command]
```
EXPECT: All tests pass

### Full Test Suite
```bash
# Run complete test suite
[project-specific full test command]
```
EXPECT: No regressions

### Database Validation (if applicable)
```bash
# Verify schema/migrations
[project-specific db command]
```
EXPECT: Schema up to date

### Browser Validation (if applicable)
```bash
# Start dev server and verify
[project-specific dev server command]
```
EXPECT: Feature works as designed

### Manual Validation
- [ ] [Step-by-step manual verification checklist]

---

## Acceptance Criteria
- [ ] All tasks completed
- [ ] All validation commands pass
- [ ] Tests written and passing
- [ ] No type errors
- [ ] No lint errors
- [ ] Matches UX design (if applicable)

## Completion Checklist
- [ ] Code follows discovered patterns
- [ ] Error handling matches codebase style
- [ ] Logging follows codebase conventions
- [ ] Tests follow test patterns
- [ ] No hardcoded values
- [ ] Documentation updated (if needed)
- [ ] No unnecessary scope additions
- [ ] Self-contained — no questions needed during implementation

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ... | ... | ... | ... |

## Notes
[Any additional context, decisions, or observations]
```
---

## Output

### Lưu Plan

Ghi plan đã tạo vào:
```
.claude/PRPs/plans/{kebab-case-feature-name}.plan.md
```

### Cập nhật PRD (nếu đầu vào là PRD)

Nếu plan này được tạo từ một phase của PRD:
1. Cập nhật trạng thái phase từ `pending` sang `in-progress`
2. Thêm đường dẫn file plan làm tham chiếu trong phase

### Báo cáo cho người dùng

```
## Plan Created

- **File**: .claude/PRPs/plans/{kebab-case-feature-name}.plan.md
- **Source PRD**: [path or "N/A"]
- **Phase**: [phase name or "standalone"]
- **Complexity**: [level]
- **Scope**: [N files, M tasks]
- **Key Patterns**: [top 3 discovered patterns]
- **External Research**: [topics researched or "none needed"]
- **Risks**: [top risk or "none identified"]
- **Confidence Score**: [1-10] — likelihood of single-pass implementation

> Next step: Run `/prp-implement .claude/PRPs/plans/{name}.plan.md` to execute this plan.
```

---

## Verification

Trước khi hoàn tất, hãy đối chiếu plan với các checklist sau:

### Context Completeness
- [ ] Đã khám phá và ghi lại tất cả file liên quan
- [ ] Đã ghi lại quy ước đặt tên kèm ví dụ
- [ ] Đã ghi lại các pattern xử lý lỗi
- [ ] Đã xác định các pattern test
- [ ] Đã liệt kê dependency

### Implementation Readiness
- [ ] Mỗi task đều có ACTION, IMPLEMENT, MIRROR và VALIDATE
- [ ] Không task nào cần tìm kiếm thêm trong codebase
- [ ] Đã chỉ định đường dẫn import
- [ ] Đã ghi lại GOTCHA ở nơi áp dụng

### Pattern Faithfulness
- [ ] Các đoạn code là ví dụ thực tế từ codebase (không tự bịa)
- [ ] Các tham chiếu SOURCE trỏ tới file và số dòng có thật
- [ ] Các pattern bao phủ naming, lỗi, logging, truy cập dữ liệu và test
- [ ] Code mới sẽ không thể phân biệt với code hiện có

### Validation Coverage
- [ ] Đã chỉ định lệnh static analysis
- [ ] Đã chỉ định lệnh test
- [ ] Đã bao gồm xác minh build

### UX Clarity
- [ ] Đã ghi lại trạng thái trước/sau (hoặc đánh dấu N/A)
- [ ] Đã liệt kê các thay đổi tương tác
- [ ] Đã xác định các edge case của UX

### Bài kiểm tra "không cần kiến thức trước" (No Prior Knowledge Test)
Một developer không quen codebase này phải có thể triển khai tính năng chỉ bằng plan này, không cần tìm kiếm trong codebase hay đặt câu hỏi. Nếu không, hãy bổ sung context còn thiếu.

---

## Các bước tiếp theo

- Chạy `/prp-implement <plan-path>` để thực thi plan này
- Chạy `/plan` để lập kế hoạch nhanh bằng hội thoại, không tạo artifact
- Chạy `/prp-prd` để tạo PRD trước nếu phạm vi chưa rõ
````
