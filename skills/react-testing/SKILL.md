---
name: react-testing
description: Kiểm thử component React với React Testing Library, Vitest/Jest, MSW để mock mạng, kiểm tra accessibility bằng axe, và ranh giới quyết định giữa component test với E2E (Playwright/Cypress). Dùng khi viết hoặc sửa test cho component, hook hoặc page React.
metadata:
  origin: ECC
---

# React Testing

Các pattern kiểm thử React toàn diện cho component test tập trung vào hành vi, test custom hook, kiểm tra accessibility và mock ở tầng mạng.

## Khi nào kích hoạt

- Viết test cho component, custom hook hoặc page React
- Bổ sung coverage cho các component legacy chưa có test
- Chuyển từ Enzyme hoặc các pattern thời class-component sang React Testing Library
- Thiết lập Vitest hoặc Jest cho dự án React mới
- Mock HTTP request trong test
- Kiểm tra các vi phạm accessibility
- Quyết định test nào thuộc RTL, test nào thuộc Playwright Component Testing, test nào thuộc E2E đầy đủ

## Nguyên tắc cốt lõi

Hãy test những gì người dùng nhìn thấy và thao tác, không test chi tiết triển khai.

Một test nên:

- Render component với cùng các provider như trong production
- Tương tác với component qua các query accessible (role, label) và `userEvent`
- Assert đầu ra hiển thị được và các side effect quan sát được (callback được gọi, request được gửi)

Một test KHÔNG nên:

- Kiểm tra state của component, props truyền cho component con, hoặc hook nào đã được gọi
- Mock chính React hoặc các hook của framework
- Assert số lần render hoặc cấu trúc DOM vượt quá những gì ảnh hưởng đến người dùng

## Lựa chọn thư viện

| Runner | Khi nào | Ghi chú |
|---|---|---|
| **Vitest** | Vite, Remix, các setup hiện đại | Nhanh hơn, ESM gốc, API tương thích Jest |
| **Jest** | Next.js, CRA, các repo đã có sẵn | Mặc định của nhiều dự án React |
| **Playwright Component Testing** | Cần engine trình duyệt thật | Dùng khi JSDOM thiếu tính năng cần thiết |
| **Cypress Component Testing** | Trình duyệt thật, đã dùng Cypress | Lựa chọn thay thế cho Playwright CT |

Chọn một. Không chạy RTL + Vitest VÀ Playwright CT trong cùng một repo trừ khi đã phân chia phạm vi rõ ràng.

## Thứ tự ưu tiên của query

React Testing Library cung cấp query theo ba tầng — dùng từ trên xuống:

1. **Accessible với mọi người**: `getByRole`, `getByLabelText`, `getByPlaceholderText`, `getByText`, `getByDisplayValue`
2. **Ngữ nghĩa (semantic)**: `getByAltText`, `getByTitle`
3. **Test ID (lối thoát cuối cùng)**: `getByTestId`

```tsx
// Best
screen.getByRole("button", { name: /save/i });

// OK for inputs
screen.getByLabelText("Email");

// Last resort
screen.getByTestId("save-btn");
```

Các biến thể:

- `getBy*` — throw nếu không có kết quả khớp
- `queryBy*` — trả về `null` (dùng để "assert không tồn tại")
- `findBy*` — bất đồng bộ, trả về Promise (dùng cho phần tử xuất hiện sau tác vụ async)

## Tương tác người dùng với `userEvent`

```tsx
import userEvent from "@testing-library/user-event";

test("submits the form", async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();
  render(<UserForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText("Email"), "user@example.com");
  await user.click(screen.getByRole("button", { name: /save/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: "user@example.com" });
});
```

- Luôn `await` các lệnh gọi userEvent
- Gọi `userEvent.setup()` một lần cho mỗi test, tái sử dụng `user` được trả về
- `userEvent` mô phỏng chuỗi sự kiện của trình duyệt thật; `fireEvent` chỉ dispatch một sự kiện tổng hợp đơn lẻ — ưu tiên `userEvent`

## Pattern bất đồng bộ

```tsx
// Element that appears after async work
expect(await screen.findByText("Loaded")).toBeInTheDocument();

// Side effect assertion
await waitFor(() => expect(saveSpy).toHaveBeenCalled());

// Element that should disappear
await waitForElementToBeRemoved(() => screen.queryByText("Loading"));
```

Không bao giờ dùng `setTimeout` + assertion — dễ flaky. Hãy dùng các matcher ở trên.

## Mock mạng với MSW

Mock Service Worker mock ở tầng mạng. Component, hook và thư viện fetch đều hoạt động y hệt như trong production.

### Thiết lập

