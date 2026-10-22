# Vòng đời và Event của Router

Angular Router phát ra các event thông qua observable `Router.events`, cho phép bạn theo dõi vòng đời điều hướng từ đầu đến cuối.

## Các Router Event phổ biến (Theo thứ tự thời gian)

1. **`NavigationStart`**: Điều hướng bắt đầu.
2. **`RoutesRecognized`**: Router khớp URL với một route.
3. **`GuardsCheckStart` / `End`**: Đánh giá `canActivate`, `canMatch`, v.v.
4. **`ResolveStart` / `End`**: Pha resolve dữ liệu (lấy dữ liệu qua resolver).
5. **`NavigationEnd`**: Điều hướng hoàn tất thành công.
6. **`NavigationCancel`**: Điều hướng bị hủy (ví dụ: guard trả về `false`).
7. **`NavigationError`**: Điều hướng thất bại (ví dụ: lỗi trong resolver).

## Subscribe vào Event

Inject `Router` và lọc observable `events`.

```ts
import {Router, NavigationStart, NavigationEnd} from '@angular/router';

export class MyService {
  private router = inject(Router);

  constructor() {
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)).subscribe((event) => {
      console.log('Navigated to:', event.url);
    });
  }
}
```

## Debug

Bật log chi tiết trên console cho mọi routing event trong quá trình bootstrap ứng dụng.

```ts
provideRouter(routes, withDebugTracing());
```

## Các trường hợp dùng phổ biến

- **Loading Indicator**: Hiển thị spinner khi `NavigationStart` được phát và ẩn nó khi `NavigationEnd`/`Cancel`/`Error`.
- **Analytics**: Theo dõi lượt xem trang bằng cách lắng nghe `NavigationEnd`.
- **Quản lý Scroll**: Phản hồi các event `Scroll` để có hành vi cuộn tùy chỉnh.
