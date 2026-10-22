---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/testing.md](../common/testing.md) với nội dung kiểm thử riêng cho web.

# Quy tắc kiểm thử Web

## Thứ tự ưu tiên

### 1. Visual Regression

- Chụp screenshot ở các breakpoint chính: 320, 768, 1024, 1440
- Test hero section, section scrollytelling và các trạng thái có ý nghĩa
- Dùng screenshot của Playwright cho công việc nặng về hình ảnh
- Nếu có cả hai theme, test cả hai

### 2. Accessibility

- Chạy kiểm tra accessibility tự động
- Test điều hướng bằng bàn phím
- Xác minh hành vi reduced-motion
- Xác minh độ tương phản màu

### 3. Hiệu năng

- Chạy Lighthouse hoặc công cụ tương đương trên các trang có ý nghĩa
- Giữ các mục tiêu CWV từ [performance.md](performance.md)

### 4. Cross-Browser

- Tối thiểu: Chrome, Firefox, Safari
- Test scroll, chuyển động và hành vi fallback

### 5. Responsive

- Test 320, 375, 768, 1024, 1440, 1920
- Xác minh không bị tràn (overflow)
- Xác minh các tương tác cảm ứng

## Hình dạng E2E

```ts
import { test, expect } from '@playwright/test';

test('landing hero loads', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toBeVisible();
});
```

- Tránh các assertion dựa trên timeout dễ flaky
- Ưu tiên chờ có tính xác định (deterministic)

## Unit Test

- Test utility, biến đổi dữ liệu và custom hook
- Với component thiên về hình ảnh, visual regression thường mang nhiều tín hiệu hơn các assertion markup mong manh
- Visual regression bổ sung cho mục tiêu coverage; nó không thay thế chúng
