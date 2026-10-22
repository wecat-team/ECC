---
paths:
  - "**/*.test.tsx"
  - "**/*.test.jsx"
  - "**/*.spec.tsx"
  - "**/*.spec.jsx"
  - "**/__tests__/**/*.ts"
  - "**/__tests__/**/*.tsx"
---
# Kiểm thử React

> File này mở rộng [typescript/testing.md](../typescript/testing.md) và [common/testing.md](../common/testing.md) với nội dung riêng cho React.

## Lựa chọn thư viện

- **React Testing Library (RTL)** — chuẩn để kiểm thử component. Kiểm thử hành vi thông qua DOM đã render.
- **Vitest** — runner được ưu tiên cho các dự án mới dựa trên Vite. Nhanh hơn Jest, ESM gốc, cùng API.
- **Jest** — vẫn là mặc định cho các dự án Next.js / CRA. RTL hoạt động y hệt.
- **Playwright Component Testing** — khi test component cần engine trình duyệt thật (animation, layout, sự kiện phức tạp)
- **Cypress Component Testing** — runner component trên trình duyệt thật thay thế

Chọn một component test runner cho mỗi dự án — không trộn RTL + Playwright CT trong cùng một repo.

## Nguyên tắc cốt lõi

Hãy test những gì người dùng thấy và làm, không test chi tiết triển khai.

- Truy vấn theo accessible role trước, rồi đến label, rồi đến text — chỉ dùng `data-testid` khi không còn cách nào khác phù hợp
- Không bao giờ assert trên state nội bộ, props truyền cho component con, hay việc hook nào đã được gọi
- Refactor mà không làm hỏng test = test đang kiểm thử hành vi; đó chính là mục tiêu

## Thứ tự ưu tiên của Query

RTL cung cấp các query theo ba nhóm. Dùng theo thứ tự ưu tiên từ trên xuống:

1. **Truy cập được với mọi người (accessible to everyone)**
   - `getByRole(role, { name })` — lựa chọn chính
   - `getByLabelText` — cho input của form
   - `getByPlaceholderText` — khi không có label (và hãy thêm label)
   - `getByText` — cho text không tương tác
   - `getByDisplayValue` — cho field của form đang có giá trị

2. **Query ngữ nghĩa (semantic)**
   - `getByAltText` — cho ảnh
   - `getByTitle` — phương án cuối cùng, giá trị accessibility thấp

3. **Test ID**
   - `getByTestId("some-id")` — chỉ là lối thoát khi không có cách nào ở trên dùng được

`getBy*` ném lỗi khi không khớp. `queryBy*` trả về null (dùng để assert sự vắng mặt). `findBy*` trả về promise (dùng cho async).

## Tương tác của người dùng

Ưu tiên `userEvent` hơn `fireEvent`. `userEvent` mô phỏng chuỗi sự kiện thật của trình duyệt (focus, keydown, beforeinput, input, keyup) — `fireEvent` chỉ dispatch một sự kiện tổng hợp duy nhất.

```tsx
import userEvent from "@testing-library/user-event";

test("submits the form", async () => {
  const user = userEvent.setup();
  render(<UserForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText("Email"), "user@example.com");
  await user.click(screen.getByRole("button", { name: /save/i }));

  expect(handleSubmit).toHaveBeenCalledWith({ email: "user@example.com" });
});
```

- Luôn `await` các lời gọi `userEvent` — chúng là async
- Gọi `userEvent.setup()` một lần ở đầu mỗi test, sau đó dùng lại `user` được trả về

## Assertion bất đồng bộ

```tsx
// SAI: query đồng bộ cho nội dung render bất đồng bộ
expect(screen.getByText("Loaded")).toBeInTheDocument();   // throws — not in DOM yet

// ĐÚNG: findBy* (returns a promise, retries)
expect(await screen.findByText("Loaded")).toBeInTheDocument();

// ĐÚNG: waitFor cho các assertion không phải về element
await waitFor(() => expect(saveSpy).toHaveBeenCalled());
```

