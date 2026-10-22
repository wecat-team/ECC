# Testing với Component Harness

Component harness là cách chuẩn và được ưu tiên để tương tác với component trong test. Chúng cung cấp một API vững chắc, lấy người dùng làm trung tâm, giúp test ít dễ vỡ hơn và dễ đọc hơn nhờ cách ly test khỏi những thay đổi trong cấu trúc DOM nội bộ của component.

## Vì sao dùng Harness?

- **Độ vững chắc:** Test không bị hỏng khi bạn refactor HTML hoặc CSS class nội bộ của component.
- **Độ dễ đọc:** Test mô tả các tương tác từ góc nhìn của người dùng (ví dụ: `button.click()`, `slider.getValue()`) thay vì qua các truy vấn DOM (`fixture.nativeElement.querySelector(...)`).
- **Khả năng tái sử dụng:** Cùng một harness có thể dùng trong cả unit test lẫn E2E test.

Angular Material cung cấp một test harness cho mọi component trong thư viện của nó.

## Dùng Harness trong Unit Test

`TestbedHarnessEnvironment` là điểm vào để dùng harness trong unit test.

### Ví dụ: Test với `MatButtonHarness`

```ts
import {TestbedHarnessEnvironment} from '@angular/cdk/testing/testbed';
import {MatButtonHarness} from '@angular/material/button/testing';
import {MyButtonContainerComponent} from './my-button-container.component';

describe('MyButtonContainerComponent', () => {
  let fixture: ComponentFixture<MyButtonContainerComponent>;
  let loader: HarnessLoader;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MyButtonContainerComponent, MatButtonModule],
    }).compileComponents();

    fixture = TestBed.createComponent(MyButtonContainerComponent);
    // Create a harness loader for the component's fixture
    loader = TestbedHarnessEnvironment.loader(fixture);
  });

  it('should find a button with specific text', async () => {
    // Load the harness for a MatButton with the text "Submit"
    const submitButton = await loader.getHarness(MatButtonHarness.with({text: 'Submit'}));

    // Use the harness API to interact with the component
    expect(await submitButton.isDisabled()).toBe(false);
    await submitButton.click();

    // ... assertions
  });
});
```

### Khái niệm chính

1. **`HarnessLoader`**: Một đối tượng dùng để tìm và tạo các harness instance. Lấy loader cho fixture của component bằng `TestbedHarnessEnvironment.loader(fixture)`.

2. **`loader.getHarness(HarnessClass)`**: Tìm bất đồng bộ và trả về một harness instance cho component khớp đầu tiên.

3. **`HarnessClass.with({ ... })`**: Nhiều harness cung cấp một phương thức static `with` trả về một `HarnessPredicate`. Điều này cho phép bạn lọc và tìm component dựa trên các thuộc tính như text, selector hoặc trạng thái disabled. Luôn dùng nó để nhắm chính xác component bạn muốn test.

4. **Harness API:** Khi đã có một harness instance, hãy dùng các phương thức của nó (ví dụ: `.click()`, `.getText()`, `.getValue()`) để tương tác với component. Các phương thức này tự động xử lý việc chờ các thao tác bất đồng bộ và change detection.
