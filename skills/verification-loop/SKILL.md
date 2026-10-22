---
name: verification-loop
description: Chạy quy trình xác minh sáu giai đoạn cho công việc của một phiên Claude Code — build, type check, lint, test kèm coverage, security grep và diff review — rồi tạo báo cáo xác minh PASS/FAIL. Dùng khi xác minh công việc sau khi hoàn thành một tính năng hoặc refactor, trước khi tạo PR, hoặc khi các quality gate phải pass.
license: MIT
metadata:
  origin: ECC
---

# Skill Verification Loop

Một hệ thống xác minh toàn diện cho các phiên Claude Code.

## Khi nào dùng

Gọi skill này:
- Sau khi hoàn thành một tính năng hoặc thay đổi code đáng kể
- Trước khi tạo PR
- Khi muốn đảm bảo các quality gate pass
- Sau khi refactor

## Các giai đoạn xác minh

### Giai đoạn 1: Xác minh build
```bash
set -o pipefail  # report the build's exit status, not tail's
# Check if project builds
npm run build 2>&1 | tail -20
# OR
pnpm build 2>&1 | tail -20
```

Nếu build thất bại, DỪNG và sửa trước khi tiếp tục.

### Giai đoạn 2: Type check
```bash
set -o pipefail
# TypeScript projects
npx --no-install tsc --noEmit 2>&1 | sed -n '1,30p'

# Python projects
pyright . 2>&1 | sed -n '1,30p'
```

Báo cáo mọi lỗi type. Sửa các lỗi nghiêm trọng (critical) trước khi tiếp tục.

### Giai đoạn 3: Lint check

Dùng `sed` để giới hạn output hiển thị trong khi vẫn tiêu thụ toàn bộ stream. Cách này giúp một linter chạy thành công không bị lỗi do SIGPIPE khi `pipefail` được bật.
```bash
set -o pipefail
# JavaScript/TypeScript
npm run lint 2>&1 | sed -n '1,30p'

# Python
ruff check . 2>&1 | sed -n '1,30p'
```

### Giai đoạn 4: Test suite
```bash
set -o pipefail
# Run tests with coverage
npm run test -- --coverage 2>&1 | tail -50

# Check coverage threshold
# Target: 80% minimum
```

Báo cáo:
- Tổng số test: X
- Passed: X
- Failed: X
- Coverage: X%

### Giai đoạn 5: Security scan
```bash
# Check for secrets
grep -rn "sk-" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "api_key" --include="*.ts" --include="*.js" . 2>/dev/null | head -10

# Check for console.log
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10
```

### Giai đoạn 6: Diff review
```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

Review từng file đã thay đổi để tìm:
- Thay đổi ngoài ý muốn
- Thiếu xử lý lỗi
- Các edge case tiềm ẩn

## Định dạng output

Sau khi chạy tất cả các giai đoạn, tạo báo cáo xác minh:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Chế độ liên tục (Continuous Mode)

Với các phiên dài, chạy xác minh mỗi 15 phút hoặc sau các thay đổi lớn:

```markdown
Set a mental checkpoint:
- After completing each function
- After finishing a component
- Before moving to next task

Run: /verify
```

## Tích hợp với Hook

Skill này bổ trợ cho các hook PostToolUse nhưng cung cấp xác minh sâu hơn.
Hook bắt lỗi ngay lập tức; skill này cung cấp review toàn diện.
