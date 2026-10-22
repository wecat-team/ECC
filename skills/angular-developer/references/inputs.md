# Input

Input cho phép dữ liệu chảy từ component cha sang component con. Angular khuyến nghị dùng API `input` dựa trên signal cho các ứng dụng hiện đại.

## Input dựa trên Signal

Khai báo input bằng hàm `input()`. Hàm này trả về một `InputSignal`.

```ts
import {Component, input, computed} from '@angular/core';

@Component({
  selector: 'app-user',
  template: `<p>User: {{ name() }} ({{ age() }})</p>`,
})
export class User {
  // Optional input with default value
  name = input('Guest');

  // Required input
  age = input.required<number>();

  // Inputs are reactive signals
  label = computed(() => `Name: ${this.name()}`);
}
```

### Cách dùng trong Template

```html
<app-user [name]="userName" [age]="25" />
```

## Các tùy chọn cấu hình

Hàm `input` nhận một object cấu hình:

- **Alias**: Đổi tên property dùng trong template.
- **Transform**: Biến đổi giá trị trước khi nó tới component.

```ts
import { input, booleanAttribute } from '@angular/core';

@Component({...})
export class CustomButton {
  // Alias example
  label = input('', { alias: 'btnLabel' });

  // Transform example using built-in helper
  disabled = input(false, { transform: booleanAttribute });
}
```

## Model Input (Two-Way Binding)

Dùng `model()` để tạo một input hỗ trợ two-way data binding.

```ts
@Component({
  selector: 'custom-counter',
  template: `<button (click)="increment()">+</button>`,
})
export class CustomCounter {
  value = model(0);

  increment() {
    this.value.update((v) => v + 1);
  }
}
```

### Cách dùng

```html
<!-- Two-way binding with a signal -->
<custom-counter [(value)]="mySignal" />

<!-- Two-way binding with a plain property -->
<custom-counter [(value)]="myProperty" />
```

## Input dựa trên Decorator (@Input)

API cũ (legacy) vẫn được hỗ trợ nhưng không được khuyến nghị cho code mới.

```ts
import { Component, Input } from '@angular/core';

@Component({...})
export class Legacy {
  @Input({ required: true }) value = 0;
  @Input({ transform: trimString }) label = '';
}
```

## Best Practice

- **Ưu tiên Signal**: Dùng `input()` thay vì `@Input()` để có khả năng reactive tốt hơn và type safety.
- **Input bắt buộc**: Dùng `input.required()` cho dữ liệu bắt buộc để nhận lỗi ngay lúc build.
- **Transform thuần túy**: Đảm bảo các hàm transform của input là pure và có thể phân tích tĩnh.
- **Tránh xung đột**: Không dùng tên input trùng với các DOM property chuẩn (ví dụ: `id`, `title`).
