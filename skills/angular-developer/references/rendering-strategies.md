# Chiến lược Rendering

Angular hỗ trợ nhiều chiến lược rendering để tối ưu cho SEO, hiệu năng và tính tương tác.

## 1. Client-Side Rendering (CSR)

**Chiến lược mặc định.** Nội dung được render hoàn toàn trong trình duyệt.

- **Trường hợp dùng**: Dashboard tương tác, công cụ nội bộ.
- **Ưu điểm**: Dễ cấu hình nhất, chi phí server thấp.
- **Nhược điểm**: SEO kém, nội dung ban đầu hiển thị chậm hơn (phải chờ JS).

## 2. Static Site Generation (SSG / Prerendering)

Nội dung được pre-render thành các file HTML tĩnh tại **thời điểm build**.

- **Trường hợp dùng**: Trang marketing, blog, tài liệu.
- **Ưu điểm**: Tải ban đầu nhanh nhất, SEO tuyệt vời, thân thiện với CDN.
- **Nhược điểm**: Cần build lại khi cập nhật nội dung, không phù hợp với dữ liệu theo từng người dùng.

## 3. Server-Side Rendering (SSR)

Nội dung được render trên server cho **request đầu tiên**. Các lần điều hướng tiếp theo diễn ra ở phía client (kiểu SPA).

- **Trường hợp dùng**: Trang sản phẩm thương mại điện tử, trang tin tức, nội dung động được cá nhân hóa.
- **Ưu điểm**: SEO tuyệt vời, nội dung ban đầu hiển thị nhanh.
- **Nhược điểm**: Cần một server (Node.js), chi phí/độ trễ server cao hơn.

## Hydration

Hydration là quá trình làm cho HTML được render từ server trở nên tương tác được trong trình duyệt.

- **Full Hydration**: Toàn bộ ứng dụng trở nên tương tác cùng một lúc.
- **Incremental Hydration**: (Nâng cao) Từng phần trở nên tương tác khi cần bằng các block `@defer`.
- **Event Replay**: Ghi lại và phát lại các event của người dùng xảy ra trước khi hydration hoàn tất.

## Ma trận quyết định

| Yêu cầu                         | Chiến lược           |
| :------------------------------ | :------------------- |
| **SEO + Nội dung tĩnh**         | SSG                  |
| **SEO + Nội dung động**         | SSR                  |
| **Không SEO + Tương tác cao**   | CSR                  |
| **Hỗn hợp**                     | Hybrid (theo route)  |
