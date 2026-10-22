# Angular Animations

Khi tạo animation cho các phần tử trong Angular, **trước tiên hãy phân tích phiên bản Angular của dự án** trong `package.json`.
Với các ứng dụng hiện đại (**Angular v20.2 trở lên**), ưu tiên dùng CSS native với `animate.enter` và `animate.leave`. Với các ứng dụng cũ hơn, bạn có thể phải dùng package `@angular/animations` đã bị deprecated.

## 1. Native CSS Animations (khuyến nghị cho v20.2+)

Angular hiện đại cung cấp `animate.enter` và `animate.leave` để tạo animation cho phần tử khi chúng vào hoặc rời khỏi DOM. Chúng áp dụng các CSS class vào đúng thời điểm.

### `animate.enter` and `animate.leave`

Dùng trực tiếp chúng trên phần tử để áp dụng CSS class trong pha enter hoặc leave. Angular tự động gỡ các class enter khi animation hoàn tất. Với `animate.leave`, Angular chờ animation kết thúc rồi mới gỡ phần tử khỏi DOM.

Ví dụ `animate.enter`:

```html
@if (isShown()) {
<div class="enter-container" animate.enter="enter-animation">
  <p>The box is entering.</p>
</div>
}
```

```css
/* Ensure you have a starting style if using transitions instead of keyframes */
.enter-container {
  border: 1px solid #dddddd;
  margin-top: 1em;
  padding: 20px;
  font-weight: bold;
  font-size: 20px;
}
.enter-container p {
  margin: 0;
}
.enter-animation {
  animation: slide-fade 1s;
}
@keyframes slide-fade {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

_Lưu ý: `animate.leave` có thể được thêm vào các phần tử con đang bị gỡ._

### Event Binding và thư viện bên thứ ba

Bạn có thể bind tới `(animate.enter)` và `(animate.leave)` để gọi hàm hoặc dùng các thư viện JS như GSAP.

```html
@if(show()) {
<div (animate.leave)="onLeave($event)">...</div>
}
```

```ts
import { AnimationCallbackEvent } from '@angular/core';

onLeave(event: AnimationCallbackEvent) {
  // Logic animation tùy chỉnh đặt ở đây
  // CRITICAL: PHẢI gọi animationComplete() khi xong để Angular gỡ phần tử!
  event.animationComplete();
}
```

## 2. CSS Animation nâng cao

CSS cung cấp các công cụ mạnh mẽ cho các chuỗi animation nâng cao.

### Animate State và Style

Bật/tắt CSS class trên phần tử bằng property binding để kích hoạt transition.

```html
<div [class.open]="isOpen">...</div>
```

```css
div {
  transition: height 0.3s ease-out;
  height: 100px;
}
div.open {
  height: 200px;
}
```

### Animate tới Auto Height

Bạn có thể dùng `css-grid` để animate tới chiều cao auto.

```css
.container {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 0.3s;
}
.container.open {
  grid-template-rows: 1fr;
}
.container > div {
  overflow: hidden;
}
```

### Animation so le (Staggering) và song song

- **Staggering**: Dùng `animation-delay` hoặc `transition-delay` với các giá trị khác nhau cho các mục trong danh sách.
- **Song song (Parallel)**: Áp dụng nhiều animation trong shorthand `animation` (ví dụ `animation: rotate 3s, fade-in 2s;`).

### Điều khiển bằng code (Programmatic Control)

Lấy các animation trực tiếp bằng Web API chuẩn:

```ts
const animations = element.getAnimations();
animations.forEach((anim) => anim.pause());
```

## 3. Legacy Animations DSL (Deprecated)

Với các dự án cũ hơn (trước v20.2 hoặc nơi `@angular/animations` đã được dùng nhiều), bạn dùng DSL trong metadata của component.

**Quan trọng:** Không trộn legacy animation và `animate.enter`/`leave` trong cùng một component.

### Thiết lập

```ts
bootstrapApplication(App, {
  providers: [provideAnimationsAsync()],
});
```

### Định nghĩa Transition

```ts
import {signal} from '@angular/core';
import {trigger, state, style, animate, transition} from '@angular/animations';

@Component({
  animations: [
    trigger('openClose', [
      state('open', style({opacity: 1})),
      state('closed', style({opacity: 0})),
      transition('open <=> closed', [animate('0.5s')]),
    ]),
  ],
  template: `<div [@openClose]="isOpen() ? 'open' : 'closed'">...</div>`,
})
export class OpenClose {
  isOpen = signal(true);
}
```
