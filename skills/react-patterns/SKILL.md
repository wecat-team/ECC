---
name: react-patterns
description: Các pattern React 18/19 gồm kỷ luật dùng hook, ranh giới server/client component, Suspense + error boundary, form action, data fetching, cây quyết định quản lý state và composition ưu tiên accessibility. Dùng khi viết hoặc review React component.
metadata:
  origin: ECC
---

# Các pattern React

Các pattern React 18/19 idiomatic để xây dựng cây component vững chắc, dễ tiếp cận (accessible) và hiệu năng cao.

## Khi nào kích hoạt

- Viết hoặc chỉnh sửa React function component, custom hook hoặc cây component
- Review file JSX/TSX
- Thiết kế hình dạng state hoặc composition của component
- Migrate class component hoặc code cũ nặng về `forwardRef`/`useEffect`
- Chọn giữa local state, lifted state, context và external store
- Làm việc với Server Component / Client Component (Next.js App Router, RSC)
- Triển khai form bằng React 19 action hoặc controlled input
- Kết nối data fetching bằng TanStack Query / SWR / RSC

## Nguyên tắc cốt lõi

### 1. Render là một hàm thuần của Props và State

```tsx
// Good: derive during render
function Cart({ items }: { items: CartItem[] }) {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return <span>{formatMoney(total)}</span>;
}

// Bad: derived state stored separately
function Cart({ items }: { items: CartItem[] }) {
  const [total, setTotal] = useState(0);
  useEffect(() => {
    setTotal(items.reduce((sum, i) => sum + i.price * i.qty, 0));
  }, [items]);
  return <span>{formatMoney(total)}</span>;
}
```

Derived state trong `useEffect` thêm một chu kỳ render, có thể bị lệch đồng bộ và làm mờ luồng dữ liệu.

### 2. Side Effect nằm ngoài Render

Effect, mutation, lời gọi mạng và subscription nằm trong event handler hoặc `useEffect` — KHÔNG BAO GIỜ nằm trong phần thân render.

### 3. Composition thay vì Inheritance

React không có mô hình kế thừa cho component. Hãy kết hợp bằng `children`, render prop hoặc component prop.

## Kỷ luật dùng Hook

Xem [rules/react/hooks.md](../../rules/react/hooks.md) để biết đầy đủ bộ rule. Điểm nổi bật:

- Chỉ gọi ở top-level, KHÔNG BAO GIỜ gọi có điều kiện
- Cleanup mọi subscription, interval, listener
- Dùng functional updater (`setX(prev => prev + 1)`) khi state mới phụ thuộc state cũ
- Quan điểm mặc định: không memoize — chỉ thêm `useMemo`/`useCallback` khi profiler hoặc một chuỗi dependency chứng minh điều đó cần thiết
- Chỉ tách custom hook khi cùng một chuỗi hook xuất hiện trong từ 2 component trở lên

## Cây quyết định vị trí đặt State

```
Used by one component?
  -> useState inside it

Used by parent + a few descendants?
  -> lift to nearest common ancestor

Used across distant branches AND low-frequency reads (theme, auth, locale)?
  -> React Context

High-frequency updates shared across the tree?
  -> external store (Zustand, Jotai, Redux Toolkit)

Derived from a server?
  -> server-state library (TanStack Query, SWR, RSC fetch)
```

Hầu hết các trang không cần context hay global store. Hãy kìm lại việc trừu tượng hóa cho đến khi việc lift state lặp đi lặp lại trở nên khó chịu.

## Server / Client Component (RSC)

```tsx
// Server Component - default, async, never ships JS for itself
export default async function ProductPage({ params }: { params: { id: string } }) {
  const product = await db.product.findUnique({ where: { id: params.id } });
  if (!product) notFound();
  return <ProductView product={product} />;
}

// Client Component - opt in with "use client"
"use client";
export function AddToCartButton({ productId }: { productId: string }) {
  const [pending, startTransition] = useTransition();
  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => addToCart(productId))}
    >
      {pending ? "Adding..." : "Add to cart"}
    </button>
  );
}
```

