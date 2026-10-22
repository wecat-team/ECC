---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/ohosTest/**"
---
# Kiểm thử HarmonyOS / ArkTS

> File này mở rộng [common/testing.md](../common/testing.md) với các thực hành kiểm thử riêng cho HarmonyOS.

## Test Framework

HarmonyOS dùng test framework tích hợp sẵn với các khả năng của `@ohos.test`:

- **Unit test**: Nằm trong `src/ohosTest/ets/test/`
- **UI test**: Dùng `@ohos.UiTest` để kiểm thử component
- **Instrument test**: Chạy trên thiết bị/emulator

## Cấu trúc thư mục test

```
module/
  |-- src/
  |   |-- main/ets/          # Production code
  |   |-- ohosTest/ets/      # Test code
  |       |-- test/
  |       |   |-- Ability.test.ets
  |       |   |-- List.test.ets
  |       |-- TestAbility.ets
  |       |-- TestRunner.ets
```

## Chạy test

```bash
# Run all tests for a module
hvigorw testHap -p product=default

# Run tests on connected device
hdc shell aa test -b com.example.app -m entry_test -s unittest /ets/TestRunner/OpenHarmonyTestRunner
```

## Ví dụ Unit Test

```typescript
import { describe, it, expect } from '@ohos/hypium';

export default function UserViewModelTest() {
  describe('UserViewModel', () => {
    it('should_initialize_with_empty_state', 0, () => {
      const vm = new UserViewModel();
      expect(vm.userName).assertEqual('');
      expect(vm.isLoading).assertFalse();
    });

    it('should_update_user_name', 0, () => {
      const vm = new UserViewModel();
      vm.updateUserName('Alice');
      expect(vm.userName).assertEqual('Alice');
    });

    it('should_handle_empty_input', 0, () => {
      const vm = new UserViewModel();
      vm.updateUserName('');
      expect(vm.userName).assertEqual('');
      expect(vm.hasError).assertFalse();
    });
  });
}
```

## Ví dụ UI Test

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

export default function HomePageUITest() {
  describe('HomePage_UI', () => {
    it('should_display_title', 0, async () => {
      const driver = Driver.create();
      await driver.delayMs(1000);

      const title = await driver.findComponent(ON.text('Home'));
      expect(title !== null).assertTrue();
    });

    it('should_navigate_to_detail_on_click', 0, async () => {
      const driver = Driver.create();
      const button = await driver.findComponent(ON.id('detailButton'));
      await button.click();
      await driver.delayMs(500);

      const detailTitle = await driver.findComponent(ON.text('Detail'));
      expect(detailTitle !== null).assertTrue();
    });
  });
}
```

## Quy trình TDD cho HarmonyOS

Tuân theo chu trình TDD chuẩn đã được điều chỉnh cho HarmonyOS:

1. **RED**: Viết một test thất bại trong `ohosTest/ets/test/`
2. **GREEN**: Triển khai code tối thiểu trong `main/ets/` để test pass
3. **REFACTOR**: Dọn dẹp trong khi giữ test xanh
4. **BUILD**: Chạy `hvigorw assembleHap` để xác minh biên dịch
5. **VERIFY**: Chạy test trên thiết bị/emulator

## Yêu cầu Test Coverage

- Tối thiểu 80% coverage cho toàn bộ code ứng dụng quan trọng (ViewModel, service, utility)
- **Unit test**: Mọi hàm utility, logic ViewModel, data model
- **Integration test**: Lời gọi API, thao tác database, tương tác giữa các module
- **E2E / UI test**: Các luồng người dùng quan trọng (đăng nhập, điều hướng, gửi dữ liệu)
- Kiểm thử các edge case: dữ liệu rỗng, lỗi mạng, bị từ chối permission

## Best Practice khi kiểm thử

- Giữ các test độc lập - không chia sẻ mutable state giữa các test
- Mock các lời gọi mạng và system API trong unit test
- Dùng tên test có ý nghĩa: `should_[expected_behavior]_when_[condition]`
- Kiểm thử tính reactive của V2 state management: xác minh các thuộc tính `@Trace` kích hoạt cập nhật UI
- Kiểm thử luồng Navigation: xác minh các thao tác push/pop/replace của `NavPathStack`
- Tránh kiểm thử phần nội bộ của framework - tập trung vào business logic và hành vi người dùng nhìn thấy
