# Animation chuyển Route

Angular Router hỗ trợ **View Transitions API** của trình duyệt để tạo các chuyển đổi hình ảnh mượt mà giữa các route.

## Bật View Transitions

Thêm `withViewTransitions()` vào cấu hình router của bạn.

```ts
provideRouter(routes, withViewTransitions());
```

Đây là một **progressive enhancement** (cải tiến dần). Trên các trình duyệt không hỗ trợ API này, router vẫn hoạt động nhưng không có animation chuyển đổi.

## Cách hoạt động

1. Trình duyệt chụp ảnh màn hình của trạng thái cũ.
2. Router cập nhật DOM (kích hoạt component mới).
3. Trình duyệt chụp ảnh màn hình của trạng thái mới.
4. Trình duyệt tạo animation giữa hai trạng thái.

## Tùy biến bằng CSS

Các chuyển đổi được tùy biến trong **file CSS toàn cục** (không phải CSS giới hạn trong component).

Dùng các pseudo-element `::view-transition-old()` và `::view-transition-new()`.

```css
/* Example: Cross-fade + Slide */
::view-transition-old(root) {
  animation: 90ms cubic-bezier(0.4, 0, 1, 1) both fade-out;
}
::view-transition-new(root) {
  animation: 210ms cubic-bezier(0, 0, 0.2, 1) 90ms both fade-in;
}
```

## Kiểm soát nâng cao

Dùng `onViewTransitionCreated` để bỏ qua chuyển đổi hoặc tùy biến hành vi dựa trên ngữ cảnh điều hướng.

```ts
withViewTransitions({
  onViewTransitionCreated: ({transition, from, to}) => {
    // Skip animation for specific routes
    if (to.url === '/no-animation') {
      transition.skipTransition();
    }
  },
});
```

## Best Practice

- **Style toàn cục**: Luôn định nghĩa animation chuyển đổi trong `styles.css` để tránh các vấn đề về view encapsulation.
- **View Transition Name**: Gán `view-transition-name` duy nhất cho các phần tử cần chuyển đổi mượt mà giữa các route (ví dụ: ảnh header).
