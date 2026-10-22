---
paths:
  - "**/nuxt.config.*"
  - "**/server/**/*.ts"
  - "**/pages/**"
  - "**/layouts/**"
  - "**/middleware/**"
---

# Kiểm thử Nuxt

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Nuxt.

Package: `@nuxt/test-utils`. Ưu tiên Vitest cho unit test và component test, có hỗ trợ sẵn E2E trên trình duyệt bằng Playwright. nuxt-vitest và vitest-environment-nuxt đã bị thay thế và gộp vào package này.

## Thiết lập

- Cài dev dependency: `@nuxt/test-utils vitest @vue/test-utils happy-dom playwright-core`.
- Config: `defineVitestConfig({ test: { environment: 'nuxt' } })` từ `@nuxt/test-utils/config`. Dùng `defineVitestProject` cho multi-project (tách riêng môi trường unit / nuxt / e2e).
- Thêm `@nuxt/test-utils/module` vào `nuxt.config`. Có thể bật theo từng file qua `// @vitest-environment nuxt`.

## Runtime helper

Import từ `@nuxt/test-utils/runtime`.

- `mountSuspended(component, opts)` mount trong môi trường Nuxt với async setup + inject plugin (nhận các option mount của `@vue/test-utils` + `route`).
- `renderSuspended(component, opts)` là biến thể cho Testing Library (cần `@testing-library/vue`).
- `mockNuxtImport(name, factory)` mock các auto-import (ví dụ `useState`). Mỗi import chỉ một lần trong mỗi file, dùng `vi.hoisted()`.
- `mockComponent(name, factory)` mock theo tên PascalCase hoặc path.
- `registerEndpoint(path, handler|opts)` mock một endpoint Nitro để test server route hoặc stub backend. Hỗ trợ method + `once`.

## E2E helper

Import từ `@nuxt/test-utils/e2e`.

- `await setup({ rootDir, server, browser, ... })` bên trong khối describe (quản lý beforeAll/afterAll).
- Sau đó dùng `$fetch(url)` (HTML đã render), `fetch(url)` (response object), `url(path)` (URL đầy đủ kèm port), `createPage(url)` (Playwright).
- Tích hợp Playwright: import `expect` / `test` từ `@nuxt/test-utils/playwright`.

## Test cái gì và test như thế nào

- Composable: mock auto-import bằng `mockNuxtImport`, mount một host component qua `mountSuspended` để chạy `useState` / `useFetch` trong runtime của Nuxt.
- Server route: dùng `registerEndpoint` để stub, hoặc e2e `$fetch` / `fetch` tới server Nitro thật.

## Tham chiếu

- Skill ECC: `nuxt4-patterns`, `e2e-testing`, `vite-patterns`.
- [Nuxt testing docs](https://nuxt.com/docs/getting-started/testing)
- [@nuxt/test-utils npm](https://www.npmjs.com/package/@nuxt/test-utils)
