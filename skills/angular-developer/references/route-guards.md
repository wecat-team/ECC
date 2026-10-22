# Route Guard

Route guard kiểm soát việc người dùng có thể điều hướng tới hoặc rời khỏi một route hay không.

## Các loại Guard

- **`CanActivate`**: Người dùng có được truy cập route này không? (ví dụ: kiểm tra xác thực).
- **`CanActivateChild`**: Người dùng có được truy cập các route con của route này không?
- **`CanDeactivate`**: Người dùng có được rời khỏi route này không? (ví dụ: có thay đổi chưa lưu).
- **`CanMatch`**: Route này có nên được xem xét để khớp hay không? (ví dụ: feature flag). Nếu trả về `false`, router tiếp tục kiểm tra các route khác.

## Tạo một Guard

Guard thường ở dạng functional kể từ Angular 15.

```ts
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isLoggedIn()) {
    return true;
  }

  // Redirect to login
  return router.parseUrl('/login');
};
```

## Áp dụng Guard

Thêm chúng vào cấu hình route dưới dạng mảng. Chúng thực thi theo thứ tự.

```ts
{
  path: 'admin',
  component: Admin,
  canActivate: [authGuard],
  canActivateChild: [adminChildGuard],
  canDeactivate: [unsavedChangesGuard]
}
```

## Giá trị trả về

- `boolean`: `true` để cho phép, `false` để chặn.
- `UrlTree` hoặc `RedirectCommand`: Chuyển hướng sang một route khác.
- `Observable` hoặc `Promise`: Resolve ra các type ở trên.

## Lưu ý bảo mật

**Guard phía client KHÔNG thay thế được bảo mật phía server.** Luôn kiểm tra quyền trên server.
