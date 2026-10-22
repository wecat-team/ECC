---
description: Áp dụng quy trình TDD cho React. Viết test React Testing Library trước (tập trung vào hành vi, ưu tiên accessibility), sau đó triển khai component. Phát hiện Vitest hoặc Jest và xác minh mục tiêu coverage.
---

# Lệnh React TDD

Lệnh này áp dụng phát triển hướng kiểm thử (TDD) cho React bằng React Testing Library cùng Vitest hoặc Jest, được phát hiện lúc runtime.

## Lệnh này làm gì

1. **Định nghĩa signature của component**: Dựng khung component, type của prop và các export
2. **Viết test hành vi trước**: Truy vấn RTL (ưu tiên role), `userEvent`, MSW cho network — RED
3. **Chạy test**: Xác minh chúng thất bại đúng lý do
4. **Triển khai code tối thiểu**: Vừa đủ để pass — GREEN
5. **Refactor**: Cải thiện trong khi giữ test xanh
6. **Kiểm tra coverage**: Đạt các mục tiêu trong [rules/react/testing.md](../rules/react/testing.md)

## Khi nào dùng

Dùng `/react-test` khi:

- Triển khai một React component hoặc custom hook mới
- Bổ sung test coverage cho component chưa có test
- Sửa bug (viết test thất bại tái hiện bug trước)
- Xây dựng form, state machine hoặc UI quan trọng về accessibility
- Làm quen với quy trình RTL + Vitest/Jest

## Chu trình TDD

```
RED      -> Write failing test for the next behavior
GREEN    -> Implement minimal component code to pass
REFACTOR -> Improve component, tests stay green
REPEAT   -> Next behavior
```

## Phát hiện runner

```bash
test -f vitest.config.ts -o -f vitest.config.js -o -f vite.config.ts   # Vitest
grep -l '"jest"' package.json                                          # Jest
```

Ưu tiên Vitest cho các project mới dựa trên Vite; tôn trọng Jest với các thiết lập hiện có.

## Ví dụ phiên làm việc

````text
User: /react-test I need a SearchInput component with debounced search

Agent:
# TDD Session: SearchInput

## Step 1: Define Signature

```tsx
// src/components/SearchInput.tsx
type Props = {
  onSearch: (query: string) => void;
  placeholder?: string;
  debounceMs?: number;
};

export function SearchInput({ onSearch, placeholder, debounceMs }: Props) {
  throw new Error("not implemented");
}
```

## Step 2: Write Behavior Tests (RED)

```tsx
// src/components/SearchInput.test.tsx
import { describe, expect, test, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SearchInput } from "./SearchInput";

describe("SearchInput", () => {
  test("renders with placeholder", () => {
    render(<SearchInput onSearch={() => {}} placeholder="Search users" />);
    expect(screen.getByPlaceholderText("Search users")).toBeInTheDocument();
  });

  test("calls onSearch after typing", async () => {
    vi.useFakeTimers();
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    const onSearch = vi.fn();
    render(<SearchInput onSearch={onSearch} debounceMs={300} />);

    await user.type(screen.getByRole("textbox"), "alice");

    expect(onSearch).not.toHaveBeenCalled();        // before debounce
    vi.advanceTimersByTime(300);
    expect(onSearch).toHaveBeenCalledWith("alice"); // after debounce

    vi.useRealTimers();
  });

  test("does not call onSearch when typing pauses then continues", async () => {
    vi.useFakeTimers();
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    const onSearch = vi.fn();
    render(<SearchInput onSearch={onSearch} debounceMs={300} />);

    await user.type(screen.getByRole("textbox"), "ali");
    vi.advanceTimersByTime(200);                    // mid-debounce
    await user.type(screen.getByRole("textbox"), "ce");
    vi.advanceTimersByTime(300);

    expect(onSearch).toHaveBeenCalledTimes(1);
    expect(onSearch).toHaveBeenCalledWith("alice");

    vi.useRealTimers();
  });

  test("is keyboard reachable and accessible", () => {
    render(<SearchInput onSearch={() => {}} />);
    const input = screen.getByRole("textbox");
    input.focus();
    expect(input).toHaveFocus();
  });
});
```

