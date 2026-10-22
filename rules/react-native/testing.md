---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Kiểm thử React Native / Expo

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung riêng cho React Native / Expo.
> Mục tiêu coverage và quy trình TDD được kế thừa từ common/testing.md (tối thiểu 80%, RED-GREEN-REFACTOR).

## Công cụ

| Tầng | Công cụ |
|-------|------|
| Unit / component | Jest + `@testing-library/react-native` (qua preset `jest-expo`) |
| Hook | `renderHook` của `@testing-library/react-native` |
| E2E | Maestro (khuyến nghị, flow YAML đơn giản) hoặc Detox |
| An toàn kiểu (type safety) | `tsc --noEmit` trong CI |

## Test component

- Truy vấn theo role/label/text có thể truy cập (accessible), không dùng `testID` trừ khi cần thiết — cách này cũng buộc tuân thủ khả năng truy cập (accessibility).
- Assert trên hành vi người dùng nhìn thấy, không assert chi tiết triển khai.
- Tuân theo Arrange-Act-Assert.

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native'

test('calls onSelect with the user id when pressed', () => {
  const onSelect = jest.fn()
  render(<UserCard user={{ id: '1', email: 'a@b.com' }} onSelect={onSelect} />)

  fireEvent.press(screen.getByText('a@b.com'))

  expect(onSelect).toHaveBeenCalledWith('1')
})
```

## Mocking

- Mock các module Expo SDK (camera, location, notifications, secure-store) tại ranh giới của test.
- Bọc các component dùng TanStack Query trong `QueryClientProvider` với client mới cho mỗi test.
- Mock điều hướng (`expo-router`) để các màn hình render độc lập.

## E2E

- Chỉ bao phủ các flow quan trọng: xác thực, điều hướng chính, giao dịch cốt lõi.
- Chạy E2E trên CI với app đã build (EAS Build) trước khi release.

## Test gì trước

Hãy CHỦ ĐỘNG dùng agent `tdd-guide` cho tính năng mới: viết một test thất bại mô tả đúng hành vi, rồi mới triển khai.
