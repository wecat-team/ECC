# Chiến lược Loading Route

Angular hỗ trợ hai chiến lược chính để load route và component nhằm cân bằng thời gian tải ban đầu và độ phản hồi khi điều hướng.

## Eager Loading

Component được đóng gói vào payload JavaScript ban đầu và khả dụng ngay lập tức.

```ts
{ path: 'home', component: Home }
```

- **Ưu điểm**: Chuyển trang mượt mà.
- **Nhược điểm**: Làm tăng kích thước bundle ban đầu.

## Lazy Loading

Component hoặc route chỉ được load khi người dùng điều hướng tới chúng. Cách này tạo ra các "chunk" JavaScript riêng biệt.

### Lazy Loading Component

Dùng `loadComponent` để lấy component theo yêu cầu.

```ts
{
  path: 'admin',
  loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent)`,
}
```

### Lazy Loading Route con

Dùng `loadChildren` để lấy một tập route.

```ts
{
  path: 'settings',
  loadChildren: () => import('./settings/settings.routes'),
}
```

## Injection Context và Lazy Loading

Các loader function chạy trong **injection context** của route hiện tại. Điều này cho phép bạn gọi `inject()` để đưa ra quyết định load dựa trên context.

```ts
{
  path: 'dashboard',
  loadComponent: () => {
    const flags = inject(FeatureFlags);
    return flags.isPremium
      ? import('./premium-dashboard')
      : import('./basic-dashboard');
  },
}
```

## Khuyến nghị

- Dùng **Eager Loading** cho các trang landing chính.
- Dùng **Lazy Loading** cho tất cả các khu vực tính năng còn lại để giữ bundle ban đầu nhỏ.
