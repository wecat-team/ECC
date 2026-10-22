# Hiển thị Route với Outlet

Directive `RouterOutlet` là một placeholder nơi Angular render component cho URL hiện tại.

## Cách dùng cơ bản

Đặt `<router-outlet />` trong template của bạn. Angular chèn routed component như một phần tử anh em (sibling) ngay sau outlet.

```html
<app-header /> <router-outlet />
<!-- Route content appears here -->
<app-footer />
```

## Outlet lồng nhau

Route con cần `<router-outlet />` riêng trong template của component cha.

```ts
// Parent component template
<h1>Settings</h1>
<router-outlet /> <!-- Child components like Profile or Security render here -->
```

## Named Outlet (Secondary Route)

Trang có thể có nhiều outlet. Gán một `name` cho outlet để nhắm tới nó cụ thể. Tên mặc định là `'primary'`.

```html
<router-outlet />
<!-- Primary -->
<router-outlet name="sidebar" />
<!-- Secondary -->
```

Định nghĩa `outlet` trong cấu hình route:

```ts
{
  path: 'chat',
  component: Chat,
  outlet: 'sidebar'
}
```

## Outlet Lifecycle Event

`RouterOutlet` phát event khi component thay đổi:

- `activate`: Component mới được khởi tạo.
- `deactivate`: Component bị hủy.
- `attach` / `detach`: Dùng với `RouteReuseStrategy`.

```html
<router-outlet (activate)="onActivate($event)" />
```

## Truyền dữ liệu qua `routerOutletData`

Bạn có thể truyền dữ liệu ngữ cảnh cho routed component bằng input `routerOutletData`. Component truy cập dữ liệu này qua injection token `ROUTER_OUTLET_DATA` dưới dạng signal.

```ts
// In Parent
<router-outlet [routerOutletData]="{ theme: 'dark' }" />

// In Routed Component
outletData = inject(ROUTER_OUTLET_DATA) as Signal<{ theme: string }>;
```
