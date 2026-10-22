---
paths:
  - "**/*.vue"
  - "**/*.ts"
  - "**/*.tsx"
---

# Hook Vue

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung riêng cho Vue.

## Mục tiêu của PostToolUse

Chạy trên `*.vue`, `*.ts` và `*.tsx` sau khi sửa. Giới hạn phạm vi vào các file đã thay đổi khi có thể.

## Typecheck

- Dùng `vue-tsc --noEmit` để kiểm tra SFC cùng TypeScript. `tsc` thuần không đọc được single-file component `.vue`, nên không được dùng làm hook typecheck cho dự án này.
- Typecheck là phạm vi toàn dự án. Hãy debounce hoặc giới hạn phạm vi để vòng lặp lưu-sau-mỗi-lần-gõ-phím không làm editor bị đơ.

## Lint và Format

- `eslint --fix` với `eslint-plugin-vue` (flat-config `vue/vue3-recommended`) bao phủ cả lint template lẫn script.
- `prettier --write` để định dạng. Ưu tiên Prettier-qua-ESLint hơn một lượt Prettier riêng để tránh định dạng hai lần và vòng lặp xung đột.

## Ranh giới kiến trúc

- Tùy chọn: thực thi ranh giới slice của Feature-Sliced Design bằng `@feature-sliced/steiger` hoặc `eslint-plugin-boundaries` để chặn import sâu xuyên slice.

## Thứ tự thực hiện

```bash
# changed files only
eslint --fix "$FILE"
prettier --write "$FILE"
# project-wide, debounced
vue-tsc --noEmit
```

- Chạy lint và format theo từng file trước, rồi typecheck toàn dự án sau cùng để lỗi type phản ánh source đã được định dạng.

## Tham chiếu

- Skill ECC: `frontend-patterns`, `vite-patterns`.
- Tài liệu: <https://github.com/vuejs/language-tools> (vue-tsc) · <https://eslint.vuejs.org/> · <https://github.com/feature-sliced/steiger>
