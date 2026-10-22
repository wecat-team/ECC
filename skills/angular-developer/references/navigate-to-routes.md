# Điều hướng tới Route

Angular cung cấp cả cách khai báo (declarative) lẫn lập trình (programmatic) để điều hướng giữa các route.

## Điều hướng khai báo (`RouterLink`)

Dùng directive `RouterLink` trên các phần tử anchor.

```ts
import {RouterLink, RouterLinkActive} from '@angular/router';

@Component({
  imports: [RouterLink, RouterLinkActive],
  template: `
    <nav>
      <a routerLink="/dashboard" routerLinkActive="active-link">Dashboard</a>
      <a [routerLink]="['/user', userId]">Profile</a>
    </nav>
  `,
})
export class Nav {
  userId = '123';
}
```

- **Đường dẫn tuyệt đối**: Bắt đầu bằng `/` (ví dụ: `/settings`).
- **Đường dẫn tương đối**: Không có `/` ở đầu. Dùng `../` để lên một cấp.

## Điều hướng bằng lập trình (`Router`)

Inject service `Router` để điều hướng qua code TypeScript.

### `router.navigate()`

Dùng một mảng các command.

```ts
private router = inject(Router);
private route = inject(ActivatedRoute);

// Standard navigation
this.router.navigate(['/profile']);

// With parameters
this.router.navigate(['/search'], {
  queryParams: { q: 'angular' },
  fragment: 'results'
});

// Relative navigation
this.router.navigate(['edit'], { relativeTo: this.route });
```

### `router.navigateByUrl()`

Dùng một đường dẫn dạng chuỗi. Lý tưởng cho điều hướng tuyệt đối hoặc URL đầy đủ.

```ts
this.router.navigateByUrl('/products/123?view=details');

// Replace current entry in history
this.router.navigateByUrl('/login', {replaceUrl: true});
```

## URL Parameter

- **Route Param**: Là một phần của đường dẫn (ví dụ: `/user/123`).
- **Query Param**: Nằm sau dấu `?` (ví dụ: `/search?q=query`).
- **Matrix Param**: Giới hạn trong một segment (ví dụ: `/products;category=books`).
