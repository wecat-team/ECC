# Nền tảng Testing

Hướng dẫn này bao gồm các nguyên tắc và thực hành cơ bản để viết unit test và component test cho Angular. Hãy dùng runner đã được cấu hình sẵn trong dự án.

## Triết lý cốt lõi: Ưu tiên bất đồng bộ (Async-First)

Các ứng dụng Angular hiện đại thường lên lịch thay đổi state một cách bất đồng bộ, đặc biệt khi dùng signal hoặc zoneless change detection. Test nên tính đến điều này.

Ưu tiên pattern "Act, Wait, Assert":

1. **Act:** Cập nhật state hoặc thực hiện một hành động (ví dụ: đặt input của component, click một nút).
2. **Wait:** Dùng `await fixture.whenStable()` để framework xử lý bản cập nhật đã lên lịch và render các thay đổi.
3. **Assert:** Xác minh kết quả.

### Ví dụ cấu trúc Test cơ bản

```ts
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {MyComponent} from './my.component';

describe('MyComponent', () => {
  let component: MyComponent;
  let fixture: ComponentFixture<MyComponent>;
  let h1: HTMLElement;

  beforeEach(async () => {
    // 1. Configure the test module
    await TestBed.configureTestingModule({
      imports: [MyComponent],
    }).compileComponents();

    // 2. Create the component fixture
    fixture = TestBed.createComponent(MyComponent);
    component = fixture.componentInstance;
    h1 = fixture.nativeElement.querySelector('h1');
  });

  it('should display the default title', async () => {
    // ACT: (Implicit) Component is created with default state.
    // WAIT for initial data binding.
    await fixture.whenStable();
    // ASSERT the initial state.
    expect(h1.textContent).toContain('Default Title');
  });

  it('should display a different title after a change', async () => {
    // ACT: Change the component's title property.
    component.title.set('New Test Title');

    // WAIT for the asynchronous update to complete.
    await fixture.whenStable();

    // ASSERT the DOM has been updated.
    expect(h1.textContent).toContain('New Test Title');
  });
});
```

## TestBed và ComponentFixture

- **`TestBed`**: Tiện ích chính để tạo một Angular module riêng cho test. Dùng `TestBed.configureTestingModule({...})` trong `beforeEach` để khai báo component, cung cấp service và thiết lập các import cần cho test của bạn.
- **`ComponentFixture`**: Một handle trỏ tới component instance đã tạo và môi trường của nó.
  - `fixture.componentInstance`: Truy cập class instance của component.
  - `fixture.nativeElement`: Truy cập phần tử DOM gốc của component.
  - `fixture.debugElement`: Một wrapper riêng của Angular quanh `nativeElement`, cung cấp các cách truy vấn DOM an toàn hơn, không phụ thuộc nền tảng (ví dụ: `debugElement.query(By.css('p'))`).
