---
paths:
  - "**/nuxt.config.*"
  - "**/app.config.*"
  - "**/server/**/*.ts"
  - "**/*.vue"
---

# Hook cho Nuxt

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Nuxt.

Đây là các hook của harness Claude Code dành cho công việc Nuxt. Chúng chạy qua harness, không phải do Claude chạy.

## Typecheck

- `nuxi typecheck` bọc `vue-tsc`. Yêu cầu dev dependency `vue-tsc` + `typescript`.
- Chạy khi sửa `.vue` / `.ts` hoặc pre-commit. Typecheck áp dụng toàn dự án, nên hãy debounce nó và bọc trong timeout (theo `web/hooks.md`, ví dụ `timeout 60 nuxi typecheck`) để một lần type-check bị treo sẽ được thu hồi thay vì dồn lại qua các lần sửa nhanh liên tiếp.

## Lint

- Dùng module `@nuxt/eslint` (flat-config, nhận biết dự án, sinh ra `.nuxt/eslint.config.mjs`).
- Chạy `eslint .` hoặc `eslint --fix`. Đây là tích hợp ESLint chính thức của Nuxt, hãy ưu tiên nó hơn các config tự viết.

## Format

- `prettier --write`, hoặc bật các rule stylistic trong `@nuxt/eslint` để tránh xung đột giữa Prettier và ESLint.
- Chọn một nguồn quyết định định dạng duy nhất. Không chạy đồng thời cả Prettier và ESLint stylistic.

## Chuỗi PostToolUse gợi ý

- Khi Edit `app/**` và `server/**`: chạy `eslint --fix` rồi `timeout 60 nuxi typecheck`.
- Thứ tự quan trọng: lint-fix trước (sửa file), typecheck có timeout sau (xác minh kết quả). Vẫn áp dụng debounce.

## Tham chiếu

- Skill ECC: `nuxt4-patterns`, `vite-patterns`.
- [@nuxt/eslint module](https://eslint.nuxt.com/)
- [nuxi typecheck](https://nuxt.com/docs/api/commands/typecheck)
