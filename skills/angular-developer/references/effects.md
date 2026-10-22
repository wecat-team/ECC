# Side Effect với `effect` và `afterRenderEffect`

Trong Angular, **effect** là một thao tác chạy mỗi khi một hoặc nhiều giá trị signal mà nó theo dõi thay đổi.

## Khi nào dùng `effect`

Effect được thiết kế để đồng bộ state của signal sang các API mệnh lệnh (imperative), không dựa trên signal.

**Các trường hợp dùng hợp lệ:**

- Ghi log analytics.
- Đồng bộ state vào `localStorage` hoặc `sessionStorage`.
- Thực hiện render tùy chỉnh lên `<canvas>` hoặc thư viện vẽ biểu đồ của bên thứ ba.

**QUY TẮC QUAN TRỌNG: KHÔNG dùng effect để lan truyền state.**
Nếu bạn thấy mình dùng `.set()` hoặc `.update()` trên một signal _bên trong_ một effect để giữ hai signal đồng bộ, bạn đang mắc lỗi. Điều này gây ra lỗi `ExpressionChangedAfterItHasBeenChecked` và vòng lặp vô hạn. **Luôn dùng `computed()` hoặc `linkedSignal()` để dẫn xuất state.**

## Cách dùng cơ bản

Effect thực thi bất đồng bộ trong quá trình change detection. Chúng luôn chạy ít nhất một lần.

```ts
import { Component, signal, effect } from '@angular/core';

@Component({...})
export class Example {
  count = signal(0);

  constructor() {
    // Effect must be created in an injection context (e.g., a constructor)
    effect((onCleanup) => {
      console.log(`Count changed to ${this.count()}`);

      const timer = setTimeout(() => console.log('Timer finished'), 1000);

      // Cleanup function runs before the next execution, or when destroyed
      onCleanup(() => clearTimeout(timer));
    });
  }
}
```

## Thao tác DOM với `afterRenderEffect`

`effect` tiêu chuẩn chạy _trước_ khi Angular cập nhật DOM. Nếu bạn cần kiểm tra hoặc sửa DOM thủ công dựa trên thay đổi của signal (ví dụ: tích hợp thư viện UI của bên thứ ba), hãy dùng `afterRenderEffect`.

`afterRenderEffect` chạy sau khi Angular đã render xong DOM.

### Các pha Render

Để tránh reflow (forced layout thrashing), `afterRenderEffect` buộc bạn chia các thao tác đọc và ghi DOM thành các pha cụ thể.

```ts
import { Component, afterRenderEffect, viewChild, ElementRef } from '@angular/core';

@Component({...})
export class Chart {
  canvas = viewChild.required<ElementRef>('canvas');

  constructor() {
    afterRenderEffect({
      // 1. Read from the DOM
      earlyRead: () => {
        return this.canvas().nativeElement.getBoundingClientRect().width;
      },
      // 2. Write to the DOM (receives the result of the previous phase)
      write: (width) => {
        // NEVER read from the DOM in the write phase.
        setupChart(this.canvas().nativeElement, width);
      }
    });
  }
}
```

**Các pha khả dụng (thực thi theo thứ tự này):**

1. `earlyRead`
2. `write` (Không bao giờ đọc ở đây)
3. `mixedReadWrite` (Tránh nếu có thể)
4. `read` (Không bao giờ ghi ở đây)

_Lưu ý: `afterRenderEffect` chỉ chạy ở phía client, không bao giờ chạy trong Server-Side Rendering (SSR)._