Ranh giới:

- Server -> Client: truyền prop có thể serialize hoặc `children`
- Client -> Server: gọi Server Action qua `<form action={...}>` hoặc gọi trực tiếp từ event handler
- KHÔNG BAO GIỜ `import` Server Component từ file Client Component — hãy kết hợp chúng qua `children`

## Suspense + Error Boundary

```tsx
<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<UserSkeleton />}>
    <UserDetail id={id} />
  </Suspense>
</ErrorBoundary>
```

- Đặt Suspense boundary gần dữ liệu, không đặt ở gốc route — hiển thị nội dung dần dần
- Error Boundary vẫn là API dạng class; dùng `react-error-boundary` để có wrapper thân thiện với hook
- Một boundary bắt lỗi được ném ra trong quá trình render, lifecycle và constructor của các con của nó — KHÔNG bắt lỗi trong event handler hoặc code async

## Form

### Form action của React 19 (ưu tiên cho code mới)

```tsx
"use client";
import { useActionState } from "react";

const initial = { error: null as string | null };

async function updateUserAction(_prev: typeof initial, formData: FormData) {
  "use server";
  const parsed = UserSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: "Invalid input" };
  await db.user.update({ where: { id: parsed.data.id }, data: parsed.data });
  return { error: null };
}

export function UserForm() {
  const [state, formAction, pending] = useActionState(updateUserAction, initial);
  return (
    <form action={formAction}>
      <input name="name" required />
      <button type="submit" disabled={pending}>Save</button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

### Controlled input

Dùng controlled khi giá trị điều khiển phần UI khác, định dạng lại sau mỗi lần gõ phím, hoặc cần validation theo thời gian thực.

### Form phức tạp

Với form nhiều bước, field array động hoặc validation chéo giữa các field: hãy dùng thư viện (React Hook Form, TanStack Form). Tự viết quản lý state cho form vượt quá độ phức tạp tầm thường là một cái bẫy về bảo trì.

## Ma trận quyết định Data Fetching

| Nhu cầu | Công cụ |
|---|---|
| Dữ liệu theo từng request trong Next.js App Router | RSC `await fetch()` |
| Cache phía client + mutation + invalidation | TanStack Query |
| Cache nhẹ phía client + revalidation | SWR |
| Subscription thời gian thực | Server-Sent Events, WebSocket, hoặc subscription API của thư viện |
| Gọi một lần, không cần chờ kết quả (fire-and-forget) | `fetch()` trong event handler |

Tránh `useEffect` + `fetch` cho dữ liệu của ứng dụng — dễ gặp race condition, không có cache, không retry, không tích hợp Suspense.

## Công thức Composition

### Slot qua `children`

```tsx
<Layout>
  <Header />
  <Main>{content}</Main>
</Layout>
```

### Named slot

```tsx
<Page header={<Nav />} sidebar={<Filters />}>
  <Results />
</Page>
```

### Compound component (chia sẻ state qua Context)

```tsx
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Panel value="profile"><Profile /></Tabs.Panel>
  <Tabs.Panel value="settings"><Settings /></Tabs.Panel>
</Tabs>
```

### Render prop / function-as-child

Hữu ích khi component cha cần truyền tham số cho phần output được render:

```tsx
<DataLoader id={id}>
  {({ data, isLoading }) => isLoading ? <Spinner /> : <UserCard user={data} />}
