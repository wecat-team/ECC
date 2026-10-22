---
description: Review PR toàn diện bằng các agent chuyên biệt (code-reviewer, comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-simplifier). Dùng cho một lượt review PR đa agent; với lượt Workflow được xác minh đối kháng hãy dùng /orch-review, và với review checklist từng bước độc lập hãy dùng /code-review.
---

Chạy một lượt review đa góc nhìn toàn diện cho một pull request.

## Cách dùng

`/review-pr [PR-number-or-URL] [--focus=comments|tests|errors|types|code|simplify]`

Nếu không chỉ định PR, review PR của branch hiện tại. Nếu không chỉ định focus, chạy toàn bộ stack review.

## Các bước

1. Xác định PR:
   - dùng `gh pr view` để lấy chi tiết PR, các file đã thay đổi và diff
2. Tìm hướng dẫn của project:
   - tìm `CLAUDE.md`, cấu hình lint, cấu hình TypeScript, quy ước của repo
3. Chạy các agent review chuyên biệt:
   - `code-reviewer`
   - `comment-analyzer`
   - `pr-test-analyzer`
   - `silent-failure-hunter`
   - `type-design-analyzer`
   - `code-simplifier`
4. Tổng hợp kết quả:
   - loại bỏ các phát hiện trùng lặp
   - xếp hạng theo mức độ nghiêm trọng
5. Báo cáo các phát hiện được nhóm theo mức độ nghiêm trọng

## Quy tắc về độ tin cậy (Confidence)

Chỉ báo cáo các vấn đề có confidence >= 80:

- Critical: bug, bảo mật, mất dữ liệu
- Important: thiếu test, vấn đề chất lượng, vi phạm style
- Advisory: chỉ đưa ra gợi ý khi được yêu cầu tường minh
