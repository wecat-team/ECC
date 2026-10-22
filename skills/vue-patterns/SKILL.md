---
name: vue-patterns
description: Các pattern Vue.js 3 Composition API, kiến trúc component, best practice về reactivity, quản lý state bằng Pinia, điều hướng Vue Router và các pattern SSR của Nuxt. Kích hoạt cho dự án Vue, Nuxt, Vite hoặc Pinia. Dùng khi xây dựng hoặc review code Vue 3, Nuxt hoặc Pinia — Composition API, reactivity hoặc điều hướng router.
origin: ECC
---

# Pattern và best practice Vue.js

Hướng dẫn toàn diện cho phát triển Vue.js 3 dùng Composition API (`<script setup>`), bao gồm thiết kế component, reactivity, quản lý state, routing, testing và pattern SSR. Có kèm hướng dẫn riêng cho Nuxt ở những chỗ khác với Vue thuần.

## Khi nào kích hoạt

Kích hoạt skill này khi:
- Dự án dùng Vue.js (bất kỳ phiên bản nào), Nuxt, Vite + Vue hoặc Pinia.
- Người dùng hỏi về kiến trúc component Vue, composable, reactivity hoặc quản lý state.
- Review các Vue Single-File Component (file `.vue`).
- Thiết lập Vue Router, Pinia store hoặc cấu hình Vite/Vitest.
- Thảo luận về hiệu năng, bảo mật hoặc pattern SSR đặc thù của Vue.

---

## 1. Cấu trúc dự án

### Layout khuyến nghị (Feature-First)

```
src/
├── api/              # API client and endpoint definitions
├── assets/           # Static assets (images, fonts, icons)
├── components/       # Shared/reusable components
│   ├── base/         # Base UI primitives (Button, Input, Modal)
│   └── features/     # Feature-specific shared components
├── composables/      # Reusable Composition API logic
├── layouts/          # Page layouts (optional)
├── pages/            # Route-level page components
├── router/           # Vue Router configuration
├── stores/           # Pinia stores
├── types/            # TypeScript type definitions
├── utils/            # Pure utility functions
└── App.vue           # Root component
```

### Đặt tên file

| Quy ước | Khi nào dùng |
|-----------|-------------|
| `PascalCase.vue` | Mọi component (được ép buộc bởi `vue/multi-word-component-names`) |
| `useCamelCase.ts` | Composable |
| `camelCase.ts` | Utility, API client, type |
| thư mục `kebab-case` | Route segment, thư mục feature |

---

## 2. Kiến trúc component

### Thứ tự trong Single-File Component

```vue
<script setup lang="ts">
// 1. Imports (vue → ecosystem → absolute → relative)
// 2. Props & Emits & Slots
// 3. Composables
// 4. Local state (ref/reactive)
// 5. Computed properties
// 6. Methods
// 7. Watchers
// 8. Lifecycle hooks
</script>

<template>
  <!-- Template content -->
</template>

<style scoped>
  /* Scoped styles */
</style>
```

### Presentational và Container

- **Container component**: Tự đảm nhiệm data fetching, state và side effect. Render các presentational component.
- **Presentational component**: Nhận props, emit event. Không gọi API, không truy cập store. Chỉ render thuần.

### Best practice cho Props

```ts
// Type-based props with defaults
interface Props {
  label: string;
  variant?: "primary" | "secondary";
  disabled?: boolean;
  items: Item[];
}

const props = withDefaults(defineProps<Props>(), {
  variant: "primary",
  disabled: false,
});
```

- LUÔN LUÔN khai báo `type`, và `required`/`default` khi phù hợp.
- Prop kiểu boolean: `isXxx`, `hasXxx`, `canXxx`.
- KHÔNG BAO GIỜ mutate props — hãy emit event.
- Với binding v-model, dùng `defineModel()` (Vue 3.4+) hoặc `modelValue` + `update:modelValue`.

### Events

```ts
const emit = defineEmits<{
  submit: [];
  "update:modelValue": [value: string];
  select: [id: string, index: number];
}>();
```

- Dùng kebab-case trong template (`@update:model-value`).
- Dùng camelCase trong script (`emit("update:modelValue", val)`).

---

## 3. Composable (logic tái sử dụng)

### Cấu trúc

```ts
// composables/useDebounce.ts
export function useDebounce<T>(value: MaybeRef<T>, delay: number): Ref<T> {
  const debounced = ref(toValue(value)) as Ref<T>;

  let timer: ReturnType<typeof setTimeout>;
  watch(
    () => toValue(value),
    (newVal) => {
      clearTimeout(timer);
      timer = setTimeout(() => { debounced.value = newVal; }, delay);
    }
  );

  onUnmounted(() => clearTimeout(timer));
  return readonly(debounced);
}
```

### Quy tắc

- PHẢI bắt đầu bằng tiền tố `use`.
- Trả về các giá trị reactive (`ref`, `computed`, `reactive`), KHÔNG BAO GIỜ trả về primitive thuần.
- Nhận đầu vào reactive qua `MaybeRef` / `toRef()` / `toValue()`.
- Dọn dẹp side effect trong `onUnmounted` hoặc `onCleanup` của watcher.
- Không có side effect ở phạm vi module.

