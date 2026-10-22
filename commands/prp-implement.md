---
description: Thực thi một kế hoạch triển khai với các vòng lặp validation nghiêm ngặt
argument-hint: <path/to/plan.md>
---

> Phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

# PRP Implement

Thực thi file plan từng bước với validation liên tục. Mọi thay đổi đều được xác minh ngay lập tức — không bao giờ để dồn trạng thái hỏng.

**Triết lý cốt lõi**: Các vòng lặp validation bắt lỗi sớm. Chạy kiểm tra sau mỗi thay đổi. Sửa vấn đề ngay lập tức.

**Quy tắc vàng**: Nếu một validation thất bại, hãy sửa trước khi đi tiếp. Không bao giờ để dồn trạng thái hỏng.

---

## Giai đoạn 0 — DETECT

### Phát hiện Package Manager

| File tồn tại | Package Manager | Runner |
|---|---|---|
| `bun.lockb` | bun | `bun run` |
| `pnpm-lock.yaml` | pnpm | `pnpm run` |
| `yarn.lock` | yarn | `yarn` |
| `package-lock.json` | npm | `npm run` |
| `pyproject.toml` hoặc `requirements.txt` | uv / pip | `uv run` hoặc `python -m` |
| `Cargo.toml` | cargo | `cargo` |
| `go.mod` | go | `go` |

### Các script validation

Kiểm tra `package.json` (hoặc tương đương) để biết các script có sẵn:

```bash
# For Node.js projects
cat package.json | grep -A 20 '"scripts"'
```

Ghi lại các lệnh có sẵn cho: type-check, lint, test, build.

---

## Giai đoạn 1 — LOAD

Đọc file plan:

```bash
cat "$ARGUMENTS"
```

Trích xuất các section sau từ plan:
- **Summary** — Đang xây dựng cái gì
- **Patterns to Mirror** — Quy ước code cần tuân theo
- **Files to Change** — Cần tạo hoặc sửa những gì
- **Step-by-Step Tasks** — Trình tự triển khai
- **Validation Commands** — Cách xác minh tính đúng đắn
- **Acceptance Criteria** — Định nghĩa hoàn thành (definition of done)

Nếu file không tồn tại hoặc không phải plan hợp lệ:
```
Error: Plan file not found or invalid.
Run /prp-plan <feature-description> to create a plan first.
```

**CHECKPOINT**: Đã load plan. Đã xác định tất cả section. Đã trích xuất các task.

---

## Giai đoạn 2 — PREPARE

### Trạng thái Git

```bash
git branch --show-current
git status --porcelain
```

### Quyết định về Branch

| Trạng thái hiện tại | Hành động |
|---|---|
| Đang ở feature branch | Dùng branch hiện tại |
| Ở main, working tree sạch | Tạo feature branch: `git checkout -b feat/{plan-name}` |
| Ở main, working tree bẩn | **DỪNG** — Yêu cầu người dùng stash hoặc commit trước |
| Trong một git worktree dành cho tính năng này | Dùng worktree đó |

### Đồng bộ Remote

```bash
git pull --rebase origin $(git branch --show-current) 2>/dev/null || true
```

**CHECKPOINT**: Đang ở đúng branch. Working tree sẵn sàng. Remote đã đồng bộ.

---

## Giai đoạn 3 — EXECUTE

Xử lý tuần tự từng task trong plan.

### Vòng lặp cho từng Task

Với mỗi task trong **Step-by-Step Tasks**:

1. **Đọc tham chiếu MIRROR** — Mở file pattern được tham chiếu trong trường MIRROR của task. Hiểu quy ước trước khi viết code.

2. **Triển khai** — Viết code theo đúng pattern. Áp dụng các cảnh báo GOTCHA. Dùng đúng IMPORTS đã chỉ định.

3. **Validate ngay lập tức** — Sau MỖI thay đổi file:
   ```bash
   # Run type-check (adjust command per project)
   [type-check command from Phase 0]
   ```
   Nếu type-check thất bại → sửa lỗi trước khi chuyển sang file tiếp theo.

4. **Theo dõi tiến độ** — Ghi log: `[done] Task N: [task name] — complete`

### Xử lý các sai lệch

Nếu việc triển khai buộc phải lệch khỏi plan:
- Ghi chú **CÁI GÌ** đã thay đổi
- Ghi chú **TẠI SAO** nó thay đổi
- Tiếp tục với hướng tiếp cận đã được điều chỉnh
- Các sai lệch này sẽ được ghi lại trong báo cáo

**CHECKPOINT**: Đã thực thi tất cả task. Đã ghi log các sai lệch.

---

## Giai đoạn 4 — VALIDATE

Chạy tất cả các mức validation từ plan. Sửa vấn đề ở từng mức trước khi đi tiếp.

### Mức 1: Phân tích tĩnh (Static Analysis)

```bash
# Type checking — zero errors required
[project type-check command]

# Linting — fix automatically where possible
[project lint command]
[project lint-fix command]
```

Nếu vẫn còn lỗi lint sau khi auto-fix, hãy sửa thủ công.

### Mức 2: Unit Test

Viết test cho mọi function mới (theo chỉ định trong Testing Strategy của plan).

```bash
[project test command for affected area]
```

- Mỗi function cần ít nhất một test
- Bao phủ các edge case được liệt kê trong plan
- Nếu một test thất bại → sửa phần triển khai (không sửa test, trừ khi test sai)

### Mức 3: Kiểm tra Build

```bash
[project build command]
```

Build phải thành công với zero lỗi.

### Mức 4: Integration Testing (nếu áp dụng)

