# Testing với RouterTestingHarness

Khi test các component có liên quan đến routing, điều quan trọng là **không mock Router hay các service liên quan**. Thay vào đó, hãy dùng `RouterTestingHarness`, công cụ cung cấp cách vững chắc và đáng tin cậy để test logic routing trong một môi trường phản ánh sát một ứng dụng thật.

Dùng harness đảm bảo bạn đang test cấu hình router, guard và resolver thực sự, từ đó tạo ra các test có ý nghĩa hơn.

## Thiết lập cho Router Testing

`RouterTestingHarness` là công cụ chính để test các tình huống routing. Bạn cũng cần cung cấp các test route của mình bằng hàm `provideRouter` trong cấu hình `TestBed`.

### Ví dụ thiết lập

```ts
import {TestBed} from '@angular/core/testing';
import {provideRouter} from '@angular/router';
import {RouterTestingHarness} from '@angular/router/testing';
import {Dashboard} from './dashboard.component';
import {HeroDetail} from './hero-detail.component';

describe('Dashboard Component Routing', () => {
  let harness: RouterTestingHarness;

  beforeEach(async () => {
    // 1. Configure TestBed with test routes
    await TestBed.configureTestingModule({
      providers: [
        // Use provideRouter with your test-specific routes
        provideRouter([
          {path: '', component: Dashboard},
          {path: 'heroes/:id', component: HeroDetail},
        ]),
      ],
    }).compileComponents();

    // 2. Create the RouterTestingHarness
    harness = await RouterTestingHarness.create();
  });
});
```

### Khái niệm chính

1. **`provideRouter([...])`**: Cung cấp cấu hình routing riêng cho test. Cấu hình này nên bao gồm các route cần thiết để component đang được test hoạt động đúng.
2. **`RouterTestingHarness.create()`**: Tạo và khởi tạo harness một cách bất đồng bộ, đồng thời thực hiện lần điều hướng ban đầu tới URL gốc (`/`).

## Viết Router Test

Sau khi harness được tạo, bạn có thể dùng nó để điều khiển điều hướng và đưa ra các assertion về trạng thái của router và các component được kích hoạt.

### Ví dụ: Test điều hướng

```ts
it('should navigate to a hero detail when a hero is selected', async () => {
  // 1. Navigate to the initial component and get its instance
  const dashboard = await harness.navigateByUrl('/', Dashboard);

  // Suppose the dashboard has a method to select a hero
  const heroToSelect = {id: 42, name: 'Test Hero'};
  dashboard.selectHero(heroToSelect);

  // Wait for stability after the action that triggers navigation
  await harness.fixture.whenStable();

  // 2. Assert on the URL
  expect(harness.router.url).toEqual('/heroes/42');

  // 3. Get the activated component after navigation
  const heroDetail = await harness.getHarness(HeroDetail);

  // 4. Assert on the state of the new component
  expect(await heroDetail.componentInstance.hero.name).toBe('Test Hero');
});

it('should get the activated component directly', async () => {
  // Navigate and get the component instance in one step
  const dashboardInstance = await harness.navigateByUrl('/', Dashboard);

  expect(dashboardInstance).toBeInstanceOf(Dashboard);
});
```

### Best Practice

- **Điều hướng bằng Harness:** Luôn dùng `harness.navigateByUrl()` để mô phỏng điều hướng. Phương thức này trả về một promise resolve ra instance của component được kích hoạt.
- **Truy cập Router State:** Dùng `harness.router` để truy cập router instance đang chạy và assert trên trạng thái của nó (ví dụ: `harness.router.url`).
- **Lấy các Component được kích hoạt:** Dùng `harness.getHarness(ComponentType)` để lấy một instance của component harness cho routed component đang được kích hoạt, hoặc `harness.routeDebugElement` để lấy `DebugElement`.
- **Chờ cho ổn định:** Sau khi thực hiện một hành động gây ra điều hướng, luôn `await harness.fixture.whenStable()` để đảm bảo routing đã hoàn tất trước khi assert.