## Step 3: Run Tests — Verify FAIL

```bash
$ vitest run src/components/SearchInput.test.tsx

× src/components/SearchInput.test.tsx (4 tests) ✘ Error: not implemented
```

✓ Tests fail as expected.

## Step 4: Implement Minimal Code (GREEN)

```tsx
import { useEffect, useState } from "react";

export function SearchInput({ onSearch, placeholder, debounceMs = 300 }: Props) {
  const [query, setQuery] = useState("");

  useEffect(() => {
    const id = setTimeout(() => onSearch(query), debounceMs);
    return () => clearTimeout(id);
  }, [query, onSearch, debounceMs]);

  return (
    <input
      type="text"
      value={query}
      placeholder={placeholder}
      onChange={(e) => setQuery(e.target.value)}
    />
  );
}
```

## Step 5: Run Tests — Verify PASS

```bash
$ vitest run src/components/SearchInput.test.tsx

✓ src/components/SearchInput.test.tsx (4 tests) 47ms
```

## Step 6: Coverage

```bash
$ vitest run --coverage src/components/SearchInput.test.tsx

% Stmts: 100  % Branch: 100  % Funcs: 100  % Lines: 100
```

## TDD Complete!
````

## Các pattern test

### Hành vi, không phải triển khai

Dùng `getByRole`, `getByLabelText`, `getByText`. Tránh `container.querySelector` và assert trên state của component.

### `userEvent.setup()` cho mỗi test

```tsx
const user = userEvent.setup();
await user.click(screen.getByRole("button", { name: /save/i }));
```

### MSW cho network

```tsx
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

server.use(http.post("/api/users", () => HttpResponse.json({ id: "1" }, { status: 201 })));
```

### Custom hook

```tsx
const { result } = renderHook(() => useCounter(0));
act(() => result.current.increment());
expect(result.current.count).toBe(1);
```

### Accessibility

```tsx
import { axe } from "vitest-axe";
expect(await axe(container)).toHaveNoViolations();
```

## Mục tiêu coverage

| Tầng | Mục tiêu |
|---|---|
| Utility thuần | >=90% |
| Custom hook | >=85% |
| Presentational component | >=80% |
| Container component | >=70% |
| Page | Được E2E bao phủ riêng |

Cấu hình trong `vitest.config.ts` / `jest.config.js` để áp dụng ngưỡng trong CI.

## Anti-pattern cần tránh

- `container.querySelector(...)` — bỏ qua các truy vấn accessibility
- Assert trên số lần render
- Mock chính `react` (`jest.mock("react", ...)`)
- Mock child component theo mặc định (chỉ mock khi child có side effect nặng)
- Bỏ qua cảnh báo `act()` — chúng báo hiệu bug thật
- Snapshot test của component đã render (dễ vỡ, bị duyệt qua loa) — hãy dùng visual diff của Playwright/Cypress thay thế

## Các lệnh test

```bash
# Vitest
vitest                              # watch
vitest run                          # one-shot
vitest run --coverage               # with coverage
vitest run path/to/file.test.tsx    # single file

# Jest
jest --watch
jest --coverage
jest path/to/file.test.tsx

# CI mode
CI=true vitest run --coverage
```

## Các lệnh liên quan

- `/react-build` — sửa lỗi build trước khi chạy test
- `/react-review` — review sau khi triển khai
- skill `verification-loop` — vòng lặp verification đầy đủ

## Liên quan

- Skills: `skills/react-testing/`, `skills/tdd-workflow/`, `skills/accessibility/`, `skills/e2e-testing/`
- Rules: `rules/react/testing.md`
- Agents: `react-reviewer` (review chất lượng test), `tdd-guide` (thực thi quy trình TDD)
