---
paths:
  - "**/nuxt.config.*"
  - "**/app.config.*"
  - "**/app.vue"
  - "**/server/**/*.ts"
  - "**/pages/**"
  - "**/middleware/**"
---

# Pattern Nuxt

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Nuxt.

## Chọn cách lấy dữ liệu (data-fetch)

Quan trọng. Chọn theo thời điểm render, không theo thói quen.

- `useFetch(url)` = an toàn với SSR, dữ liệu ban đầu/first-paint ưu tiên URL. Là lựa chọn mặc định. Chuyển kết quả từ server qua payload nên không bị fetch hai lần khi hydration.
- `useAsyncData(key, fn)` = an toàn với SSR, cho logic async tùy chỉnh (SDK / GraphQL / các lời gọi kết hợp). Key tường minh giúp chia sẻ kết quả giữa các component.
- `$fetch` = chỉ cho các tương tác phía client (submit form, click nút, POST/PUT/DELETE). KHÔNG an toàn với SSR, sẽ fetch hai lần nếu dùng cho first paint.
- Quy tắc: `useFetch` / `useAsyncData` cho mọi thứ được render ở first paint, `$fetch` chỉ cho các mutation hướng sự kiện.

## State dùng chung

- `useState('key', () => init)` cho state dùng chung an toàn với SSR. Giá trị phải serialize được thành JSON.
- KHÔNG BAO GIỜ `export const x = ref()` ở phạm vi module. Một instance dùng chung sẽ rò rỉ giữa các request SSR đồng thời và gây memory leak.
- Với `@pinia/nuxt`: dùng Pinia cho state của domain, `useState` cho các primitive nhỏ dùng chéo component.
- Khởi tạo bất đồng bộ phía server đặt trong `callOnce(async () => {...})`, không phải là side effect bên trong `useAsyncData`.

## Nitro server route

- `server/api/*.{get,post}.ts` tự đăng ký theo path + method. Handler là `defineEventHandler((event) => ...)`.
- Lỗi qua `throw createError({ status, statusText })`. Ưu tiên `status` / `statusText` theo Web API hơn `statusCode` / `statusMessage` đã deprecated.
- `server/middleware/` KHÔNG ĐƯỢC trả về response. Chỉ mutate `event.context` hoặc đặt header.

## Route middleware

- `app/middleware/*.ts` với `defineNuxtRouteMiddleware((to, from) => ...)`.
- Dùng các đối số `to` / `from`. KHÔNG gọi `useRoute()` bên trong middleware.
- Hậu tố `.global` chạy trên mọi route. Trả về `navigateTo()` để redirect, `abortNavigation()` để dừng.

## Rendering an toàn với hydration

- Rẽ nhánh theo `status` (`idle | pending | success | error`) cho các lazy fetch.
- Payload của `useAsyncData` dùng `devalue` (Date/Map/Set/ref được giữ nguyên). Response của `server/api` chỉ qua `JSON.stringify`, nên hãy định nghĩa `toJSON()` cho các kiểu không phải JSON.
- Giảm payload bằng `pick` / `transform`. Cách này giảm kích thước đã serialize, không bỏ qua việc fetch.

## Tham chiếu

- Skill ECC: `nuxt4-patterns`, `vite-patterns`, `frontend-patterns`.
- [Nuxt data fetching](https://nuxt.com/docs/getting-started/data-fetching)
- [Nuxt state management](https://nuxt.com/docs/getting-started/state-management)
- [Nuxt server engine (Nitro)](https://nuxt.com/docs/guide/directory-structure/server)
