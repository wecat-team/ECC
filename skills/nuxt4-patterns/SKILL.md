---
name: nuxt4-patterns
description: Các pattern app Nuxt 4 về an toàn hydration, hiệu năng, route rule, lazy loading và lấy dữ liệu an toàn với SSR bằng useFetch và useAsyncData. Dùng khi xây dựng hoặc review một app Nuxt 4, hoặc debug hydration mismatch và việc lấy dữ liệu an toàn với SSR.
metadata:
  origin: ECC
---

# Nuxt 4 Patterns

Dùng khi xây dựng hoặc debug app Nuxt 4 với SSR, hybrid rendering, route rule, hoặc lấy dữ liệu ở cấp trang.

## Khi nào kích hoạt

- Hydration mismatch giữa HTML của server và state của client
- Các quyết định rendering ở cấp route như prerender, SWR, ISR hoặc các section chỉ chạy ở client
- Công việc hiệu năng liên quan đến lazy loading, lazy hydration hoặc kích thước payload
- Lấy dữ liệu cho trang hoặc component bằng `useFetch`, `useAsyncData` hoặc `$fetch`
- Vấn đề routing Nuxt gắn với route param, middleware hoặc khác biệt SSR/client

## An toàn Hydration

- Giữ lần render đầu tiên mang tính xác định (deterministic). Không đặt `Date.now()`, `Math.random()`, API chỉ có ở browser, hoặc việc đọc storage trực tiếp vào state template được SSR render.
- Chuyển logic chỉ có ở browser ra phía sau `onMounted()`, `import.meta.client`, `ClientOnly`, hoặc một component `.client.vue` khi server không thể tạo ra cùng markup.
- Dùng composable `useRoute()` của Nuxt, không dùng cái của `vue-router`.
- Không dùng `route.fullPath` để điều khiển markup được SSR render. URL fragment chỉ có ở client, có thể gây ra hydration mismatch.
- Coi `ssr: false` là lối thoát hiểm cho các vùng thực sự chỉ có ở browser, không phải cách sửa mặc định cho mismatch.

## Lấy dữ liệu

- Ưu tiên `await useFetch()` cho việc đọc API an toàn với SSR trong page và component. Nó chuyển dữ liệu đã fetch ở server vào Nuxt payload và tránh fetch lần hai khi hydration.
- Dùng `useAsyncData()` khi fetcher không phải một lời gọi `$fetch()` đơn giản, khi bạn cần key tùy chỉnh, hoặc khi bạn đang kết hợp nhiều nguồn bất đồng bộ.
- Đặt cho `useAsyncData()` một key ổn định để tái sử dụng cache và hành vi refresh dễ đoán.
- Giữ các handler của `useAsyncData()` không có side effect. Chúng có thể chạy trong SSR và hydration.
- Dùng `$fetch()` cho các thao tác ghi do người dùng kích hoạt hoặc hành động chỉ có ở client, không dùng cho dữ liệu trang cấp cao nhất cần được hydrate từ SSR.
- Dùng `lazy: true`, `useLazyFetch()` hoặc `useLazyAsyncData()` cho dữ liệu không quan trọng không nên chặn điều hướng. Xử lý `status === 'pending'` trong UI.
- Chỉ dùng `server: false` cho dữ liệu không cần cho SEO hoặc first paint.
- Cắt giảm kích thước payload bằng `pick` và ưu tiên payload nông hơn khi không cần deep reactivity.

```ts
const route = useRoute()

const { data: article, status, error, refresh } = await useAsyncData(
  () => `article:${route.params.slug}`,
  () => $fetch(`/api/articles/${route.params.slug}`),
)

const { data: comments } = await useFetch(`/api/articles/${route.params.slug}/comments`, {
  lazy: true,
  server: false,
})
```

## Route Rule

Ưu tiên `routeRules` trong `nuxt.config.ts` cho chiến lược rendering và caching:

```ts
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },
    '/products/**': { swr: 3600 },
    '/blog/**': { isr: true },
    '/admin/**': { ssr: false },
    '/api/**': { cache: { maxAge: 60 * 60 } },
  },
})
```

- `prerender`: HTML tĩnh tại thời điểm build
- `swr`: phục vụ nội dung đã cache và revalidate ở background
- `isr`: incremental static regeneration trên các nền tảng được hỗ trợ
- `ssr: false`: route render ở client
- `cache` hoặc `redirect`: hành vi response ở cấp Nitro

Chọn route rule theo từng nhóm route, không áp dụng toàn cục. Trang marketing, catalog, dashboard và API thường cần các chiến lược khác nhau.

## Lazy Loading và Hiệu năng

- Nuxt đã tự code-split các trang theo route. Hãy giữ ranh giới route có ý nghĩa trước khi tối ưu vi mô việc tách component.
- Dùng tiền tố `Lazy` để import động các component không quan trọng.
- Render có điều kiện các lazy component bằng `v-if` để chunk không được tải cho đến khi UI thực sự cần.
- Dùng lazy hydration cho UI tương tác nằm dưới màn hình đầu (below-the-fold) hoặc không quan trọng.

```vue
<template>
  <LazyRecommendations v-if="showRecommendations" />
  <LazyProductGallery hydrate-on-visible />
</template>
```

- Với các chiến lược tùy chỉnh, dùng `defineLazyHydrationComponent()` với chiến lược visibility hoặc idle.
- Lazy hydration của Nuxt hoạt động trên single-file component. Truyền prop mới vào một component được lazy hydrate sẽ kích hoạt hydration ngay lập tức.
- Dùng `NuxtLink` cho điều hướng nội bộ để Nuxt có thể prefetch các route component và payload được sinh ra.

## Checklist review

- Lần SSR render đầu tiên và lần render client sau hydration tạo ra cùng markup
- Dữ liệu trang dùng `useFetch` hoặc `useAsyncData`, không dùng `$fetch` ở cấp cao nhất
- Dữ liệu không quan trọng là lazy và có UI loading tường minh
- Route rule khớp với yêu cầu SEO và độ mới của trang
- Các island tương tác nặng được lazy-load hoặc lazy hydrate
