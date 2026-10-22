---
paths:
  - "**/*.vue"
---

# Coding Style Vue

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho Vue.

## Cấu trúc SFC

- Luôn dùng `<script setup lang="ts">` với Composition API. Không dùng Options API trong code mới.
- Thứ tự khối trong file `.vue`: `<script setup>`, rồi `<template>`, rồi `<style scoped>`. Mỗi file một component.
- Đặt tên: file component PascalCase (`AuctionCard.vue`), composable camelCase có tiền tố `useXxx` (`useAuctionTimer`).
- Định dạng bằng Prettier cùng ESLint flat config dùng `eslint-plugin-vue` (`vue/vue3-recommended`). Kiểm tra type bằng `vue-tsc`.

## Kỷ luật về Reactivity

- `ref` là API state chính. Thay đổi qua `.value` trong script, chỉ được tự động unwrap ở cấp cao nhất của template.
- `ref` lồng bên trong mảng, `Map` hoặc `Set` vẫn cần `.value` để đọc.
- Chỉ dùng `reactive` cho state dạng object được nhóm lại. Không bao giờ gán lại cả một object `reactive`.
- Không bao giờ destructure một object `reactive` hay Pinia store mà không dùng `toRefs` / `storeToRefs`. Destructure thông thường sẽ âm thầm làm mất reactivity.

## Computed và Watcher

- Getter của `computed` phải thuần (pure): không side effect, không async, không truy cập DOM.
- `computed` từ 3.4+ chỉ kích hoạt khi giá trị trả về thay đổi. Hãy trả về object trước đó không đổi khi bằng nhau để bỏ qua các cập nhật phía sau.
- `watch` là lazy. Truyền getter cho thuộc tính reactive (`watch(() => x.value, ...)`), không truyền object reactive trần.
- `watchEffect` là eager và ngừng theo dõi dependency sau `await` đầu tiên.

## Lifecycle và DOM

- Đăng ký lifecycle hook một cách đồng bộ bên trong `setup` (`onMounted`, `onUnmounted`).
- Dọn dẹp timer, listener và subscription trong `onUnmounted`.
- Chỉ đọc hoặc đo DOM sau `await nextTick()`.

## Macro và Template

- Macro: `defineProps` / `defineEmits` (dạng tuple `change: [id: number]`), `defineModel` (3.4+) cho `v-model`, `withDefaults` hoặc reactive-props-destructure của 3.5+ cho giá trị mặc định, `defineExpose` cho API ref công khai.
- Đặt `:key` trên mọi `v-for`, là một primitive duy nhất và ổn định. Không bao giờ dùng index của mảng, không bao giờ dùng object.
- Không bao giờ đặt `v-if` và `v-for` trên cùng một phần tử. Bọc bằng `<template v-for>` cùng một `v-if` bên trong, hoặc tính trước danh sách đã lọc.

```vue
<script setup lang="ts">
const props = defineProps<{ id: number }>()
const emit = defineEmits<{ change: [id: number] }>()
const open = defineModel<boolean>('open', { default: false })
</script>
```

## Tham chiếu

- Skill ECC: `frontend-patterns`, `vite-patterns`.
- Tài liệu: <https://vuejs.org/api/sfc-script-setup.html> · <https://vuejs.org/guide/essentials/reactivity-fundamentals.html> · <https://eslint.vuejs.org/>
