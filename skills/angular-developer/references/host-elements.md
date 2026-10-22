# Host Element của Component

**Host element** là phần tử DOM khớp với selector của component. Template của component được render bên trong phần tử này.

## Binding vào Host Element

Dùng thuộc tính `host` trong decorator `@Component` để bind property, attribute, style và event vào host element. Đây là **cách được ưu tiên** so với các decorator cũ (legacy).

```ts
@Component({
  selector: 'custom-slider',
  host: {
    'role': 'slider', // Static attribute
    '[attr.aria-valuenow]': 'value', // Attribute binding
    '[class.active]': 'isActive()', // Class binding
    '[style.color]': 'color()', // Style binding
    '[tabIndex]': 'disabled ? -1 : 0', // Property binding
    '(keydown)': 'onKeyDown($event)', // Event binding
  },
})
export class CustomSlider {
  value = 0;
  disabled = false;
  isActive = signal(false);
  color = signal('blue');

  onKeyDown(event: KeyboardEvent) {
    /* ... */
  }
}
```

## Decorator cũ (Legacy)

`@HostBinding` và `@HostListener` vẫn được hỗ trợ để tương thích ngược nhưng nên tránh trong code mới.

```ts
export class CustomSlider {
  @HostBinding('tabIndex')
  get tabIndex() {
    return this.disabled ? -1 : 0;
  }

  @HostListener('keydown', ['$event'])
  onKeyDown(event: KeyboardEvent) {
    /* ... */
  }
}
```

## Xung đột Binding

Nếu cả component (host binding) và bên sử dụng (template binding) cùng bind vào một property:

1. **Static so với Static**: Binding của instance (bên sử dụng) thắng.
2. **Static so với Dynamic**: Binding động thắng.
3. **Dynamic so với Dynamic**: Host binding của component thắng.

## Inject Host Attribute

Dùng `HostAttributeToken` với hàm `inject` để đọc các attribute tĩnh từ host element tại thời điểm khởi tạo.

```ts
import {Component, HostAttributeToken, inject} from '@angular/core';

@Component({
  selector: 'app-btn',
  template: `<ng-content />`,
})
export class AppButton {
  // Throws error if 'type' is missing unless injected with { optional: true }
  type = inject(new HostAttributeToken('type'));
}
```

Cách dùng:

```html
<app-btn type="primary">Click Me</app-btn>
```