```ts
// test/setup.ts
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/users/:id", ({ params }) =>
    HttpResponse.json({ id: params.id, name: "Alice" }),
  ),
  http.post("/api/users", async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: "new-id", ...body }, { status: 201 });
  }),
];

export const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Cấu hình `onUnhandledRequest: "error"` để mọi request chưa được mock đều làm test fail một cách rõ ràng — test pass âm thầm còn tệ hơn test đỏ.

### Ghi đè theo từng test

```tsx
test("renders error on 500", async () => {
  server.use(
    http.get("/api/users/:id", () => new HttpResponse(null, { status: 500 })),
  );
  render(<UserPage id="1" />);
  expect(await screen.findByText(/something went wrong/i)).toBeInTheDocument();
});
```

## Bọc Provider

Bọc các provider một lần duy nhất trong `test-utils.tsx`:

```tsx
// test-utils.tsx
import { render, RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

export function renderWithProviders(
  ui: React.ReactElement,
  options?: RenderOptions,
) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={lightTheme}>
        <MemoryRouter>{ui}</MemoryRouter>
      </ThemeProvider>
    </QueryClientProvider>,
    options,
  );
}

export * from "@testing-library/react";
```

Sau đó `import { renderWithProviders, screen } from "test-utils"` trong mọi file test.

## Test Custom Hook

```tsx
import { renderHook, act } from "@testing-library/react";

test("useCounter increments and decrements", () => {
  const { result } = renderHook(() => useCounter(0));

  expect(result.current.count).toBe(0);

  act(() => result.current.increment());
  expect(result.current.count).toBe(1);

  act(() => result.current.decrement());
  expect(result.current.count).toBe(0);
});

test("useCounter accepts initial value", () => {
  const { result } = renderHook(() => useCounter(10));
  expect(result.current.count).toBe(10);
});

test("useUser fetches user data", async () => {
  // Instantiate QueryClient ONCE per test outside the wrapper so it survives re-renders.
  // Creating it inside the wrapper closure resets cache state on every render, producing flaky tests.
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );

  const { result } = renderHook(() => useUser("1"), { wrapper });

  await waitFor(() => expect(result.current.isSuccess).toBe(true));
  expect(result.current.data).toEqual({ id: "1", name: "Alice" });
});
```

- Bọc các lệnh gọi thay đổi state trong `act`
- Chỉ test thông qua public API của hook
- Với hook dùng context, truyền `wrapper`

## Assert Accessibility

```tsx
import { axe, toHaveNoViolations } from "jest-axe"; // or vitest-axe
expect.extend(toHaveNoViolations);

