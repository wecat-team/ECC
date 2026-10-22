# End-to-End (E2E) Testing

Dùng E2E test để bao phủ các hành trình người dùng quan trọng trong một trình duyệt thật. Ưu tiên framework đã được cấu hình sẵn trong Angular workspace, chẳng hạn Cypress hoặc Playwright.

## Chạy E2E Test

Kiểm tra `package.json` và `angular.json` để biết lệnh riêng của dự án. Các mẫu phổ biến gồm:

```shell
npm run e2e
pnpm e2e
ng e2e
```

Khi ứng dụng phải được build hoặc serve trước, hãy dùng các script có sẵn của dự án thay vì tự tạo một entrypoint test song song.

## Cấu trúc Test

- Giữ các E2E spec gần với framework test đã cấu hình, chẳng hạn `cypress/e2e/` hoặc `e2e/`.
- Đặt các helper login/setup tái sử dụng trong thư mục support của framework.
- Giữ fixture tường minh và đủ nhỏ để mỗi test có thể giải thích trạng thái người dùng mà nó phụ thuộc vào.

### Ví dụ Cypress

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

### Ví dụ Playwright

```typescript
import {expect, test} from '@playwright/test';

test('redirects to dashboard on valid credentials', async ({page}) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', {name: 'Sign in'}).click();
  await expect(page).toHaveURL(/dashboard/);
});
```

## Best Practice

- Ưu tiên các locator accessible (`getByRole`, `getByLabel`) hoặc các thuộc tính `data-*` ổn định.
- Tránh các selector phụ thuộc vào CSS class, độ sâu DOM hoặc text ngẫu nhiên.
- Chờ các trạng thái UI, route hoặc network response cụ thể thay vì sleep tùy ý.
- Giữ smoke test ngắn gọn và dành phần bao phủ toàn bộ workflow cho các luồng có giá trị cao nhất.
