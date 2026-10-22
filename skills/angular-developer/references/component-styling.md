# Styling cho Component

Angular component có thể định nghĩa các style áp dụng riêng cho template của nó, cho phép đóng gói (encapsulation) và module hóa.

## Định nghĩa Style

Style có thể được định nghĩa inline hoặc trong file riêng.

```ts
@Component({
  selector: 'app-photo',
  // Inline styles
  styles: `
    img {
      border-radius: 50%;
    }
  `,
  // OR external file
  styleUrl: 'photo.component.css',
})
export class Photo {}
```

## View Encapsulation

Mỗi component có một thiết lập view encapsulation quyết định cách style được giới hạn phạm vi (scope).

| Chế độ                          | Hành vi                                                                                                   |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------- |
| `Emulated` (Mặc định)           | Giới hạn style trong component bằng các thuộc tính HTML duy nhất. Style toàn cục vẫn có thể lọt vào.      |
| `ShadowDom`                     | Dùng Shadow DOM API gốc của trình duyệt để cô lập style hoàn toàn.                                        |
| `None`                          | Tắt encapsulation. Style của component trở thành toàn cục.                                                |
| `ExperimentalIsolatedShadowDom` | Đảm bảo nghiêm ngặt rằng chỉ có style của component được áp dụng.                                         |

### Cách dùng

```ts
import { ViewEncapsulation } from '@angular/core';

@Component({
  ...,
  encapsulation: ViewEncapsulation.None,
})
export class GlobalStyled {}
```

## Selector đặc biệt

### `:host`

Nhắm tới host element của component (phần tử khớp với selector của component).

```css
:host {
  display: block;
  border: 1px solid black;
}
```

### `:host-context()`

Nhắm tới host element dựa trên một điều kiện nào đó trong chuỗi tổ tiên của nó.

```css
/* Apply styles if any ancestor has the 'theme-dark' class */
:host-context(.theme-dark) {
  background-color: #333;
}
```

### `::ng-deep`

Tắt view encapsulation cho một rule cụ thể, cho phép nó "lọt" vào các component con.
**Lưu ý: Đội ngũ Angular rất không khuyến khích dùng `::ng-deep`.** Nó chỉ được hỗ trợ để tương thích ngược.

## Style trong Template

Bạn có thể dùng trực tiếp các phần tử `<style>` trong template của component. Các quy tắc view encapsulation vẫn được áp dụng.

```html
<style>
  .dynamic-class {
    color: red;
  }
</style>
<div class="dynamic-class">Hello</div>
```

## Style bên ngoài

Việc dùng `<link>` hoặc `@import` trong CSS được coi là style bên ngoài. **Style bên ngoài không bị ảnh hưởng bởi emulated view encapsulation.**