### So với Mixin

Composable thay thế hoàn toàn mixin của Vue 2:
- **Mixin**: Luồng dữ liệu mờ đục, xung đột nguồn sự thật (source-of-truth), xung đột tên.
- **Composable**: Import tường minh, giá trị trả về rõ ràng, có thể kết hợp (composable) và tree-shake được.

---

## 4. Quản lý state

### Khi nào dùng cái gì

| Pattern | Trường hợp dùng |
|---------|----------|
| `ref()` / `reactive()` | State cục bộ của component |
| Props + Emits | Giao tiếp cha-con |
| Provide / Inject | Theme, config, plugin API |
| Pinia store | State toàn cục, dùng chung, phức tạp |
| Server state composable | Dữ liệu API có caching (bọc `fetch`/TanStack Query) |

### Pinia Setup Store (ưu tiên)

```ts
// stores/useCartStore.ts
export const useCartStore = defineStore("cart", () => {
  const items = ref<CartItem[]>([]);
  const isLoading = ref(false);

  const totalPrice = computed(() =>
    items.value.reduce((sum, i) => sum + i.price * i.quantity, 0)
  );
  const itemCount = computed(() =>
    items.value.reduce((sum, i) => sum + i.quantity, 0)
  );

  async function addItem(productId: string) {
    isLoading.value = true;
    try {
      const item = await fetchProduct(productId);
      const existing = items.value.find(i => i.id === item.id);
      if (existing) existing.quantity++;
      else items.value.push({ ...item, quantity: 1 });
    } finally {
      isLoading.value = false;
    }
  }

  return { items, isLoading, totalPrice, itemCount, addItem };
});
```

- Dùng cú pháp Setup Store (không dùng Options Store).
- Ưu tiên action cho các mutation ở mức nghiệp vụ và `$patch()` cho các cập nhật theo nhóm.
- Mọi async action: xử lý loading + success + error.

---

## 5. Vue Router

### Định nghĩa route

```ts
const routes = [
  {
    path: "/users/:id",
    name: "user-detail",
    component: () => import("@/pages/UserDetail.vue"), // lazy
    props: true, // pass params as props
    meta: { requiresAuth: true },
  },
];
```

### Navigation Guard

```ts
router.beforeEach((to, from) => {
  const { isLoggedIn } = useAuthStore();
  if (to.meta.requiresAuth && !isLoggedIn) {
    return { name: "login", query: { redirect: to.fullPath } };
  }
});
```

### Route param reactive

Khi một component vẫn được mount nhưng route param thay đổi:

```ts
const route = useRoute();
const id = computed(() => route.params.id as string);
watch(id, (newId) => fetchItem(newId));
```

---

## 6. Pattern cho Template

### Cú pháp Template

```vue
<!-- v-if/v-else-if/v-else -->
<div v-if="isLoading">Loading...</div>
<div v-else-if="error">Error: {{ error }}</div>
<div v-else>{{ content }}</div>

<!-- v-show for frequent toggles -->
<div v-show="isOpen">Toggled content</div>

<!-- v-for with stable keys -->
<div v-for="item in items" :key="item.id">{{ item.name }}</div>

<!-- Computed filtered list (not v-if + v-for on same element) -->
<div v-for="item in activeItems" :key="item.id">{{ item.name }}</div>

<!-- Event handling -->
<form @submit.prevent="handleSubmit">
  <button type="submit">Save</button>
</form>

<!-- v-model -->
<input v-model="name" />
<CustomInput v-model="value" v-model:title="title" />
```

---

## 7. Hiệu năng

| Kỹ thuật | Khi nào dùng |
|-----------|-------------|
| `v-memo` | Các item trong danh sách hiếm khi thay đổi |
| `v-once` | Nội dung chỉ render một lần và tĩnh mãi mãi |
| `shallowRef()` | Cấu trúc dữ liệu lớn được thay thế nguyên khối |
| `shallowReactive()` | Chỉ các property cấp cao nhất là reactive |
| `v-show` thay cho `v-if` | Bật/tắt hiển thị thường xuyên |
| `<KeepAlive :max="10">` | Cache các view được bật/tắt |
| Lazy route | `() => import(...)` cho các route không quan trọng |
| `Suspense` | Tải async component kèm fallback |

---

## 8. Testing

### Stack

- **Vitest** cho unit test và component test
- **Vue Test Utils** để mount và tương tác
- **@pinia/testing** để mock store
- **Playwright** cho E2E

### Pattern test component

```ts
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import UserCard from "./UserCard.vue";

beforeEach(() => { setActivePinia(createPinia()); });

it("renders and emits", async () => {
  const wrapper = mount(UserCard, {
    props: { user: { id: "1", name: "Alice" } },
  });
  expect(wrapper.text()).toContain("Alice");
  await wrapper.find("button").trigger("click");
  expect(wrapper.emitted("select")![0]).toEqual(["1"]);
});
```

---

## 9. Pattern riêng cho Nuxt

### Auto-Import

