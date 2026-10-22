# Data Resolver

Data resolver lấy dữ liệu trước khi một route được kích hoạt, đảm bảo component có đủ dữ liệu cần thiết khi render.

## Tạo một Resolver

Triển khai type `ResolveFn`.

```ts
export const userResolver: ResolveFn<User> = (route, state) => {
  const userService = inject(UserService);
  const id = route.paramMap.get('id')!;
  return userService.getUser(id);
};
```

## Cấu hình Route

Thêm resolver vào key `resolve`.

```ts
{
  path: 'user/:id',
  component: UserProfile,
  resolve: {
    user: userResolver
  }
}
```

## Truy cập dữ liệu đã resolve

### 1. Qua `ActivatedRoute` (Truyền thống)

```ts
private route = inject(ActivatedRoute);
data = toSignal(this.route.data);
user = computed(() => this.data().user);
```

### 2. Qua Component Input (Hiện đại)

Bật `withComponentInputBinding()` trong `provideRouter` để truyền dữ liệu đã resolve trực tiếp vào `@Input` hoặc `input()`.

```ts
// app.config.ts
provideRouter(routes, withComponentInputBinding());

// component.ts
user = input.required<User>();
```

## Xử lý lỗi

Điều hướng (navigation) bị chặn nếu resolver thất bại.

- Dùng `withNavigationErrorHandler` để xử lý toàn cục.
- Dùng `catchError` trong resolver để trả về một `RedirectCommand` hoặc dữ liệu dự phòng.

```ts
return userService
  .get(id)
  .pipe(catchError(() => of(new RedirectCommand(router.parseUrl('/error')))));
```

## Best Practice

- **Giữ nhẹ**: Chỉ lấy dữ liệu quan trọng.
- **Phản hồi cho người dùng**: Lắng nghe các router event để hiển thị thanh loading toàn cục trong quá trình điều hướng, vì UI vẫn ở trang cũ cho đến khi resolver hoàn tất.
