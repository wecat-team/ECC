---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.directive.ts"
  - "**/*.pipe.ts"
  - "**/*.guard.ts"
  - "**/*.resolver.ts"
  - "**/*.module.ts"
---
# Phong cách code Angular

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Angular.

## Nhận biết phiên bản

Luôn kiểm tra phiên bản Angular của dự án trước khi viết code — tính năng khác nhau đáng kể giữa các phiên bản. Chạy `ng version` hoặc xem `package.json`. Khi tạo dự án mới, không ghim (pin) phiên bản trừ khi người dùng chỉ định.

Sau khi sinh hoặc sửa code Angular, luôn chạy `ng build` để bắt lỗi trước khi kết thúc.

## Đặt tên file

Tuân theo quy ước của Angular CLI — mỗi file một artifact:

- `user-profile.component.ts` + `user-profile.component.html` + `user-profile.component.spec.ts`
- `user.service.ts`, `auth.guard.ts`, `date-format.pipe.ts`
- Thư mục feature: `features/users/`, `features/auth/`
- Sinh bằng CLI: `ng generate component features/users/user-card`

## Component

Ưu tiên standalone component (mặc định từ v17+). Dùng change detection `OnPush` cho mọi component mới.

```typescript
@Component({
  selector: 'app-user-card',
  standalone: true,
  imports: [RouterModule],
  templateUrl: './user-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserCardComponent {
  user = input.required<User>();
  select = output<string>();
}
```

## Dependency Injection

Dùng `inject()` thay cho constructor injection. Để constructor trống hoặc bỏ hẳn.

```typescript
// CORRECT
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private router = inject(Router);
}

// WRONG: Constructor injection is verbose and harder to tree-shake
constructor(private http: HttpClient, private router: Router) {}
```

Dùng `InjectionToken` cho các dependency không phải class:

```typescript
const API_URL = new InjectionToken<string>('API_URL');

// Provide:
{ provide: API_URL, useValue: 'https://api.example.com' }

// Consume:
private apiUrl = inject(API_URL);
```

## Signals

### Các primitive cốt lõi

```typescript
count = signal(0);
doubled = computed(() => this.count() * 2);

increment() {
  this.count.update(n => n + 1);
}
```

### `linkedSignal` — State dẫn xuất có thể ghi

Dùng `linkedSignal` khi một signal phải reset hoặc thích ứng khi nguồn thay đổi, nhưng đồng thời vẫn có thể ghi độc lập:

```typescript
selectedOption = linkedSignal(() => this.options()[0]);
// Resets to first option when options changes, but user can override
```

### `resource` — Đưa dữ liệu bất đồng bộ vào signal

Dùng `resource()` để lấy dữ liệu bất đồng bộ theo kiểu reactive mà không cần subscription thủ công:

```typescript
userResource = resource({
  request: () => ({ id: this.userId() }),
  loader: ({ request }) => fetch(`/api/users/${request.id}`).then(r => r.json()),
});

// Access: userResource.value(), userResource.isLoading(), userResource.error()
```

### Cách dùng `effect`

Chỉ dùng `effect()` cho các side effect bắt buộc phải phản ứng với thay đổi của signal (logging, thao tác DOM của thư viện bên thứ ba). KHÔNG BAO GIỜ dùng effect để đồng bộ các signal — hãy dùng `computed` hoặc `linkedSignal`. Với thao tác DOM sau khi render, dùng `afterRenderEffect`.

```typescript
// CORRECT: Side effect
effect(() => console.log('User changed:', this.user()));

// WRONG: Use computed instead
effect(() => { this.fullName.set(`${this.first()} ${this.last()}`); });
```

## Template

Dùng cú pháp block của v17+. Luôn cung cấp `track` trong `@for`:

```html
@for (item of items(); track item.id) {
  <app-item [item]="item" />
}

@if (isLoading()) {
  <app-spinner />
} @else if (error()) {
  <app-error [message]="error()" />
} @else {
  <app-content [data]="data()" />
}
```

Không đặt logic trong template ngoài các điều kiện đơn giản — hãy chuyển sang method của component hoặc pipe.

## Form

Chọn chiến lược form phù hợp với cách tiếp cận sẵn có của dự án:

- **Signal Forms** (v21+): Ưu tiên cho dự án mới trên v21+. State của form dựa trên signal.
- **Reactive Forms**: `FormBuilder` + `FormGroup` + `FormControl`. Phù hợp nhất cho form phức tạp có validation động.
- **Template-Driven Forms**: `ngModel`. Chỉ phù hợp với form đơn giản.

```typescript
// Reactive Forms — standard approach for most apps
export class LoginComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  submit() {
    if (this.form.valid) {
      // use this.form.value
    }
  }
}
```

## Style của component

Dùng style ở cấp component với `ViewEncapsulation.Emulated` (mặc định). Tránh `ViewEncapsulation.None` trừ khi xây dựng design system cố ý để style lan ra ngoài.

- Giới hạn phạm vi style trong component — không dùng tên class toàn cục bên trong stylesheet của component
- Dùng `:host` để tạo style cho host element
- Ưu tiên CSS custom property cho các giá trị có thể đổi theme

## Change Detection

- Mặc định dùng `ChangeDetectionStrategy.OnPush` cho mọi component mới
- Signal và `async` pipe tự xử lý việc phát hiện thay đổi — tránh `markForCheck()` và `detectChanges()`
- KHÔNG BAO GIỜ mutate trực tiếp các object `@Input()` khi dùng OnPush
