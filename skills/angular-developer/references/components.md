# Component

Angular component là các khối xây dựng cơ bản của một ứng dụng. Mỗi component gồm một class TypeScript chứa hành vi, một HTML template và một CSS selector.

## Định nghĩa Component

Dùng decorator `@Component` để định nghĩa metadata của component.

```ts
@Component({
  selector: 'app-profile',
  template: `
    <img src="profile.jpg" alt="Profile photo" />
    <button (click)="save()">Save</button>
  `,
  styles: `
    img {
      border-radius: 50%;
    }
  `,
})
export class Profile {
  save() {
    /* ... */
  }
}
```

## Các tùy chọn Metadata

- `selector`: CSS selector xác định component này trong template.
- `template`: HTML template inline (ưu tiên cho template nhỏ).
- `templateUrl`: Đường dẫn tới file HTML bên ngoài.
- `styles`: CSS style inline.
- `styleUrl` / `styleUrls`: Đường dẫn tới (các) file CSS bên ngoài.
- `imports`: Liệt kê các component, directive hoặc pipe được dùng trong template của component này.

## Sử dụng Component

Để dùng một component, hãy thêm nó vào mảng `imports` của component sử dụng và dùng selector của nó trong template.

```ts
@Component({
  selector: 'app-root',
  imports: [Profile],
  template: `<app-profile />`,
})
export class App {}
```

## Template Control Flow

Angular dùng các block tích hợp sẵn cho việc render có điều kiện và vòng lặp.

### Render có điều kiện (`@if`)

Dùng `@if` để hiển thị nội dung có điều kiện. Bạn có thể kèm các block `@else if` và `@else`.

```html
@if (user.isAdmin) {
<admin-dashboard />
} @else if (user.isModerator) {
<mod-dashboard />
} @else {
<standard-dashboard />
}
```

**Đặt alias cho kết quả**: Lưu kết quả của biểu thức để tái sử dụng.

```html
@if (user.settings(); as settings) {
<p>Theme: {{ settings.theme }}</p>
}
```

### Vòng lặp (`@for`)

Block `@for` lặp qua các collection. Biểu thức `track` là **bắt buộc** để đảm bảo hiệu năng và tái sử dụng DOM.

```html
<ul>
  @for (item of items(); track item.id; let i = $index, total = $count) {
  <li>{{ i + 1 }}/{{ total }}: {{ item.name }}</li>
  } @empty {
  <li>No items to display.</li>
  }
</ul>
```

**Biến ngầm định**: `$index`, `$count`, `$first`, `$last`, `$even`, `$odd`.

### Chuyển đổi nội dung (`@switch`)

Block `@switch` render nội dung dựa trên một giá trị. Nó dùng so sánh nghiêm ngặt (`===`) và **không có fallthrough**.

```html
@switch (status()) { @case ('loading') { <app-spinner /> } @case ('error') { <app-error-msg /> }
@case ('success') { <app-data-grid /> } @default {
<p>Unknown status</p>
} }
```

**Kiểm tra type đầy đủ (Exhaustive)**: Dùng `@default never;` để đảm bảo mọi case của một union type đều được xử lý.

```html
@switch (state) { @case ('on') { ... } @case ('off') { ... } @default never; // Errors if a new
state like 'standby' is added }
```

## Khái niệm cốt lõi

- **Host Element**: Phần tử DOM khớp với selector của component.
- **View**: DOM được render bởi template của component bên trong host element.
- **Standalone**: Mặc định, component là standalone (từ Angular 19, `standalone: true` là mặc định). Với các phiên bản cũ hơn, phải khai báo tường minh `standalone: true` hoặc component phải thuộc một `NgModule`.
- **Component Tree**: Ứng dụng Angular được cấu trúc như một cây các component, trong đó mỗi component có thể chứa các component con.
- **Đặt tên Component**: Không thêm hậu tố `Component` cho các class Component (ví dụ: AppComponent) trừ khi dự án đã được cấu hình để dùng quy ước đặt tên đó.
