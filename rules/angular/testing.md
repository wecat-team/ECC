---
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
---
# Kiểm thử Angular

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Angular.

## Test Runner

Dùng test runner mà dự án đã cấu hình. Kiểm tra `angular.json` và `package.json`; dự án Angular thường dùng Vitest, Jest hoặc Jasmine + Karma.

```bash
ng test               # watch mode
ng test --no-watch    # CI mode
```

## Thiết lập TestBed

Với standalone component, import trực tiếp component. Gọi `compileComponents()` cho các component có template bên ngoài.

```typescript
describe('UserCardComponent', () => {
  let fixture: ComponentFixture<UserCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserCardComponent);
  });
});
```

## Signal Input

Đặt các input dựa trên signal qua `fixture.componentRef.setInput()`:

```typescript
fixture.componentRef.setInput('user', mockUser);
fixture.detectChanges();
```

## Component Harness

Ưu tiên Angular CDK component harness thay cho truy vấn DOM trực tiếp khi tương tác với UI. Harness bền vững hơn trước các thay đổi markup.

```typescript
import { HarnessLoader } from '@angular/cdk/testing';
import { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';
import { MatButtonHarness } from '@angular/material/button/testing';

let loader: HarnessLoader;

beforeEach(() => {
  loader = TestbedHarnessEnvironment.loader(fixture);
});

it('triggers save on button click', async () => {
  const button = await loader.getHarness(MatButtonHarness.with({ text: 'Save' }));
  await button.click();
  expect(saveSpy).toHaveBeenCalled();
});
```

## Kiểm thử Router

Dùng `RouterTestingHarness` cho các component phụ thuộc vào router:

```typescript
import { RouterTestingHarness } from '@angular/router/testing';

it('renders user on navigation', async () => {
  const harness = await RouterTestingHarness.create();
  const component = await harness.navigateByUrl('/users/1', UserDetailComponent);
  expect(component.userId()).toBe('1');
});
```

## Kiểm thử bất đồng bộ

Dùng `fakeAsync` + `tick` để kiểm soát async. Dùng `waitForAsync` cho async thật với `fixture.whenStable()`.

```typescript
it('loads user after delay', fakeAsync(() => {
  const service = TestBed.inject(UserService);
  vi.spyOn(service, 'getUser').mockReturnValue(of(mockUser));

  fixture.detectChanges();
  tick();
  fixture.detectChanges();

  expect(fixture.nativeElement.querySelector('.name').textContent).toBe(mockUser.name);
}));
```

## Kiểm thử HTTP

```typescript
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { HttpTestingController } from '@angular/common/http/testing';

beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [provideHttpClient(), provideHttpClientTesting()],
  });
  httpMock = TestBed.inject(HttpTestingController);
});

afterEach(() => httpMock.verify());
```

## Kiểm thử Service

Inject service trực tiếp mà không cần component fixture:

```typescript
describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(UserService);
  });
});
```

## Cần kiểm thử gì

- **Service**: Mọi method public, các đường lỗi, tương tác HTTP
- **Component**: Binding input/output, kết quả render cho các trạng thái chính, tương tác của người dùng qua harness
- **Pipe**: Phép biến đổi thuần — unit test thông thường, không cần TestBed
- **Guard/Resolver**: Giá trị trả về cho các trạng thái được phép và bị từ chối, dùng `RouterTestingHarness`

## Kiểm thử E2E

Dùng framework E2E mà dự án đã cấu hình, như Cypress hoặc Playwright, cho các luồng người dùng quan trọng.

```typescript
describe('Login flow', () => {
  it('redirects to dashboard on valid credentials', () => {
    cy.visit('/login');
    cy.get('[data-cy=email]').type('user@example.com');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=submit]').click();
    cy.url().should('include', '/dashboard');
  });
});
```

- Thêm thuộc tính `data-cy` vào các phần tử tương tác để có selector ổn định
- Không dựa vào CSS class hay nội dung văn bản làm selector trong E2E test

## Coverage

Mục tiêu ≥80% cho service và pipe. Component: kiểm thử hành vi, không kiểm thử chi tiết triển khai.

## Tham chiếu Skill

Xem skill: `angular-developer` để có các pattern kiểm thử toàn diện, cách dùng harness và best practice về async.
