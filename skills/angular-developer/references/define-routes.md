# Định nghĩa Route

Route là các object định nghĩa component nào sẽ được render cho một đường dẫn URL cụ thể.

## Cấu hình cơ bản

Định nghĩa route trong một mảng `Routes` và cung cấp chúng bằng `provideRouter` trong `appConfig` của bạn.

```ts
// app.routes.ts
export const routes: Routes = [
  {path: '', component: HomePage},
  {path: 'admin', component: AdminPage},
];

// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes)],
};
```

## Đường dẫn URL

- **Static**: Khớp một chuỗi chính xác (ví dụ: `'admin'`).
- **Route Parameter**: Các segment động có tiền tố dấu hai chấm (ví dụ: `'user/:id'`).
- **Wildcard**: Khớp mọi URL bằng `**`. Hữu ích cho các trang "Not Found". **Luôn đặt ở cuối mảng.**

## Chiến lược khớp

Angular dùng chiến lược **khớp đầu tiên thắng (first-match wins)**. Các route cụ thể phải đứng trước các route ít cụ thể hơn.

## Redirect

Dùng `redirectTo` để trỏ một path sang path khác.

```ts
{ path: 'articles', redirectTo: '/blog' },
{ path: 'blog', component: Blog },
```

## Tiêu đề trang

Gắn tiêu đề với route để hỗ trợ accessibility. Tiêu đề có thể tĩnh hoặc động (qua `ResolveFn` hoặc một `TitleStrategy` tùy chỉnh).

```ts
{ path: 'home', component: Home, title: 'Home Page' }
```

## Route Data và Provider

- **Dữ liệu tĩnh**: Gắn metadata bằng thuộc tính `data`.
- **Route Provider**: Giới hạn phạm vi dependency vào một route cụ thể và các route con của nó bằng mảng `providers`.

## Route lồng nhau (Con)

Định nghĩa các sub-view bằng thuộc tính `children`. Component cha phải có `<router-outlet />`.

```ts
{
  path: 'product/:id',
  component: Product,
  children: [
    { path: 'info', component: ProductInfo },
    { path: 'reviews', component: ProductReviews },
  ],
}
```
