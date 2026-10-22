# State phụ thuộc với `linkedSignal`

Hàm `linkedSignal` cho phép bạn tạo state ghi được (writable) gắn liền với một state khác. Nó rất phù hợp cho state cần giá trị mặc định dẫn xuất từ một input hoặc signal khác, nhưng vẫn có thể được người dùng chỉnh sửa độc lập.

Nếu state nguồn thay đổi, `linkedSignal` được đặt lại về một giá trị mới được tính toán.

## Cách dùng cơ bản

Khi bạn chỉ cần tính lại dựa trên một nguồn, hãy truyền vào một hàm tính toán. `linkedSignal` hoạt động như `computed`, nhưng signal kết quả là writable (bạn có thể gọi `.set()` hoặc `.update()` trên nó).

```ts
import { Component, signal, linkedSignal } from '@angular/core';

@Component({...})
export class ShippingMethodPicker {
  shippingOptions = signal(['Ground', 'Air', 'Sea']);

  // Defaults to the first option.
  // If shippingOptions changes, selectedOption resets to the new first option.
  selectedOption = linkedSignal(() => this.shippingOptions()[0]);

  changeShipping(index: number) {
    // We can still manually update this signal!
    this.selectedOption.set(this.shippingOptions()[index]);
  }
}
```

## Cách dùng nâng cao: Xét đến state trước đó

Đôi khi, khi state nguồn thay đổi, bạn muốn giữ lại lựa chọn thủ công của người dùng nếu nó vẫn còn hợp lệ. Để làm vậy, hãy dùng cú pháp object với `source` và `computation`.

Hàm `computation` nhận giá trị mới của nguồn, và một object `previous` chứa giá trị nguồn trước đó cùng giá trị `linkedSignal` trước đó.

```ts
interface ShippingMethod { id: number; name: string; }

@Component({...})
export class ShippingMethodPicker {
  shippingOptions = signal<ShippingMethod[]>([
    {id: 0, name: 'Ground'}, {id: 1, name: 'Air'}, {id: 2, name: 'Sea'}
  ]);

  selectedOption = linkedSignal<ShippingMethod[], ShippingMethod>({
    source: this.shippingOptions,
    computation: (newOptions, previous) => {
      // If the newly loaded options still contain the user's previously
      // selected option, keep it selected. Otherwise, reset to the first option.
      return newOptions.find(opt => opt.id === previous?.value.id) ?? newOptions[0];
    }
  });
}
```

### Khi nào dùng `linkedSignal` so với `computed` so với `effect`

- Dùng `computed`: Khi state được dẫn xuất **hoàn toàn** từ state khác và không bao giờ nên được cập nhật thủ công.
- Dùng `linkedSignal`: Khi state được dẫn xuất từ state khác, nhưng người dùng **phải** có thể ghi đè hoặc cập nhật thủ công.
- **KHÔNG BAO GIỜ** dùng `effect` để đồng bộ một state sang state khác. Đó là anti-pattern. Hãy dùng `computed` hoặc `linkedSignal`.
