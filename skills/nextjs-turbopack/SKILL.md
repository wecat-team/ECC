---
name: nextjs-turbopack
description: Hướng dẫn Next.js 16+ và Turbopack — bundling tăng dần bằng Rust, file-system caching, dev startup và HMR nhanh hơn, đánh đổi giữa Turbopack và webpack, và việc đổi tên file middleware.ts thành proxy.ts. Dùng khi phát triển hoặc debug app Next.js 16+, chẩn đoán dev startup hoặc hot reload chậm, chọn giữa các bundler, hoặc review cách đặt tên file middleware/proxy.
metadata:
  origin: ECC
---

# Next.js và Turbopack

Next.js 16+ dùng Turbopack theo mặc định cho phát triển local: một bundler tăng dần (incremental) viết bằng Rust, giúp tăng tốc đáng kể dev startup và hot update.

## Khi nào dùng

- **Turbopack (dev mặc định)**: Dùng cho phát triển hằng ngày. Cold start và HMR nhanh hơn, đặc biệt trong các app lớn.
- **Webpack (dev legacy)**: Chỉ dùng nếu bạn gặp bug của Turbopack hoặc phụ thuộc vào plugin chỉ có ở webpack trong dev. Tắt bằng `--webpack` (hoặc `--no-turbopack` tùy phiên bản Next.js; hãy xem tài liệu cho bản phát hành của bạn).
- **Production**: Hành vi production build (`next build`) có thể dùng Turbopack hoặc webpack tùy phiên bản Next.js; hãy xem tài liệu chính thức của Next.js cho phiên bản của bạn.

Dùng khi: phát triển hoặc debug app Next.js 16+, chẩn đoán dev startup hoặc HMR chậm, hoặc tối ưu production bundle.

## Cách hoạt động

- **Turbopack**: Bundler tăng dần cho Next.js dev. Dùng file-system caching nên restart nhanh hơn nhiều (ví dụ 5–14 lần trên các dự án lớn).
- **Mặc định trong dev**: Từ Next.js 16, `next dev` chạy với Turbopack trừ khi bị tắt.
- **File-system caching**: Các lần restart tái sử dụng công việc trước đó; cache thường nằm dưới `.next`; không cần cấu hình thêm cho việc sử dụng cơ bản.
- **Bundle Analyzer (Next.js 16.1+)**: Bundle Analyzer thử nghiệm để kiểm tra output và tìm các dependency nặng; bật qua config hoặc cờ experimental (xem tài liệu Next.js cho phiên bản của bạn).

## Ví dụ

### Lệnh

```bash
next dev
next build
next start
```

### Cách dùng

Chạy `next dev` để phát triển local với Turbopack. Dùng Bundle Analyzer (xem tài liệu Next.js) để tối ưu code-splitting và cắt bớt các dependency lớn. Ưu tiên App Router và server component khi có thể.

## Đặt tên file Middleware

Next.js 16 giới thiệu `proxy.ts` làm tên file middleware, thay thế quy ước `middleware.ts` cũ:

- **Next.js 16+**: dùng `proxy.ts` ở root dự án
- **Trước Next.js 16**: dùng `middleware.ts` ở root dự án

Việc đổi tên file gắn với **phiên bản Next.js**, không phải với bundler nào (Turbopack hay webpack) đang được dùng. Luôn xem tài liệu chính thức cho phiên bản bạn đang review.

**Không đánh dấu `proxy.ts` là file middleware đặt sai tên hoặc bị thiếu trong các dự án Next.js 16.** File đó là đúng và có chủ đích. Đề xuất đổi tên thành `middleware.ts` sẽ làm hỏng việc thực thi middleware.

Tham khảo: [Next.js proxy docs](https://nextjs.org/docs/app/getting-started/proxy)

## Best Practice

- Dùng một bản Next.js 16.x gần đây để có hành vi Turbopack và caching ổn định.
- Nếu dev chậm, hãy đảm bảo bạn đang dùng Turbopack (mặc định) và cache không bị xóa một cách không cần thiết.
- Với các vấn đề kích thước production bundle, hãy dùng công cụ phân tích bundle chính thức của Next.js cho phiên bản của bạn.