- `findBy*` cho element xuất hiện bất đồng bộ
- `waitFor` cho các expectation bất đồng bộ về side effect hoặc các matcher khác
- Không bao giờ dùng `setTimeout` + assertion — dễ flaky

## Mock mạng bằng MSW

Dùng Mock Service Worker cho mọi test chạm tới ranh giới mạng. MSW chạy ở tầng mạng, nên component, hook và thư viện fetch đều hoạt động như trên production.

```tsx
// test setup
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";

const server = setupServer(
  http.get("/api/users/:id", ({ params }) =>
    HttpResponse.json({ id: params.id, name: "Alice" }),
  ),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Ghi đè theo từng test:

```tsx
test("renders error on 500", async () => {
  server.use(http.get("/api/users/:id", () => new HttpResponse(null, { status: 500 })));
  render(<UserPage id="1" />);
  expect(await screen.findByText(/something went wrong/i)).toBeInTheDocument();
});
```

## Tránh Snapshot Test cho Component

Snapshot của output đã render rất mong manh, khó review và thường bị reviewer duyệt qua loa. Chỉ dùng chúng cho:

- Serialization dữ liệu thuần (ví dụ một transformer tạo ra chuỗi ổn định)
- Bắt các regression ngoài ý muốn ở output không phải hình ảnh

Với visual regression của component, hãy dùng screenshot của Playwright / Cypress / Percy — so sánh hình ảnh thực sự, không phải so sánh DOM.

## Helper thiết lập Test

Bọc các provider một lần:

```tsx
function renderWithProviders(ui: React.ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ThemeProvider theme={lightTheme}>
        <Router>{ui}</Router>
      </ThemeProvider>
    </QueryClientProvider>,
  );
}
```

Export từ `test-utils.tsx` và dùng ở mọi nơi.

## Test Custom Hook

Dùng `renderHook` từ RTL:

```tsx
import { renderHook, act } from "@testing-library/react";

test("useCounter increments", () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

- Luôn bọc các lời gọi làm thay đổi state trong `act`
- Luôn test thông qua API công khai của hook, không test triển khai nội bộ

## Assertion về Accessibility

```tsx
import { axe } from "vitest-axe";   // or jest-axe

test("UserCard has no a11y violations", async () => {
  const { container } = render(<UserCard user={mockUser} />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Chạy assertion axe trong test component — bắt được label bị thiếu, dùng sai ARIA, độ tương phản màu (có giới hạn).

## Khi nào cần dùng Playwright / Cypress

Test component bằng RTL + JSDOM không thể:

- Test layout thật (flexbox, grid, render phụ thuộc viewport)
- Test scroll, drag-and-drop, paste từ clipboard
- Test animation gốc của trình duyệt, CSS transition
- Test tương tác xuyên frame (iframe, popup)

Với những trường hợp này, dùng Playwright Component Testing hoặc chạy end-to-end bằng Playwright/Cypress. Xem [skill e2e-testing](../../skills/e2e-testing/SKILL.md).

## Mục tiêu Coverage

| Tầng | Mục tiêu |
|---|---|
| Hàm utility thuần | ≥90% |
| Custom hook | ≥85% |
| Component (presentational) | ≥80% — hành vi, không phải số dòng |
| Container component | ≥70% — golden path + trạng thái lỗi |
| Page (E2E bao phủ riêng) | Tối thiểu một smoke test cho mỗi route |

## Anti-Pattern

- Assert trên `container.querySelector` — bỏ qua các accessibility query
- Assert trên số lần render — là chi tiết triển khai
- Mock React hook (`jest.mock("react", ...)`) — hãy refactor component thay vì mock
- Mock component con theo mặc định — chỉ test phần tích hợp, không test cha một cách độc lập
- Bỏ qua cảnh báo `act()` thủ công — chúng chỉ ra bug thật

## Tham chiếu Skill

Xem `skills/react-testing/SKILL.md` để có ví dụ test end-to-end, các pattern MSW và khung test accessibility.
