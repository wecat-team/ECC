# Định nghĩa Dependency Provider

Angular cung cấp cả cách tự động lẫn thủ công để cung cấp dependency cho hệ thống Dependency Injection (DI) của nó.

## Cung cấp tự động

Cách phổ biến nhất để cung cấp một service là dùng `providedIn: 'root'` trên `@Injectable()`.

### InjectionToken

Dùng `InjectionToken` cho các dependency không phải class (object cấu hình, hàm, kiểu nguyên thủy). Một `InjectionToken` cũng có thể được cung cấp tự động.

```ts
import {InjectionToken} from '@angular/core';

export interface AppConfig {
  apiUrl: string;
}

export const APP_CONFIG = new InjectionToken<AppConfig>('app.config', {
  providedIn: 'root',
  factory: () => ({apiUrl: 'https://api.example.com'}),
});
```

## Cung cấp thủ công

Bạn dùng mảng `providers` khi một service không có `providedIn`, khi bạn muốn một instance mới cho một component cụ thể, hoặc khi cấu hình các giá trị lúc runtime.

```ts
@Component({
  providers: [
    // Shorthand for { provide: LocalService, useClass: LocalService }
    LocalService,

    // useClass: Swap implementations
    {provide: Logger, useClass: BetterLogger},

    // useValue: Provide static values
    {provide: API_URL_TOKEN, useValue: 'https://api.example.com'},

    // useFactory: Generate value dynamically
    {
      provide: ApiClient,
      useFactory: (http = inject(HttpClient)) => new ApiClient(http),
    },

    // useExisting: Create an alias
    {provide: OldLogger, useExisting: NewLogger},

    // multi: Provide multiple values for the same token as an array
    {provide: INTERCEPTOR_TOKEN, useClass: AuthInterceptor, multi: true},
  ],
})
export class Example {}
```

## Phạm vi của Provider

- **Application Bootstrap**: Singleton toàn cục. Dùng cho HTTP client, logging hoặc cấu hình toàn ứng dụng.
- **Component/Directive**: Instance được cô lập. Dùng cho state hoặc form riêng của component. Service bị hủy khi component bị hủy.
- **Route**: Service theo tính năng, chỉ được load cùng các route cụ thể.

## Library Pattern: các hàm `provide*`

Tác giả thư viện nên export các hàm trả về mảng provider để đóng gói cấu hình:

```ts
export function provideAnalytics(config: AnalyticsConfig): Provider[] {
  return [{provide: ANALYTICS_CONFIG, useValue: config}, AnalyticsService];
}
```
