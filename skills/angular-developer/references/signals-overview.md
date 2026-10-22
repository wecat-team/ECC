# Tổng quan về Angular Signal

Signal là nền tảng của reactivity trong các ứng dụng Angular hiện đại. **Signal** là một wrapper bao quanh một giá trị, thông báo cho các consumer quan tâm khi giá trị đó thay đổi.

## Writable Signal (`signal`)

Dùng `signal()` để tạo state có thể cập nhật trực tiếp.

```ts
import {signal} from '@angular/core';

// Create a writable signal
const count = signal(0);

// Read the value (always requires calling the getter function)
console.log(count());

// Update the value directly
count.set(3);

// Update based on the previous value
count.update((value) => value + 1);
```

### Expose dưới dạng Readonly

Khi expose state từ một service, thực hành tốt là chỉ expose phiên bản readonly để ngăn việc thay đổi từ bên ngoài.

```ts
private readonly _count = signal(0);
// Consumers can read this, but cannot call .set() or .update()
readonly count = this._count.asReadonly();
```

## Computed Signal (`computed`)

Dùng `computed()` để tạo các signal chỉ đọc (read-only) có giá trị dẫn xuất từ các signal khác.

- **Đánh giá lười (Lazily Evaluated)**: Hàm dẫn xuất không chạy cho đến khi computed signal được đọc.
- **Memoized**: Kết quả được cache. Nó chỉ tính lại khi một trong các signal mà nó phụ thuộc thay đổi.
- **Dependency động**: Chỉ các signal _thực sự được đọc_ trong quá trình dẫn xuất mới được theo dõi.

```ts
import {signal, computed} from '@angular/core';

const count = signal(0);
const doubleCount = computed(() => count() * 2);

// doubleCount automatically updates when count changes.
```

## Reactive Context

**Reactive context** là một trạng thái runtime trong đó Angular theo dõi các lần đọc signal để thiết lập dependency.

Angular tự động vào một reactive context khi đánh giá:

- Các `computed` signal
- Các callback của `effect`
- Các phép tính của `linkedSignal`
- Template của component

### Đọc không theo dõi (`untracked`)

Nếu bạn cần đọc một signal bên trong reactive context _mà không_ tạo dependency (để context không chạy lại khi signal thay đổi), hãy dùng `untracked()`.

```ts
import {effect, untracked} from '@angular/core';

effect(() => {
  // This effect only runs when currentUser changes.
  // It does NOT run when counter changes, even though counter is read here.
  console.log(`User: ${currentUser()}, Count: ${untracked(counter)}`);
});
```

### Thao tác bất đồng bộ trong Reactive Context

Reactive context chỉ hoạt động với code **đồng bộ**. Các lần đọc signal sau một `await` sẽ không được theo dõi. **Luôn đọc signal trước các ranh giới bất đồng bộ.**

```ts
// Incorrect: theme() is not tracked because it is read after await
effect(async () => {
  const data = await fetchUserData();
  console.log(theme());
});

// Correct: Read the signal before the await
effect(async () => {
  const currentTheme = theme();
  const data = await fetchUserData();
  console.log(currentTheme);
});
```
