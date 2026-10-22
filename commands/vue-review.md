---
description: Code review Vue.js toàn diện về tính đúng đắn của Composition API, reactivity, pattern composable, bảo mật template, accessibility và hiệu năng đặc thù Vue. Gọi agent vue-reviewer (và typescript-reviewer song song với các thay đổi .vue/.ts).
---

# Vue Code Review

Lệnh này gọi agent **vue-reviewer** để thực hiện code review đặc thù cho Vue. Với pull request chạm vào file `.vue` hoặc file `.ts`/`.js` có chứa Vue, cả `vue-reviewer` và `typescript-reviewer` đều nên chạy — mỗi agent phụ trách một mảng riêng.

## Lệnh này làm gì

1. **Xác định thay đổi Vue**: Tìm các file `.vue` đã sửa và các file `.ts`/`.js` liên quan đến Vue qua `git diff`
2. **Chạy lint**: Thực thi `eslint` với `eslint-plugin-vue`
3. **Typecheck**: Chạy `vue-tsc --noEmit` hoặc lệnh typecheck chuẩn của project
4. **Chỉ review các mảng Vue**: Reactivity, composable, bảo mật template, accessibility, hiệu năng đặc thù Vue
5. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng (CRITICAL / HIGH / MEDIUM)

## Khi nào dùng

Dùng `/vue-review` khi:

- Một PR hoặc commit chạm vào file `.vue`
- Sau khi viết hoặc sửa component Vue, composable hoặc Pinia store
- Trước khi merge code Vue
- Audit bảo mật template (`v-html`, URL binding)
- Review một composable mới về tính đúng đắn
- Audit guard và điều hướng của Vue Router
- Review các server route của Nuxt hoặc code đặc thù SSR

Với thay đổi `.ts`/`.js` thuần không import Vue, dùng `/code-review` (chung) hoặc gọi trực tiếp `typescript-reviewer`.

## Phạm vi so với `/code-review` và TypeScript Review

| Công cụ | Phạm vi |
|---|---|
| `vue-reviewer` (lệnh này) | Reactivity, composable, bảo mật template, a11y, hiệu năng Vue, Pinia/Router |
| `typescript-reviewer` | TS/JS chung — lạm dụng `any`, tính đúng đắn của async, bảo mật Node |
| `security-reviewer` | Audit bảo mật toàn project |
| `/code-review` | Review chung các thay đổi chưa commit hoặc PR |

Với PR `.vue` / liên quan đến Vue, hãy gọi cả `vue-reviewer` và `typescript-reviewer`. Các phát hiện của mỗi bên được thiết kế để không chồng lấn nhau.

## Các nhóm review

### CRITICAL (Phải sửa)

- `v-html` với đầu vào chưa được sanitize
- `:href`/`:src` với URL người dùng chưa được kiểm tra (`javascript:`, `data:`)
- Secret trong client bundle (`VITE_*`, `public` runtimeConfig của Nuxt)
- Server endpoint không có kiểm tra đầu vào (Nuxt Nitro)
- Dùng `localStorage`/`sessionStorage` cho session token
- Destructure reactive props trong Vue < 3.5 (làm mất reactivity)
- Thay thế object `reactive()` (làm hỏng watcher)
- Nguồn của watcher theo dõi một ref object thay vì `.value`

### HIGH (Nên sửa)

- Composable có side effect ở module scope
- Thiếu cleanup trong composable (watcher, interval, listener)
- `v-for` không có `:key` hoặc dùng `key={index}`
- `v-if` + `v-for` trên cùng một phần tử
- Thay đổi props (props mutation)
- Thiếu kiểm tra prop (prop validation)
- Route guard trả về false mà không redirect
- `useRoute().params` bị destructure ở top-level (snapshot)
- `v-model` bind vào computed không có setter
- Vi phạm accessibility (thiếu label, phần tử tương tác không semantic)
- Thay đổi trực tiếp thuộc tính của store bên ngoài action

### MEDIUM (Cân nhắc)

- Options API trong code Vue 3 mới
- Component dài hơn 300 dòng
- Dùng `v-show` khi `v-if` phù hợp hơn (hoặc ngược lại)
- Thiếu `:max` trên `<KeepAlive>`
- Thiếu `shallowRef` cho dữ liệu lớn bị thay thế
- Tự viết validation thay vì dùng thư viện form đã được kiểm chứng
- `defineExpose` expose nhiều hơn mức cần thiết
- Không tắt `inheritAttrs` khi dùng `v-bind="$attrs"`

## Các kiểm tra tự động được chạy

```bash
# Lint (required)
npx eslint . --ext .vue,.ts,.js

# Vue-specific typecheck
vue-tsc --noEmit

# Targeted security rules
npx eslint . --rule 'vue/no-v-html: warn' \
              --rule 'vue/no-template-target-blank: error'

# Supply-chain
npm audit
```

Nếu `eslint-plugin-vue` hoặc `vue-tsc` chưa được cấu hình, review sẽ đánh dấu khoảng trống đó là vấn đề cấu hình HIGH và tiếp tục.

## Ví dụ sử dụng

````text
User: /vue-review

Agent:
# Vue Code Review Report

## Files Reviewed
- src/components/UserCard.vue (modified)
- src/composables/useUser.ts (new)
- src/stores/useUserStore.ts (modified)

## Lint Results
PASS: eslint clean
PASS: vue-tsc clean

## Issues Found

[CRITICAL] Unsanitized v-html
File: src/components/UserCard.vue:15
Issue: User-controlled bio rendered as raw HTML via v-html.
Why: XSS via stored script tags in user input.
Fix: Sanitize with DOMPurify or render as text:
```vue
<script setup>
import DOMPurify from "dompurify";
const safeBio = computed(() => DOMPurify.sanitize(user.bio));
</script>
<template>
  <div v-html="safeBio" />
</template>
```

[HIGH] Watcher in composable missing cleanup
File: src/composables/useUser.ts:22
Issue: `watch` callback fires fetch without AbortController; stale responses can overwrite newer data.
Fix: Use onCleanup to abort:
```ts
watch(userId, async (newId, _old, onCleanup) => {
  const controller = new AbortController();
  onCleanup(() => controller.abort());
  const data = await fetch(`/api/users/${newId}`, { signal: controller.signal });
  user.value = await data.json();
});
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
````

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|---|---|
| PASS: Approve | Không có vấn đề CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| FAIL: Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các lệnh khác

- Chạy lệnh build của project trước nếu build đang hỏng
- Chạy test để đảm bảo test của component pass
- Chạy `/vue-review` trước khi merge code Vue
- Dùng `/code-review` cho các mối quan tâm không đặc thù Vue trên cùng PR

## Liên quan

- Agent: `agents/vue-reviewer.md`
- Agent đồng hành: `agents/typescript-reviewer.md` (chạy song song cho TS/JS liên quan đến Vue)
- Skills: `skills/vue-patterns/`
- Rules: `rules/vue/`
