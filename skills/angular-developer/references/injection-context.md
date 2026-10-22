# Injection Context

Hàm `inject()` chỉ có thể dùng khi code đang thực thi trong một **injection context**.

## Injection Context khả dụng ở đâu?

Một injection context tự động khả dụng trong:

1. **Field initializer** của các class được DI khởi tạo (`@Injectable`, `@Component`, `@Directive`, `@Pipe`).
2. **Constructor** của các class được DI khởi tạo.
3. **Factory function** được chỉ định trong `useFactory` hoặc cấu hình `InjectionToken`.
4. **Functional API** do Angular thực thi (ví dụ: functional route guard, resolver, interceptor).

```ts
@Component({...})
export class Example {
  // Valid: Field initializer
  private router = inject(Router);

  constructor() {
    // Valid: Constructor
    const http = inject(HttpClient);
  }

  onClick() {
    // Invalid: Not an injection context
    // const auth = inject(AuthService);
  }
}
```

## `runInInjectionContext`

Nếu bạn cần chạy một hàm trong injection context (thường cần khi tạo component động hoặc khi testing), hãy dùng `runInInjectionContext`. Hàm này yêu cầu truy cập một injector sẵn có (như `EnvironmentInjector` hoặc `Injector`).

```ts
import {Injectable, inject, EnvironmentInjector, runInInjectionContext} from '@angular/core';

@Injectable({providedIn: 'root'})
export class MyService {
  private injector = inject(EnvironmentInjector);

  doSomethingDynamic() {
    runInInjectionContext(this.injector, () => {
      // Now valid to use inject() here
      const router = inject(Router);
    });
  }
}
```

## `assertInInjectionContext`

Dùng `assertInInjectionContext` trong các hàm tiện ích để đảm bảo chúng được gọi từ một context hợp lệ. Nó ném một lỗi rõ ràng nếu không hợp lệ.

```ts
import {assertInInjectionContext, inject, ElementRef} from '@angular/core';

export function injectNativeElement<T extends Element>(): T {
  assertInInjectionContext(injectNativeElement);
  return inject(ElementRef).nativeElement;
}
```