Nuxt tự động import `ref`, `computed`, `watch`, `useFetch`, `useAsyncData`, v.v. Dùng trực tiếp mà không cần import. Với dự án không phải Nuxt, luôn import tường minh.

### useAsyncData / useFetch

```ts
const { data: user, pending, error, refresh } = await useAsyncData(
  "user", // unique key for caching
  () => $fetch(`/api/users/${id}`),
);

const { data: posts } = await useFetch("/api/posts", {
  query: { page: 1 },
  key: "posts-page-1", // dedupes requests
});
```

### Server Route

```ts
// server/api/users/[id].ts
export default defineEventHandler(async (event) => {
  const { id } = await getValidatedRouterParams(event, z.object({
    id: z.string().uuid(),
  }).parse);
  // ... fetch and return
});
```

### Runtime Config

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    // server-only
    apiSecret: "",
    // public (exposed to client)
    public: {
      apiBase: "https://api.example.com",
    },
  },
});
```

---

## 10. Các API mới của Vue 3.5+

### Reactive Props Destructure

Vue 3.5 đã ổn định reactive props destructure — các biến được destructure từ `defineProps()` tự động reactive:

```ts
// Vue 3.5+: destructured props are reactive (no need for toRefs)
const { count = 0, msg = "hello" } = defineProps<{
  count?: number;
  msg?: string;
}>();

// Limitation: cannot watch destructured prop directly
watch(() => count, (newVal) => { ... }); // PASS getter required
```

### `useTemplateRef()`

Thay các ref thường khớp theo tên bằng `useTemplateRef()` cho template reference:

```ts
import { useTemplateRef } from "vue";
const inputEl = useTemplateRef<HTMLInputElement>("input");
// "input" matches the ref="input" attribute in template, not the variable name
```

Hỗ trợ ref ID động: `useTemplateRef(dynamicRefId)`.

### `onWatcherCleanup()`

API dọn dẹp watcher có thể import toàn cục (Vue 3.5+). Phải được gọi đồng bộ bên trong callback của watcher:

```ts
import { watch, onWatcherCleanup } from "vue";

watch(userId, async (newId) => {
  const controller = new AbortController();
  onWatcherCleanup(() => controller.abort());
  // ... fetch with signal
});
```

### `useId()`

Sinh ID duy nhất ổn định với SSR cho phần tử form và accessibility:

```ts
import { useId } from "vue";
const id = useId();
```

### Teleport `defer`

`<Teleport defer>` cho phép teleport tới các target được render trong cùng một chu kỳ:

```vue
<Teleport defer to="#container">Content</Teleport>
<div id="container"></div>
```

### Lazy Hydration (SSR)

`defineAsyncComponent()` giờ hỗ trợ chiến lược `hydrate`:

```ts
import { defineAsyncComponent, hydrateOnVisible } from "vue";
const AsyncComp = defineAsyncComponent({
  loader: () => import("./Comp.vue"),
  hydrate: hydrateOnVisible(),
});
```

---

## Anti-Pattern

| Anti-Pattern | Vì sao sai | Cách sửa |
|-------------|---------------|---------|
| Destructure `defineProps()` (Vue < 3.5) | Chụp snapshot, mất reactivity | Truy cập qua `props.xxx` hoặc dùng `toRefs()` |
| `watch()` trên prop đã destructure (Vue 3.5+) | Lỗi lúc compile — prop đã destructure không thể watch trực tiếp | Dùng getter wrapper: `watch(() => count, ...)` |
| `v-if` + `v-for` trên cùng một phần tử | Thứ tự thực thi không rõ ràng | Dùng mảng đã lọc bằng computed |
| key của `v-for` = index | State hỏng khi đổi thứ tự | Dùng ID ổn định từ database |
| Mutate props | Vi phạm luồng dữ liệu một chiều | Emit event hoặc dùng `v-model` |
| `v-html` với nội dung người dùng | Lỗ hổng XSS | Sanitize bằng DOMPurify |
| Mixin trong Vue 3 | Mờ đục, dễ xung đột | Thay bằng composable |
| Side effect ở phạm vi module trong composable | Bị chia sẻ giữa các instance | Giới hạn phạm vi trong `onMounted` + `onUnmounted` |
| `reactive()` cho state có thể bị thay thế | Việc thay thế làm hỏng reactivity | Dùng `ref()` thay thế |
| Watcher không có cleanup | Rò rỉ bộ nhớ, race condition | Dùng `onCleanup` hoặc `onWatcherCleanup()` (Vue 3.5+) |
| Options API trong code Vue 3 mới | Hệ sinh thái đã chuyển sang Composition API | Dùng `<script setup>` |
| Ref thường cho template reference | Không hỗ trợ ref động, khớp theo tên dễ vỡ | Dùng `useTemplateRef()` (Vue 3.5+) |

## Skill liên quan

- `accessibility` — ARIA, HTML ngữ nghĩa, quản lý focus
- `frontend-patterns` — Kiến trúc frontend xuyên framework
- `typescript` — best practice TypeScript áp dụng cho dự án Vue
- `coding-standards` — Tiêu chuẩn chất lượng code chung