test("UserCard has no a11y violations", async () => {
  const { container } = render(<UserCard user={mockUser} />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Chạy axe trong component test cho mọi component có tương tác. Phát hiện được:

- Thiếu label trên input của form
- Dùng ARIA không hợp lệ
- Độ tương phản màu kém (có giới hạn — JSDOM không có CSS engine thật nên chỉ hoạt động với inline style; kiểm tra tương phản trực quan thuộc về Playwright)
- Thiếu alt text trên ảnh
- Vi phạm thứ tự heading

Tham chiếu chéo: [skills/accessibility/SKILL.md](../accessibility/SKILL.md) cho playbook kiểm thử a11y đầy đủ hơn.

## Khi nào KHÔNG dùng Snapshot Test

Snapshot của đầu ra được render:

- Vỡ sau mỗi lần đổi style
- Bị duyệt qua loa trong review
- Test chi tiết triển khai (cấu trúc DOM), không test hành vi

Các trường hợp dùng snapshot chấp nhận được:

- Hàm serialize dữ liệu thuần (`formatInvoice(invoice)` -> chuỗi ổn định)
- File cấu hình được sinh ra (ví dụ: output cấu hình webpack)

Với visual regression của component, hãy dùng ảnh chụp màn hình của Playwright/Cypress hoặc Percy/Chromatic — so sánh khác biệt hình ảnh thực sự, không phải chuỗi DOM.

## Khi nào nên dùng Playwright / Cypress

JSDOM (được Vitest/Jest sử dụng) không thể:

- Render layout thật (flexbox, grid, viewport query)
- Chạy animation gốc của trình duyệt, CSS transition
- Test hành vi scroll, drag-and-drop, paste từ clipboard
- Xử lý iframe, popup, download, luồng cross-origin
- Chạy mạng thật trong môi trường được kiểm soát với đầy đủ hỗ trợ DevTools

Với bất kỳ trường hợp nào ở trên, hãy dùng Playwright Component Testing (component test trong trình duyệt thật) hoặc E2E đầy đủ. Xem [e2e-testing skill](../e2e-testing/SKILL.md).

Ranh giới quyết định:

- Một hook, một component thuần trình bày, một form có logic -> RTL
- Một component mà layout quan trọng hoặc dùng các browser API không có trong JSDOM -> Playwright CT
- Một luồng người dùng đầy đủ qua nhiều trang -> Playwright/Cypress E2E

## Mục tiêu Coverage

| Tầng | Mục tiêu |
|---|---|
| Hàm tiện ích thuần | >=90% |
| Custom hook | >=85% |
| Component trình bày | >=80% — hành vi, không phải số dòng |
| Container component | >=70% — golden path + trạng thái lỗi |
| Page | E2E bao phủ riêng; tối thiểu có smoke test |

Cấu hình qua `vitest.config.ts` / `jest.config.js`:

```ts
// vitest.config.ts
test: {
  coverage: {
    provider: "v8",
    reporter: ["text", "html", "lcov"],
    thresholds: {
      lines: 80,
      functions: 80,
      branches: 70,
      statements: 80,
    },
  },
}
```

## Anti-Pattern

- `container.querySelector("...")` — bỏ qua các query accessible, khiến test pass trong khi người dùng thật sẽ gặp lỗi
- Assert số lần render — là chi tiết triển khai
- `jest.mock("react", ...)` — không bao giờ mock React. Hãy refactor component thay vào đó
- Mock component con theo mặc định — chỉ test tích hợp chứ không cô lập. Chỉ mock khi component con có side effect nặng
- Bỏ qua cảnh báo `act()` — chúng báo hiệu bug thật (cập nhật state sau khi unmount, thiếu bọc async)
- Chia sẻ mutable state giữa các test — flaky khi thứ tự test thay đổi
- Test vẫn pass khi bỏ `it.skip()` — nghĩa là test của bạn không thực sự assert những gì bạn nghĩ

## Quy trình TDD

```
RED     -> Write failing test for the next requirement
GREEN   -> Write minimal component code to pass
REFACTOR -> Improve the component, tests stay green
REPEAT  -> Next requirement
```

Với component mới:

1. Định nghĩa kiểu props và signature của component
2. Viết test đầu tiên cho trường hợp đơn giản nhất
3. Xác nhận test fail vì đúng lý do
4. Triển khai vừa đủ để pass
5. Thêm test case tiếp theo
6. Refactor khi test tương tự thứ ba làm lộ ra một pattern

## Lệnh test

```bash
# Vitest
vitest                            # watch
vitest run                        # one-shot
vitest run --coverage             # with coverage
vitest run path/to/file.test.tsx  # single file

# Jest
jest --watch
jest --coverage
jest path/to/file.test.tsx

# CI mode
CI=true vitest run --coverage
```

## Liên quan

- Rules: [rules/react/testing.md](../../rules/react/testing.md)
- Skills: [react-patterns](../react-patterns/SKILL.md), [accessibility](../accessibility/SKILL.md), [e2e-testing](../e2e-testing/SKILL.md), [tdd-workflow](../tdd-workflow/SKILL.md)
- Agents: `react-reviewer` (review chất lượng test trong lúc code review), `tdd-guide` (thực thi quy trình TDD)
- Commands: `/react-test`, `/react-review`

## Ví dụ

### Gửi form với MSW và userEvent

```tsx
test("submits user form and shows success", async () => {
  server.use(
    http.post("/api/users", () =>
      HttpResponse.json({ id: "1", name: "Alice" }, { status: 201 }),
    ),
  );

  const user = userEvent.setup();
  renderWithProviders(<UserForm />);

  await user.type(screen.getByLabelText("Name"), "Alice");
  await user.type(screen.getByLabelText("Email"), "alice@example.com");
  await user.click(screen.getByRole("button", { name: /save/i }));

  expect(await screen.findByText(/saved successfully/i)).toBeInTheDocument();
});
```

### Test error boundary

```tsx
function Broken() {
  throw new Error("boom");
}

test("error boundary renders fallback", () => {
  // Suppress React's console.error noise for the expected throw, then restore so
  // the spy does not leak across tests and hide real errors elsewhere.
  const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
  try {
    render(
      <ErrorBoundary fallback={<div>Something went wrong</div>}>
        <Broken />
      </ErrorBoundary>,
    );

    expect(screen.getByText("Something went wrong")).toBeInTheDocument();
  } finally {
    errorSpy.mockRestore();
  }
});
```

### Test Suspense boundary

```tsx
test("shows loading then content", async () => {
  renderWithProviders(
    <Suspense fallback={<div>Loading...</div>}>
      <UserDetail id="1" />
    </Suspense>,
  );

  expect(screen.getByText("Loading...")).toBeInTheDocument();
  expect(await screen.findByText("Alice")).toBeInTheDocument();
});
```
