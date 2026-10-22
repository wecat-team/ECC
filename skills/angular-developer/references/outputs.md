# Output (Custom Event)

Output cho phép component con phát (emit) các custom event mà component cha có thể lắng nghe. Angular khuyến nghị dùng hàm `output()` mới cho các ứng dụng hiện đại.

## Output dựa trên hàm

Khai báo output bằng hàm `output()`. Hàm này trả về một `OutputEmitterRef`.

```ts
import {Component, output} from '@angular/core';

@Component({
  selector: 'custom-slider',
  template: `<button (click)="changeValue(50)">Set to 50</button>`,
})
export class CustomSlider {
  // Output without event data
  panelClosed = output<void>();

  // Output with event data (number)
  valueChanged = output<number>();

  changeValue(newValue: number) {
    this.valueChanged.emit(newValue);
  }
}
```

### Cách dùng trong Template

Bind vào output event bằng dấu ngoặc đơn `()`. Nếu event phát ra dữ liệu, truy cập nó bằng biến đặc biệt `$event`.

```html
<custom-slider (panelClosed)="savePanelState()" (valueChanged)="logValue($event)" />
```

## Các tùy chọn cấu hình

Hàm `output` nhận một object cấu hình để chỉ định alias.

```ts
@Component({...})
export class CustomSlider {
  // The event is named 'valueChanged' in the template,
  // but accessed as 'changed' in the component class.
  changed = output<number>({ alias: 'valueChanged' });
}
```

## Subscribe bằng lập trình

Khi tạo component động, bạn có thể subscribe vào output bằng code:

```ts
const componentRef = viewContainerRef.createComponent(CustomSlider);

const subscription = componentRef.instance.valueChanged.subscribe((val) => {
  console.log('Value changed:', val);
});

// Clean up manually if needed (Angular cleans up destroyed components automatically)
subscription.unsubscribe();
```

## Output dựa trên Decorator (@Output)

API cũ (legacy) dùng decorator `@Output()` với `EventEmitter`. Nó vẫn được hỗ trợ nhưng không được khuyến nghị cho code mới.

```ts
import { Component, Output, EventEmitter } from '@angular/core';

@Component({...})
export class LegacyExample {
  @Output() valueChanged = new EventEmitter<number>();

  // With alias
  @Output('customEventName') changed = new EventEmitter<void>();
}
```

## Best Practice

- **Ưu tiên `output()`**: Dùng `output()` dựa trên hàm thay vì `@Output()` và `EventEmitter`.
- **Đặt tên**: Dùng `camelCase` cho tên output. Tránh thêm tiền tố `on` (ví dụ: dùng `valueChanged` thay vì `onValueChanged`).
- **Không bubble qua DOM**: Custom event của Angular không bubble lên cây DOM như các event gốc.
- **Tránh xung đột**: Không chọn tên trùng với các DOM event gốc (như `click` hoặc `submit`).