```bash
# Start server, run tests, stop server
[project dev server command] &
SERVER_PID=$!

# Wait for server to be ready (adjust port as needed)
SERVER_READY=0
for i in $(seq 1 30); do
  if curl -sf http://localhost:PORT/health >/dev/null 2>&1; then
    SERVER_READY=1
    break
  fi
  sleep 1
done

if [ "$SERVER_READY" -ne 1 ]; then
  kill "$SERVER_PID" 2>/dev/null || true
  echo "ERROR: Server failed to start within 30s" >&2
  exit 1
fi

[integration test command]
TEST_EXIT=$?

kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true

exit "$TEST_EXIT"
```

### Mức 5: Kiểm thử Edge Case

Chạy qua các edge case trong checklist Testing Strategy của plan.

**CHECKPOINT**: Cả 5 mức validation đều pass. Zero lỗi.

---

## Giai đoạn 5 — REPORT

### Tạo báo cáo triển khai

```bash
mkdir -p .claude/PRPs/reports
```

Ghi báo cáo vào `.claude/PRPs/reports/{plan-name}-report.md`:

```markdown
# Implementation Report: [Feature Name]

## Summary
[What was implemented]

## Assessment vs Reality

| Metric | Predicted (Plan) | Actual |
|---|---|---|
| Complexity | [from plan] | [actual] |
| Confidence | [from plan] | [actual] |
| Files Changed | [from plan] | [actual count] |

## Tasks Completed

| # | Task | Status | Notes |
|---|---|---|---|
| 1 | [task name] | [done] Complete | |
| 2 | [task name] | [done] Complete | Deviated — [reason] |

## Validation Results

| Level | Status | Notes |
|---|---|---|
| Static Analysis | [done] Pass | |
| Unit Tests | [done] Pass | N tests written |
| Build | [done] Pass | |
| Integration | [done] Pass | or N/A |
| Edge Cases | [done] Pass | |

## Files Changed

| File | Action | Lines |
|---|---|---|
| `path/to/file` | CREATED | +N |
| `path/to/file` | UPDATED | +N / -M |

## Deviations from Plan
[List any deviations with WHAT and WHY, or "None"]

## Issues Encountered
[List any problems and how they were resolved, or "None"]

## Tests Written

| Test File | Tests | Coverage |
|---|---|---|
| `path/to/test` | N tests | [area covered] |

## Next Steps
- [ ] Code review via `/code-review`
- [ ] Create PR via `/prp-pr`
```

### Cập nhật PRD (nếu áp dụng)

Nếu lần triển khai này dành cho một phase của PRD:
1. Cập nhật trạng thái phase từ `in-progress` sang `complete`
2. Thêm đường dẫn báo cáo làm tham chiếu

### Lưu trữ Plan

```bash
mkdir -p .claude/PRPs/plans/completed
mv "$ARGUMENTS" .claude/PRPs/plans/completed/
```

**CHECKPOINT**: Đã tạo báo cáo. Đã cập nhật PRD. Đã lưu trữ plan.

---

## Giai đoạn 6 — OUTPUT

Báo cáo cho người dùng:

```
## Implementation Complete

- **Plan**: [plan file path] → archived to completed/
- **Branch**: [current branch name]
- **Status**: [done] All tasks complete

### Validation Summary

| Check | Status |
|---|---|
| Type Check | [done] |
| Lint | [done] |
| Tests | [done] (N written) |
| Build | [done] |
| Integration | [done] or N/A |

### Files Changed
- [N] files created, [M] files updated

### Deviations
[Summary or "None — implemented exactly as planned"]

### Artifacts
- Report: `.claude/PRPs/reports/{name}-report.md`
- Archived Plan: `.claude/PRPs/plans/completed/{name}.plan.md`

### PRD Progress (if applicable)
| Phase | Status |
|---|---|
| Phase 1 | [done] Complete |
| Phase 2 | [next] |
| ... | ... |

> Next step: Run `/prp-pr` to create a pull request, or `/code-review` to review changes first.
```

---

## Xử lý khi thất bại

### Type Check thất bại
1. Đọc kỹ thông báo lỗi
2. Sửa lỗi type trong file nguồn
3. Chạy lại type-check
4. Chỉ tiếp tục khi sạch lỗi

### Test thất bại
1. Xác định lỗi nằm ở phần triển khai hay ở test
2. Sửa nguyên nhân gốc (thường là phần triển khai)
3. Chạy lại test
4. Chỉ tiếp tục khi tất cả xanh

### Lint thất bại
1. Chạy auto-fix trước
2. Nếu vẫn còn lỗi, sửa thủ công
3. Chạy lại lint
4. Chỉ tiếp tục khi sạch lỗi

### Build thất bại
1. Thường là vấn đề type hoặc import — kiểm tra thông báo lỗi
2. Sửa file gây lỗi
3. Chạy lại build
4. Chỉ tiếp tục khi thành công

### Integration Test thất bại
1. Kiểm tra server đã khởi động đúng chưa
2. Xác minh endpoint/route tồn tại
3. Kiểm tra định dạng request khớp với kỳ vọng
4. Sửa và chạy lại

---

## Tiêu chí thành công

- **TASKS_COMPLETE**: Tất cả task trong plan đã được thực thi
- **TYPES_PASS**: Zero lỗi type
- **LINT_PASS**: Zero lỗi lint
- **TESTS_PASS**: Tất cả test xanh, đã viết test mới
- **BUILD_PASS**: Build thành công
- **REPORT_CREATED**: Đã lưu báo cáo triển khai
- **PLAN_ARCHIVED**: Plan đã được chuyển vào `completed/`

---

## Các bước tiếp theo

- Chạy `/code-review` để review thay đổi trước khi commit
- Chạy `/prp-commit` để commit với một message mô tả
- Chạy `/prp-pr` để tạo pull request
- Chạy `/prp-plan <next-phase>` nếu PRD còn nhiều phase
