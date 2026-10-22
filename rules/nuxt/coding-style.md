---
paths:
  - "**/nuxt.config.*"
  - "**/app.config.*"
  - "**/app.vue"
  - "**/pages/**"
  - "**/layouts/**"
  - "**/middleware/**"
---

# Phong cách code Nuxt

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Nuxt.

## Cấu trúc thư mục

- `srcDir` mặc định là `app/`. Các file của framework nằm ở `app/pages/`, `app/layouts/`, `app/middleware/`, `app/plugins/`, `app/app.config.ts`. `nuxt.config.ts` và `server/` nằm ở root của dự án.
- Một số dự án ghi đè `srcDir` thành `src/` để dùng cấu trúc Feature-Sliced Design, ánh xạ lại `dir.pages` (ví dụ sang `src/app/routes`), `dir.layouts` và các alias `@`/`~`. Luôn kiểm tra `nuxt.config.ts` trước khi giả định một đường dẫn.

## Kỷ luật với auto-import

- Các composable trong `app/composables/` và `server/utils/` được auto-import. KHÔNG import thủ công các composable của Nuxt (`useFetch`, `useState`, `navigateTo`) hay `defineStore` / `storeToRefs`.
- KHÔNG thêm dependency `vue-router` riêng lẻ (Nuxt đã đóng gói v5) và không tự mount `createApp` / `createPinia` / `createRouter`. Framework đã tự nối các thành phần này.

## Compiler macro

- `definePageMeta` là một compile-time macro. Chỉ dùng giá trị tĩnh, không dùng dữ liệu reactive và không gọi hàm có side effect bên trong nó.
- Mở rộng `PageMeta` có kiểu qua `declare module '#app'` thay vì ép kiểu (cast).

## Tách biệt các file cấu hình

Có ba file riêng biệt, đừng nhập nhằng.

- `nuxt.config.ts` = chỉ dành cho build-time (`routeRules`, `modules`, `nitro`, cờ `ssr`). Không reactive.
- `runtimeConfig` (bên trong nuxt.config) = giá trị runtime theo từng môi trường, có thể ghi đè qua `NUXT_*`. Các key ở root chỉ dùng phía server, các key `public` hiển thị với client.
- `app/app.config.ts` = các cài đặt reactive công khai, cố định lúc build (theme token, feature flag). Không ghi đè bằng env. KHÔNG BAO GIỜ chứa secret.

## Head và meta

- `app.head` trong `nuxt.config.ts` chỉ nhận giá trị tĩnh.
- Meta reactive đi qua `useHead` / `useSeoMeta` trong phần setup của component, KHÔNG BAO GIỜ qua `app.head`.

## Tham chiếu

- Skill ECC: `nuxt4-patterns`, `vite-patterns`, `frontend-patterns`.
- [Nuxt directory structure](https://nuxt.com/docs/guide/directory-structure/app)
- [Nuxt configuration](https://nuxt.com/docs/api/nuxt-config)
