---
paths:
  - "**/nuxt.config.*"
  - "**/app.config.*"
  - "**/server/**/*.ts"
---

# Bảo mật Nuxt

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Nuxt.

## runtimeConfig public và private

- Các key `runtimeConfig` ở root chỉ dùng phía server. `runtimeConfig.public` được serialize vào payload của MỌI trang (hiển thị với client).
- Secret chỉ đặt ở root. KHÔNG BAO GIỜ đặt secret trong `app.config.ts` hoặc `runtimeConfig.public`, cả hai đều được đưa vào client bundle.
- Cảnh báo chính thức: "Be careful not to expose runtime config keys to the client-side by either rendering them or passing them to `useState`."

## Kiểm tra đầu vào của server route

- Dùng các validating reader của h3. KHÔNG tin cậy `readBody` / `getQuery` / `getRouterParam` thuần.
  - `readValidatedBody(event, schema)` validate body.
  - `getValidatedQuery(event, schema)` validate query.
  - `getValidatedRouterParams(event, schema)` validate route param.
- Tất cả đều nhận một hàm validate hoặc Zod schema và throw khi thất bại.

## Rò rỉ payload SSR

- Mọi thứ trong `useState`, kết quả của `useFetch` / `useAsyncData`, hoặc `runtimeConfig.public` đều được serialize vào payload gửi xuống client. KHÔNG BAO GIỜ ghi secret vào các nơi đó.
- Dùng `useServerSeoMeta` cho meta chỉ có ở server mà không tốn chi phí phía client.

## Chuyển tiếp cookie và auth trên SSR

- Nuxt KHÔNG tự động gắn cookie của người dùng đang gửi request vào `$fetch` phía server gửi ra ngoài.
- Chuyển tiếp tường minh bằng `useRequestFetch()` (gọn nhất, đã bind sẵn với header của request) hoặc `useRequestHeaders(['cookie'])`.
- Chuyển tiếp `Set-Cookie` của backend tới trình duyệt qua `$fetch.raw` + `appendResponseHeader(event, 'set-cookie', ...)`.
- socket.io chỉ chạy phía client (plugin `.client.ts`), KHÔNG BAO GIỜ chạy trong SSR.

## SSRF trên $fetch phía server

- Server route chạy với toàn quyền truy cập mạng ra ngoài. KHÔNG BAO GIỜ truyền trực tiếp input do người dùng kiểm soát vào URL hoặc host của `$fetch` phía server.
- Validate tham số trước (các tiện ích h3 ở trên), allowlist đích đến, ghim vào `runtimeConfig.public.apiBase`, từ chối URL tuyệt đối do người dùng cung cấp.
- Chỉ tự động kích hoạt `/security-review` cho các route thực hiện request mạng ra bên ngoài (`$fetch` phía server), xử lý auth token hoặc credential, hoặc thực hiện mutation nhạy cảm hay kiểm tra phân quyền. Ví dụ: endpoint proxy dễ bị SSRF, trao đổi token hoặc đặt lại mật khẩu, thao tác admin. Bỏ qua các route chỉ đọc vô hại chỉ nhận query param đã được validate.

## Tham chiếu

- Skill ECC: `security-review`, `nuxt4-patterns`.
- [Nuxt runtime config](https://nuxt.com/docs/guide/going-further/runtime-config)
- [h3 request utils](https://v1.h3.dev/utils/request)
