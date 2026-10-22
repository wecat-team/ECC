---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.store.ts"
  - "**/*.routes.ts"
---
# Pattern Angular

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Angular.

## Tách Smart / Dumb Component

Smart component (container) sở hữu việc lấy dữ liệu và state. Dumb component (presentational) chỉ nhận input và phát output — không inject service.

```typescript
// Smart — owns data
@Component({ standalone: true, changeDetection: ChangeDetectionStrategy.OnPush })
export class UserPageComponent {
  private userService = inject(UserService);
  user = toSignal(this.userService.getUser(this.userId));
}
```

```html
<!-- Dumb — pure presentation -->
<app-user-card [user]="user()" (select)="onSelect($event)" />
```

## Tầng Service

Service sở hữu toàn bộ việc truy cập dữ liệu và business logic. Component chỉ ủy quyền — không dùng `HttpClient` trong component.

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  getUsers(): Observable<User[]> {
    return this.http.get<User[]>('/api/users');
  }
}
```

## Dữ liệu bất đồng bộ với `resource`

Dùng `resource()` để lấy dữ liệu bất đồng bộ theo kiểu reactive. Ưu tiên hơn pipeline RxJS thủ công cho việc tải dữ liệu đơn giản:

```typescript
export class UserDetailComponent {
  userId = input.required<string>();

  userResource = resource({
    request: () => ({ id: this.userId() }),
    loader: ({ request }) =>
      firstValueFrom(inject(UserService).getUser(request.id)),
  });
}
```

Truy cập state: `userResource.value()`, `userResource.isLoading()`, `userResource.error()`, `userResource.reload()`.

## Pattern cho Signal State

```typescript
// Local mutable state
count = signal(0);

// Derived (never duplicated)
doubled = computed(() => this.count() * 2);

// Writable derived state that resets with source
selectedItem = linkedSignal(() => this.items()[0]);

// Bridge Observable to signal
users = toSignal(this.userService.getUsers(), { initialValue: [] });
```

KHÔNG BAO GIỜ lưu giá trị dẫn xuất trong các signal riêng — hãy dùng `computed`. KHÔNG BAO GIỜ dùng `effect` để đồng bộ signal — hãy dùng `computed` hoặc `linkedSignal`.

## Dọn dẹp Subscription

Dùng `takeUntilDestroyed()` cho mọi subscription thủ công. KHÔNG BAO GIỜ dùng `ngOnDestroy` + `Subject` + `takeUntil` thủ công trong code mới.

```typescript
export class UserComponent {
  private destroyRef = inject(DestroyRef);

  ngOnInit() {
    this.userService.updates$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(update => this.handleUpdate(update));
  }
}
```

## Routing

### Định nghĩa Route

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'admin',
    canMatch: [authGuard],           // CanMatch prevents loading the chunk at all
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES),
  },
  {
    path: 'users/:id',
    resolve: { user: userResolver },
    component: UserDetailComponent,
  },
];
```

- Dùng `canMatch` thay cho `canActivate` khi module của route không nên được tải với người dùng không có quyền
- Lazy-load mọi feature module bằng `loadChildren`
- Pre-fetch dữ liệu bằng `resolve` để tránh trạng thái loading trong component

### Functional Guard

```typescript
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  return auth.isAuthenticated()
    ? true
    : inject(Router).createUrlTree(['/login']);
};
```

### Data Resolver

```typescript
export const userResolver: ResolveFn<User> = (route) => {
  return inject(UserService).getUser(route.paramMap.get('id')!);
};
```

### View Transition

Bật chuyển cảnh route mượt mà bằng View Transitions API:

```typescript
// app.config.ts
provideRouter(routes, withViewTransitions())
```

## Pattern Dependency Injection

### Scoped Provider

Cung cấp service ở cấp component hoặc route khi chúng không nên là singleton:

```typescript
@Component({
  providers: [UserEditService],   // scoped to this component subtree
})
export class UserEditComponent {}
```

### `InjectionToken`

```typescript
export const CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');

// In providers:
{ provide: CONFIG, useValue: appConfig }
{ provide: CONFIG, useFactory: () => loadConfig(), deps: [] }

// Consume:
private config = inject(CONFIG);
```

### `viewProviders` so với `providers`

- `providers`: Khả dụng cho component và mọi content children của nó
- `viewProviders`: Chỉ khả dụng trong view riêng của component (không áp dụng cho nội dung được project vào)

## HTTP Interceptor

Dùng functional interceptor (v15+) cho xác thực, xử lý lỗi và retry:

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).token();
  if (!token) return next(req);
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};
```

Đăng ký trong `app.config.ts`:

```typescript
provideHttpClient(withInterceptors([authInterceptor, errorInterceptor]))
```

## Toán tử RxJS

- `switchMap` — tìm kiếm, điều hướng (hủy request trước đó)
- `mergeMap` — các request song song độc lập
- `exhaustMap` — gửi form (bỏ qua cho đến khi hoàn tất)
- Luôn xử lý lỗi bằng `catchError` — không bao giờ để stream chết trong im lặng

```typescript
search$ = this.query$.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(q => this.service.search(q).pipe(catchError(() => of([])))),
);
```

## Form

Khớp với chiến lược form sẵn có của dự án. Với ứng dụng mới v21+, ưu tiên signal forms.

```typescript
// Reactive Forms — standard for complex forms
export class UserFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    name: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
  });
}
```

## Chiến lược Rendering

- **CSR** (mặc định): SPA tiêu chuẩn
- **SSR + Hydration**: `ng add @angular/ssr` — cải thiện FCP và SEO
- **SSG (Prerendering)**: Trang tĩnh được tạo lúc build cho các route nặng nội dung

Khi dùng SSR, tránh dùng trực tiếp `window`, `document`, `localStorage` — hãy dùng `isPlatformBrowser` hoặc token `DOCUMENT`.

## Accessibility

Dùng Angular CDK cho các component headless, accessible (Accordion, Listbox, Combobox, Menu, Tabs, Toolbar, Tree, Grid). Style theo các thuộc tính ARIA thay vì quản lý chúng thủ công:

```css
[aria-selected="true"] { background: var(--color-selected); }
```

## Tham chiếu Skill

Xem skill: `angular-developer` để có hướng dẫn chuyên sâu về signals, forms, routing, DI, SSR và các pattern accessibility.
