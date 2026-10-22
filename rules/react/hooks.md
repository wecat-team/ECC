---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/hooks/**/*.ts"
  - "**/hooks/**/*.js"
  - "**/use-*.ts"
  - "**/use-*.tsx"
---
# React Hooks

> File này nói về **React hook** (`useState`, `useEffect`, `useMemo`, `useCallback`, custom hook) — KHÔNG phải hệ thống runtime `hooks/` của Claude Code. Cách đặt tên khớp với quy ước theo ngôn ngữ `rules/<lang>/hooks.md` dùng xuyên suốt repo này.
>
> Mở rộng [typescript/patterns.md](../typescript/patterns.md) và [common/patterns.md](../common/patterns.md).

## Quy tắc của Hook

Thực thi `eslint-plugin-react-hooks` với `react-hooks/rules-of-hooks` đặt ở mức error.

1. Hook chỉ được gọi ở cấp cao nhất của function component hoặc của một hook khác
2. Không bao giờ gọi trong vòng lặp, điều kiện, hàm lồng nhau, hay sau early return
3. Luôn được gọi theo cùng một thứ tự ở mọi lần render
4. Chỉ gọi bên trong React function component hoặc custom hook (hàm bắt đầu bằng `use`)

```tsx
// SAI: hook có điều kiện
function Foo({ enabled }: { enabled: boolean }) {
  if (enabled) {
    const [x, setX] = useState(0); // rule violation
  }
}

// ĐÚNG: hook không điều kiện, điều kiện nằm bên trong
function Foo({ enabled }: { enabled: boolean }) {
  const [x, setX] = useState(0);
  if (!enabled) return null;
  return <span>{x}</span>;
}
```

## `useEffect` — Khi nào KHÔNG nên dùng

`useEffect` dùng để đồng bộ với hệ thống bên ngoài (subscription, browser API, thư viện bên thứ ba). Nó **không** phải công cụ phù hợp cho:

- Derived state — hãy tính trong lúc render
- Biến đổi dữ liệu để render — hãy tính trong lúc render
- Reset state khi prop thay đổi — dùng `key` ở component cha hoặc suy ra từ props
- Thông báo cho component cha về thay đổi state — gọi callback trong event handler
- Khởi tạo singleton cấp app — gọi hàm ở phía module hoặc trong `main.tsx`

```tsx
// SAI: dùng effect cho derived state
const [fullName, setFullName] = useState("");
useEffect(() => {
  setFullName(`${first} ${last}`);
}, [first, last]);

// ĐÚNG: suy ra trong lúc render
const fullName = `${first} ${last}`;
```

## Dependency array

- Luôn bao gồm mọi giá trị reactive được tham chiếu bên trong effect/callback
- Bật lint rule `react-hooks/exhaustive-deps` — không bao giờ tắt nó mà không có comment giải thích lý do
- Nếu dep array phình to khó kiểm soát, effect đang làm quá nhiều việc — hãy tách nó ra
- Danh tính (identity) ổn định cho hàm truyền vào deps: chỉ bọc bằng `useCallback` khi chính hàm đó là dependency của hook khác hoặc được truyền cho child đã memo

## Cleanup

Mọi subscription, interval, listener hoặc request đang chạy phải được dọn dẹp.

```tsx
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal }).then(handleResponse);
  return () => controller.abort();
}, [url]);
```

```tsx
useEffect(() => {
  const id = setInterval(tick, 1000);
  return () => clearInterval(id);
}, []);
```

Thiếu cleanup = race condition khi deps thay đổi, memory leak khi unmount.

## `useMemo` và `useCallback` — Khi nào đáng dùng

Quan điểm mặc định: **không memoize**. Chỉ thêm `useMemo` / `useCallback` khi:

1. Giá trị được truyền làm prop cho child bọc `React.memo`, và identity có ý nghĩa
2. Giá trị là dependency của một `useEffect` / `useMemo` / `useCallback` khác
3. Phép tính tốn kém đo đạc được (hãy profile trước khi giả định)

Memoize sớm làm thêm nhiễu, che giấu bug, và có thể chậm hơn chính phép tính lại mà nó thay thế.

## Custom Hook

Tách custom hook khi:

- Cùng một chuỗi hook (state + effect + computed) xuất hiện ở 2+ component
- Logic có mục đích rõ ràng, đặt tên được (`useDebounce`, `useOnClickOutside`, `useLocalStorage`)
- Bạn muốn test logic độc lập với bất kỳ component nào

KHÔNG tách khi:

- Nó chỉ có một nơi gọi — hãy inline
- "Hook" chỉ là `useState` với tên khác — thêm một tầng gián tiếp mà không có giá trị

```tsx
export function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
```

## Pattern của `useState`

- State khởi tạo từ prop chỉ tại lúc mount: truyền một hàm `useState(() => computeInitial(prop))` khi phép tính tốn kém
- Dùng functional updater khi state mới phụ thuộc state cũ: `setCount(c => c + 1)` — không bao giờ `setCount(count + 1)` trong ngữ cảnh async hoặc batched
- Chỉ gộp các state liên quan thành một object khi chúng luôn thay đổi cùng nhau; ngược lại hãy tách thành nhiều lời gọi `useState`
- Dùng `useReducer` khi các chuyển trạng thái phụ thuộc vào state trước đó hoặc có từ 3 giá trị liên quan trở lên

## Pattern của `useRef`

- DOM ref cho API mệnh lệnh (focus, scroll, thư viện bên thứ ba)
- Container có thể thay đổi mà không kích hoạt re-render (timer id, giá trị trước đó, cờ "is mounted")
- Không bao giờ đọc hoặc ghi `ref.current` trong lúc render — chỉ trong effect hoặc event handler
- `useImperativeHandle` chỉ khi cần expose API của child cho ref của cha — là lối thoát cuối cùng (last-resort escape hatch)

## `useSyncExternalStore`

Dùng hook này để subscribe vào bất kỳ external store nào (browser API, thư viện state bên thứ ba, event emitter tự viết). Đây là cách được hỗ trợ để làm cho external state an toàn với concurrent rendering.

```tsx
const isOnline = useSyncExternalStore(
  (cb) => {
    window.addEventListener("online", cb);
    window.addEventListener("offline", cb);
    return () => {
      window.removeEventListener("online", cb);
      window.removeEventListener("offline", cb);
    };
  },
  () => navigator.onLine,
  () => true,
);
```

## Bổ sung của React 19

- `use()` — mở (unwrap) promise và context ngay tại chỗ; dùng được có điều kiện (hook duy nhất có tính chất này)
- `useFormStatus()` / `useFormState()` (hoặc `useActionState`) — trạng thái submit form mà không cần prop drilling
- `useOptimistic()` — cập nhật UI lạc quan (optimistic) trong khi server action đang chờ
- `useTransition()` — đánh dấu các cập nhật state không khẩn cấp để các cập nhật khẩn cấp vẫn phản hồi mượt

Khi dự án nhắm tới React 19+, hãy ưu tiên những hook này hơn các giải pháp tự viết tương đương.

## Bẫy stale closure

Async handler và interval capture giá trị từ lần render nơi chúng được tạo. Cách sửa:

1. Dùng dạng functional updater của `setState`
2. Đưa giá trị thay đổi vào dep array của `useEffect` và dựng lại handler
3. Đọc từ một ref được giữ đồng bộ

## Cấu hình Lint

Các rule bắt buộc:

```json
{
  "rules": {
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn"
  }
}
```

Hãy coi cảnh báo `exhaustive-deps` là lỗi trong CI đối với code mới.
