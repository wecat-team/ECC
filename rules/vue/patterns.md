---
paths:
  - "**/*.vue"
---

# Pattern Vue

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung riêng cho Vue.

## Composable

- Composable (`useXxx`) là đơn vị logic tái sử dụng. Trong Feature-Sliced Design, nó nằm ở segment `model` của slice.
- Nhận đầu vào `MaybeRefOrGetter<T>` và chuẩn hóa bằng `toValue`, để bên gọi có thể truyền ref, getter hoặc giá trị thô.
- Trả về `toRefs(reactive(...))` để bên dùng có thể destructure mà không mất reactivity.
- Composable dùng lifecycle hook hoặc `provide` / `inject` phải được gọi bên trong `setup` của component, không gọi lazy hay có điều kiện.

## Props, Emits, v-model

- `defineProps<Props>()` dựa trên type và `defineEmits<{ change: [id: number] }>()` dạng tuple.
- `defineModel<T>('name', { default })` cho binding hai chiều. Nó biên dịch thành một prop cộng một emit `update:*`.

## Provide / Inject

- Dùng `provide` / `inject` cho dữ liệu có phạm vi theo cây mà không cần prop drilling.
- Key an toàn về type, không xung đột: `const key = Symbol() as InjectionKey<T>`.
- Provider sở hữu các mutation. Hãy expose một ref `readonly` cùng một hàm cập nhật tường minh, không bao giờ expose ref mutable thô.

## Pinia (segment model của FSD)

- Ưu tiên setup store: `ref` là state, `computed` là getter, `function` là action.
- Setup store không có sẵn `$reset`. Hãy tự định nghĩa.
- Dùng `storeToRefs` cho state và getter. Destructure action trực tiếp từ store.
- Không bao giờ lưu auth token thô vào `localStorage`.

## vue-router

- Lazy-load các route component bằng `import()` động.
- Một auth gate `beforeEach` toàn cục dựa trên `meta.requiresAuth`. Guard trả về `false` (hủy), một route location (redirect), hoặc `undefined` / `true` (tiếp tục).
- Watch `() => route.params.id`, không watch cả object `route`.

## vue-query (server cache)

- `@tanstack/vue-query` sở hữu state server-cache. Pinia sở hữu state client.
- Đặt các hàm request cùng factory `queryOptions` trong segment `api` của FSD.
- Quan trọng: đặt CHÍNH ref hoặc computed vào query key, không bao giờ đặt `.value`. Truyền `.value` sẽ đóng băng key và làm mất refetch reactive.

```ts
useQuery({ queryKey: ['auction', id], queryFn: () => fetchAuction(toValue(id)) })
// after a mutation
queryClient.invalidateQueries({ queryKey: ['auction', id] })
```

## Tham chiếu

- Skill ECC: `frontend-patterns`, `vite-patterns`.
- Tài liệu: <https://pinia.vuejs.org/> · <https://router.vuejs.org/> · <https://tanstack.com/query/latest/docs/framework/vue/overview> · <https://vuejs.org/guide/reusability/composables.html>
