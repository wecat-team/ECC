# Nền tảng Dependency Injection (DI)

Dependency Injection (DI) là một design pattern dùng để tổ chức và chia sẻ code trong ứng dụng bằng cách cho phép bạn "inject" các tính năng vào những phần khác nhau. Điều này cải thiện khả năng bảo trì, khả năng mở rộng và khả năng kiểm thử của code.

## DI hoạt động như thế nào trong Angular

Có hai cách chính để code tương tác với hệ thống DI của Angular:

1. **Providing**: Làm cho các giá trị (object, hàm, kiểu nguyên thủy) khả dụng với hệ thống DI.
2. **Injecting**: Yêu cầu các giá trị đó từ hệ thống DI.

Component, directive và service của Angular tự động tham gia vào DI.

## Service

**Service** là cách phổ biến nhất để chia sẻ dữ liệu và chức năng trong ứng dụng. Nó là một class TypeScript được gắn decorator `@Injectable()`.

### Tạo một Service

Dùng tùy chọn `providedIn: 'root'` trong decorator `@Injectable` để biến service thành singleton khả dụng trong toàn bộ ứng dụng. Đây là cách được khuyến nghị cho hầu hết service.

```ts
import {Injectable} from '@angular/core';

@Injectable({
  providedIn: 'root', // Makes this a singleton available everywhere
})
export class AnalyticsLogger {
  trackEvent(category: string, value: string) {
    console.log('Analytics event logged:', {category, value});
  }
}
```

Các cách dùng phổ biến của service gồm:

- Data client (gọi API)
- Quản lý state
- Xác thực (authentication) và phân quyền (authorization)
- Logging và xử lý lỗi
- Các hàm tiện ích

## Inject Dependency

Dùng hàm `inject()` của Angular để yêu cầu dependency.

### Hàm `inject()`

Bạn có thể dùng hàm `inject()` để lấy một instance của service (hoặc bất kỳ token nào khác đã được cung cấp).

```ts
import {Component, inject} from '@angular/core';
import {Router} from '@angular/router';
import {AnalyticsLogger} from './analytics-logger.service';

@Component({
  selector: 'app-navbar',
  template: `<a href="#" (click)="navigateToDetail($event)">Detail Page</a>`,
})
export class Navbar {
  // Injecting dependencies using class field initializers
  private router = inject(Router);
  private analytics = inject(AnalyticsLogger);

  navigateToDetail(event: Event) {
    event.preventDefault();
    this.analytics.trackEvent('navigation', '/details');
    this.router.navigate(['/details']);
  }
}
```

### `inject()` có thể dùng ở đâu? (Injection Context)

Bạn có thể gọi `inject()` trong một **injection context**. Các injection context phổ biến nhất là trong quá trình khởi tạo một component, directive hoặc service.

Những nơi hợp lệ để gọi `inject()`:

1. **Class field initializer** (Khuyến nghị)
2. **Thân constructor**
3. **Route guard và resolver** (được thực thi trong một injection context)
4. **Factory function** dùng trong provider

```typescript
import {Component, Directive, Injectable, inject, ElementRef} from '@angular/core';
import {HttpClient} from '@angular/common/http';

// 1. In a Component (Field Initializer & Constructor)
@Component({
  /*...*/
})
export class Example {
  private service1 = inject(MyService); // Valid field initializer

  private service2: MyService;
  constructor() {
    this.service2 = inject(MyService); // Valid constructor body
  }
}

// 2. In a Directive
@Directive({
  /*...*/
})
export class MyDirective {
  private element = inject(ElementRef); // Valid field initializer
}

// 3. In a Service
@Injectable({providedIn: 'root'})
export class MyService {
  private http = inject(HttpClient); // Valid field initializer
}

// 4. In a Route Guard (Functional)
export const authGuard = () => {
  const auth = inject(AuthService); // Valid route guard
  return auth.isAuthenticated();
};
```