</DataLoader>
```

Phương án hiện đại thay thế: một hook (`useData(id)`) trả về cùng cấu trúc — thường gọn hơn.

## Hiệu năng

### Khi nào `React.memo` thực sự có ích

Chỉ bọc component trong `React.memo` khi:

1. Nó re-render thường xuyên
2. Prop của nó thường giống nhau giữa các lần render
3. Việc render của nó tốn kém một cách đo lường được

`React.memo` thêm một lần kiểm tra bằng nhau ở mỗi lần render. Nếu prop khác nhau ở hầu hết các lần render, việc kiểm tra này chỉ là chi phí thừa.

### Tránh Render Cascade

- Ưu tiên đẩy state xuống (lift state down) thay vì đẩy lên khi có thể
- Tách context: mỗi mối quan tâm một context, để thay đổi `themeContext` không làm re-render các consumer của auth
- Dùng `useSyncExternalStore` cho các thư viện external state — bắt buộc để concurrent rendering an toàn

### List

- Cung cấp prop `key` ổn định (id từ database, không dùng index của array)
- Dùng virtualization cho list dài với `@tanstack/react-virtual` hoặc `react-window` khi số item hiển thị vượt ~50 và mỗi dòng không đơn giản

## Composition ưu tiên Accessibility

- LUÔN LUÔN render HTML ngữ nghĩa (`<button>`, `<a>`, `<nav>`, `<main>`) trước khi dùng đến thuộc tính `role`
- Mọi phần tử tương tác đều phải truy cập được bằng bàn phím
- Input của form cần có label — `<label htmlFor>` hoặc `aria-label` nếu được gắn nhãn bằng icon
- Quản lý focus khi đổi route và khi mở/đóng modal
- Chạy `axe` trong component test (xem [skills/react-testing](../react-testing/SKILL.md))
- Liên kết chéo: [skills/accessibility/SKILL.md](../accessibility/SKILL.md) bao gồm các tiêu chí WCAG và thư viện pattern

## Routing

Skill này không phụ thuộc vào router cụ thể. Các pattern ở trên hoạt động với React Router, TanStack Router, Next.js App Router, Remix Router. Các pattern đặc thù của router (loader, action, nested layout) hãy theo tài liệu của router đó — đó là các vấn đề của framework được xếp lớp bên trên React core.

## Ngoài phạm vi (các mục chỉ dẫn)

- **Đặc thù của Next.js**: App Router data loading, Route Handler, Middleware, Parallel Route — là vấn đề riêng, hãy dùng tài liệu Next.js
- **React Native**: Các pattern đặc thù theo nền tảng khác biệt đủ nhiều để cần một skill `react-native-patterns` riêng (chưa có)
- **Remix**: Quy ước loader/action chồng lấn với RSC nhưng hãy theo tài liệu Remix

## Liên quan

- Rules: [rules/react/](../../rules/react/) — coding-style, hooks, patterns, security, testing
- Skills: [react-performance](../react-performance/SKILL.md) cho bộ rule hiệu năng bắt nguồn từ Vercel, [frontend-patterns](../frontend-patterns/SKILL.md) cho các vấn đề UI xuyên framework, [accessibility](../accessibility/SKILL.md), [angular-developer](../angular-developer/SKILL.md) để so sánh framework
- Agents: `react-reviewer` cho code review, `react-build-resolver` cho lỗi build/bundler
- Commands: `/react-review`, `/react-build`, `/react-test`

## Ví dụ

### Custom hook cho tìm kiếm có debounce

```tsx
function useDebounce<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}

function SearchBox() {
  const [query, setQuery] = useState("");
  const debounced = useDebounce(query, 300);
  const { data } = useQuery({
    queryKey: ["search", debounced],
    queryFn: () => searchApi(debounced),
    enabled: debounced.length > 0,
  });
  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <Results items={data ?? []} />
    </>
  );
}
```

### Optimistic UI với `useOptimistic` của React 19

```tsx
"use client";
import { useOptimistic } from "react";

export function MessageList({ messages }: { messages: Message[] }) {
  const [optimistic, addOptimistic] = useOptimistic(
    messages,
    (state, newMessage: Message) => [...state, newMessage],
  );

  async function send(formData: FormData) {
    const text = String(formData.get("text"));
    addOptimistic({ id: "pending", text, sender: "me" });
    await saveMessage(text);
  }

  return (
    <>
      <ul>{optimistic.map((m) => <li key={m.id}>{m.text}</li>)}</ul>
      <form action={send}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </>
  );
}
```

### Tách context để tránh render cascade

```tsx
// Two contexts: one rarely changes, one frequently
const ThemeContext = createContext<Theme>("light");
const NotificationsContext = createContext<Notification[]>([]);

// A component that only consumes ThemeContext does NOT re-render when notifications change
```
