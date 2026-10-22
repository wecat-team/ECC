---
name: react-performance
description: Các pattern tối ưu hiệu năng cho React và Next.js, phỏng theo React Best Practices của Vercel Engineering (https://github.com/vercel-labs/agent-skills). Tổ chức hơn 70 rule thành 8 nhóm ưu tiên — waterfall, bundle size, server-side, client fetching, re-render, rendering, JS micro-perf, advanced. Dùng khi viết, review hoặc refactor code React/Next.js về mặt hiệu năng (performance).
metadata:
  origin: ECC
---

# Hiệu năng React

Các pattern tối ưu hiệu năng cho React 18/19 và Next.js, phỏng theo [Vercel Labs `react-best-practices`](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices) (MIT, v1.0.0). Skill này tổ chức các rule theo mức ưu tiên và cung cấp hướng dẫn dạng cây quyết định cho việc code review và refactor chủ động.

## Khi nào kích hoạt

- Viết hoặc review code React/Next.js về hiệu năng
- Chẩn đoán trang tải chậm, tương tác chậm hoặc CPU cao ở phía client
- Audit bundle size hoặc các regression về Lighthouse Core Web Vitals
- Loại bỏ waterfall trong Server Component / API route
- Giảm re-render phía client
- Tối ưu list dài, animation hoặc hydration
- Audit các lựa chọn tối ưu trong PR đụng đến `app/`, `pages/`, `components/` hoặc data layer

## Chỉ mục ưu tiên

| Ưu tiên | Nhóm | Tiền tố | Khi nào quan trọng |
|---|---|---|---|
| 1 — CRITICAL | Loại bỏ Waterfall | `async-` | Bất cứ khi nào một `await` được theo sau bởi một `await` độc lập |
| 2 — CRITICAL | Tối ưu Bundle Size | `bundle-` | JS tải lần đầu, import ở cấp route, thư viện bên thứ ba |
| 3 — HIGH | Hiệu năng phía Server | `server-` | RSC, Server Action, API route, SSR |
| 4 — MEDIUM-HIGH | Data Fetching phía Client | `client-` | SWR / TanStack Query / `fetch` thuần trong hook |
| 5 — MEDIUM | Tối ưu Re-render | `rerender-` | Cập nhật state tần suất cao, lan truyền từ cha xuống con |
| 6 — MEDIUM | Hiệu năng Rendering | `rendering-` | List dài, animation, hydration |
| 7 — LOW-MEDIUM | Hiệu năng JavaScript | `js-` | Vòng lặp nóng (hot loop), cấp phát bộ nhớ thường xuyên |
| 8 — LOW | Pattern nâng cao | `advanced-` | Tích hợp effect-event, ref ổn định |

## 1. Loại bỏ Waterfall (CRITICAL)

> "Waterfall là kẻ giết hiệu năng số 1" — mỗi `await` tuần tự cộng thêm đầy đủ độ trễ mạng.

### Kiểm tra điều kiện rẻ trước await

Kiểm tra các điều kiện đồng bộ (props, env, flag cố định) trước khi await dữ liệu từ xa.

```ts
// INCORRECT
async function Page({ id }: { id: string }) {
  const flag = await getFlag("show-page");
  if (!flag || !id) return null;
  const data = await getData(id);
  // ...
}

// CORRECT — short-circuit on cheap sync condition first
async function Page({ id }: { id: string }) {
  if (!id) return null;
  const flag = await getFlag("show-page");
  if (!flag) return null;
  const data = await getData(id);
}
```

### Trì hoãn await cho đến khi cần dùng

Chuyển `await` vào nhánh thực sự dùng đến nó.

```ts
// INCORRECT — awaits before deciding it needs the data
const user = await getUser(id);
if (mode === "guest") return renderGuest();
return renderUser(user);

// CORRECT
if (mode === "guest") return renderGuest();
const user = await getUser(id);
return renderUser(user);
```

### Promise.all cho các công việc độc lập

```ts
// INCORRECT — sequential
const user = await getUser(id);
const posts = await getPosts(id);
const followers = await getFollowers(id);

// CORRECT — parallel
const [user, posts, followers] = await Promise.all([
  getUser(id),
  getPosts(id),
  getFollowers(id),
]);
```

### Phụ thuộc một phần — khởi chạy sớm, await muộn

```ts
// CORRECT — kick off all promises, await only when each result is needed
const userP = getUser(id);
const postsP = getPosts(id);
const profile = await getProfile(id);
if (profile.private) return null;
const [user, posts] = await Promise.all([userP, postsP]);
```

### Suspense cho streaming

Đặt các boundary `<Suspense>` gần dữ liệu để trang vẽ được phần có thể vẽ trong khi các cây con chậm hơn được stream về. Đánh đổi: layout shift khi nội dung đến — hãy dành sẵn chỗ (skeleton hoặc `min-height`).

### Server Component: song song thông qua composition

```tsx
// INCORRECT — sibling awaits run sequentially inside one component
export default async function Page() {
  const user = await getUser();
  const cart = await getCart();
  return <View user={user} cart={cart} />;
}

// CORRECT — split into children, React runs them in parallel
export default async function Page() {
  return (
    <View>
      <UserSection />
      <CartSection />
    </View>
  );
}
```

## 2. Tối ưu Bundle Size (CRITICAL)

### Import trực tiếp, không dùng barrel

Các file barrel `index.ts` buộc bundler phải duyệt toàn bộ module graph ngay cả khi tree-shaking loại bỏ phần lớn. Import trực tiếp tiết kiệm 200-800ms JS tải lần đầu trong nhiều ứng dụng thực tế.

```ts
// INCORRECT
import { Button, Card, Modal } from "@/components";

// CORRECT
import { Button } from "@/components/Button";
import { Card } from "@/components/Card";
import { Modal } from "@/components/Modal";
```

Next.js 13.5+ có [Optimize Package Imports](https://nextjs.org/docs/app/api-reference/next-config-js/optimizePackageImports) tự động hóa việc này cho các package trong danh sách — hãy dùng nó; với các thư viện không có trong danh sách vẫn cần import trực tiếp thủ công.

### Đường dẫn có thể phân tích tĩnh

```ts
// INCORRECT — defeats bundler/trace analysis
const mod = await import(`./pages/${name}`);

// CORRECT — explicit per branch
const mod = name === "home" ? await import("./pages/home") : await import("./pages/about");
```

### Dynamic import cho component nặng

```tsx
import dynamic from "next/dynamic";

const HeavyChart = dynamic(() => import("./HeavyChart"), {
  loading: () => <Skeleton />,
  ssr: false, // when client-only
});
```

### Trì hoãn script của bên thứ ba

Tải analytics, logging, widget hỗ trợ SAU khi hydration. Dùng `next/script` với `strategy="afterInteractive"` (mặc định) hoặc `"lazyOnload"`.

### Tải module có điều kiện

```tsx
if (user.role === "admin") {
  const { AdminPanel } = await import("./admin/AdminPanel");
  // ...
}
```

### Preload khi hover/focus

Kích hoạt `<link rel="preload">` hoặc `import()` khi hover để bundle đã nằm trong cache vào lúc người dùng click.

## 3. Hiệu năng phía Server (HIGH)

### Xác thực Server Action như API route

Mọi hàm `"use server"` đều là một endpoint công khai. Hãy authenticate VÀ authorize bên trong action — KHÔNG BAO GIỜ dựa vào việc chặn truy cập của Client Component gọi nó.

```ts
"use server";
export async function deleteUser(formData: FormData) {
  const session = await getSession();
  if (!session?.user) throw new Error("Unauthorized");
  const targetId = String(formData.get("id"));
  if (session.user.role !== "admin" && session.user.id !== targetId) {
    throw new Error("Forbidden");
  }
  await db.user.delete({ where: { id: targetId } });
}
```

### `React.cache()` để loại trùng lặp theo từng request

```ts
import { cache } from "react";

export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});
```

`React.cache` loại trùng lặp trong phạm vi một request. Gọi `getUser("1")` từ ba Server Component trong cùng một lần render = một DB query.

### LRU cache cho dữ liệu dùng chung giữa các request

Với dữ liệu KHÔNG thay đổi theo từng request (config, bảng tra cứu), hãy cache bên ngoài React bằng LRU cache hoặc `unstable_cache`.

### Tránh serialize trùng lặp trong prop của RSC

Khi một Server Component render cùng một dữ liệu vào nhiều Client Component, dữ liệu sẽ được serialize một lần cho mỗi consumer. Hãy nâng Client Component lên và truyền children.

### Đưa I/O tĩnh lên module scope

```ts
// CORRECT — runs once at module load
const fontData = readFileSync(fontPath);

export async function Page() {
  return <Banner font={fontData} />;
}
```

### Không dùng state mutable ở cấp module trong RSC/SSR

State ở cấp module trên server được chia sẻ giữa mọi request — gây race condition giữa các người dùng. Thay vào đó hãy dùng storage theo phạm vi request (`headers()`, `cookies()`, async context).

### Giảm thiểu dữ liệu truyền cho Client Component

Chỉ serialize những gì Client cần. Loại bỏ field thừa, phân trang, chỉ chọn các cột cần thiết (project) ở tầng DB.

### Song song hóa các fetch lồng nhau bằng Promise.all cho từng item

```ts
const users = await getUsers();
const enriched = await Promise.all(
  users.map(async (u) => ({ ...u, posts: await getPostsFor(u.id) })),
);
```

### Dùng `after()` cho công việc không chặn

`after()` của Next.js 15 chạy công việc sau khi response đã được gửi — logging, làm nóng cache (cache warming), analytics.

```ts
import { after } from "next/server";
export async function GET() {
  const data = await getData();
  after(() => logAnalytics(data));
  return Response.json(data);
}
```

## 4. Data Fetching phía Client (MEDIUM-HIGH)

### SWR / TanStack Query để loại trùng lặp

Nhiều component gọi `useUser(id)` nên dùng chung một network request và một cache entry. Hãy dùng SWR hoặc TanStack Query — KHÔNG BAO GIỜ tự viết `useEffect` + `fetch` cho dữ liệu dùng chung.

### Loại trùng lặp global event listener

```tsx
// INCORRECT — every component adds its own
useEffect(() => {
  window.addEventListener("scroll", handler);
  return () => window.removeEventListener("scroll", handler);
}, []);

// CORRECT — single shared listener via a hook + global subject
const useScroll = createScrollHook(); // singleton subject under the hood
```

### Passive listener cho scroll

```ts
window.addEventListener("scroll", handler, { passive: true });
```

Cải thiện độ mượt khi cuộn; listener không thể gọi `preventDefault()`.

### localStorage: đánh version + tối giản

- LUÔN LUÔN lưu một field `version`; tăng version khi schema thay đổi và migrate hoặc bỏ dữ liệu cũ
- Giữ payload nhỏ — `localStorage` là đồng bộ và chặn main thread

## 5. Tối ưu Re-render (MEDIUM)

### Không subscribe state chỉ dùng trong callback

```tsx
// INCORRECT — re-renders every time count changes
const count = useStore((s) => s.count);
const handler = () => doSomething(count);

// CORRECT — read once on call
const handler = () => {
  const count = useStore.getState().count;
  doSomething(count);
};
```

### Tách công việc tốn kém vào component được memoize

```tsx
// CORRECT — child re-renders only when `items` changes
const Heavy = memo(function Heavy({ items }: { items: Item[] }) {
  return <Chart data={transform(items)} />;
});
```

### Đưa các prop mặc định không phải primitive ra ngoài

```tsx
// INCORRECT — new array each render breaks memo
<List items={items ?? []} />

// CORRECT
const EMPTY: Item[] = [];
<List items={items ?? EMPTY} />
```

### Dependency kiểu primitive trong effect

```tsx
// INCORRECT — new object identity every render
useEffect(() => {}, [{ id, name }]);

// CORRECT — primitives
useEffect(() => {}, [id, name]);
```

### Subscribe vào boolean dẫn xuất, không subscribe giá trị thô

```tsx
// INCORRECT — re-renders for any cart change
const cart = useStore((s) => s.cart);
const hasItems = cart.length > 0;

// CORRECT — re-renders only when emptiness flips
const hasItems = useStore((s) => s.cart.length > 0);
```

### Tính toán dẫn xuất trong lúc render, KHÔNG BAO GIỜ qua `useEffect`

```tsx
// INCORRECT
const [full, setFull] = useState("");
useEffect(() => setFull(`${first} ${last}`), [first, last]);

// CORRECT
const full = `${first} ${last}`;
```

### `setState` dạng hàm cho callback ổn định

```tsx
// CORRECT
const increment = useCallback(() => setCount((c) => c + 1), []);
```

### Lazy state initializer cho giá trị tốn kém

```tsx
const [tree] = useState(() => parseTree(largeInput));
```

### Tránh memo cho primitive đơn giản

`useMemo(() => x + 1, [x])` chỉ là chi phí thừa. Memo chỉ có giá trị với danh tính object (identity) và tính toán tốn kém.

### Tách hook có dependency độc lập

```tsx
// INCORRECT — both selectors re-run if either source changes
const { a, b } = useSomething(source1, source2);

// CORRECT
const a = useA(source1);
const b = useB(source2);
```

### Chuyển logic tương tác vào event handler

Event handler chỉ chạy khi người dùng thao tác — `useEffect` chạy lại mỗi khi dependency thay đổi.

### `startTransition` cho cập nhật không khẩn cấp

```tsx
const [pending, startTransition] = useTransition();
startTransition(() => setFilters(newFilters));
```

### `useDeferredValue` cho render tốn kém

```tsx
const deferredQuery = useDeferredValue(query);
const results = useMemo(() => expensiveSearch(deferredQuery), [deferredQuery]);
```

### `useRef` cho giá trị tạm thời thay đổi thường xuyên

Dành cho các giá trị thay đổi thường xuyên nhưng không nên kích hoạt re-render (timestamp, phím cuối cùng, biến tích lũy).

### Không định nghĩa component bên trong component

```tsx
// INCORRECT — Inner is a new component on every Outer render
function Outer() {
  const Inner = () => <span />;
  return <Inner />;
}
```

Mỗi lần render tạo ra một type `Inner` mới, phá vỡ reconciliation và unmount các con.

## 6. Hiệu năng Rendering (MEDIUM)

### Animate wrapper, không animate SVG

Transform một wrapper `<div>` bao quanh SVG được tăng tốc bằng GPU; transform chính SVG sẽ kích hoạt paint.

### `content-visibility: auto` cho list dài

```css
.row { content-visibility: auto; contain-intrinsic-size: auto 80px; }
```

Trình duyệt bỏ qua việc render phần ngoài màn hình — lợi ích lớn cho list có hàng trăm dòng.

### Đưa JSX tĩnh ra ngoài

```tsx
const STATIC_HEADER = <h1>Title</h1>;
function Page() {
  return <>{STATIC_HEADER}<Body /></>;
}
```

### SVG: giảm độ chính xác của tọa độ

`d="M10.123456,20.654321"` → `d="M10.12,20.65"`. Mỗi chữ số tốn thêm byte; khác biệt thị giác chỉ ở mức dưới pixel.

### Hydration không nhấp nháy bằng inline script

Với các giá trị cần có trước hydration (theme, locale), hãy inline một `<script>` đặt `document.documentElement.dataset.*` trước khi React mount.

### Chỉ chặn các hydration mismatch đã dự kiến trong phạm vi hẹp

```tsx
<time suppressHydrationWarning>{new Date().toLocaleString()}</time>
```

CHỈ dùng cho các node lá đã biết là sẽ khác nhau — KHÔNG BAO GIỜ dùng trên cây có chứa các con khác.

### `<Activity>` để hiện/ẩn thay vì mount/unmount

`<Activity mode="visible|hidden">` của React 19 giữ state của cây và effect ở trạng thái mounted nhưng ẩn đi — rẻ hơn unmount/remount cho tab và accordion.

### Dùng ternary thay vì `&&` khi render có điều kiện

```tsx
// INCORRECT — `0` renders as text node
{count && <Badge>{count}</Badge>}

// CORRECT
{count > 0 ? <Badge>{count}</Badge> : null}
```

### `useTransition` cho trạng thái loading

Kết hợp `startTransition` với action; React giữ hiển thị UI trước đó với `isPending` trong khi state tiếp theo đang được tính.

### Resource hint của React DOM

```tsx
import { preload, preconnect } from "react-dom";
preload("/api/critical", { as: "fetch" });
preconnect("https://api.example.com");
```

### `defer` / `async` trên thẻ `<script>`

`defer` để thực thi theo thứ tự sau DOMContentLoaded; `async` cho kiểu fire-and-forget.

## 7. Hiệu năng JavaScript (LOW-MEDIUM)

- **Gộp thay đổi DOM/CSS theo lô (batch)** — áp dụng bằng cách đổi class hoặc `cssText`, không đổi từng property một
- **Dùng `Map` cho các lần tra cứu lặp lại** — `O(1)` so với quét tuyến tính `O(n)`
- **Cache việc truy cập property trong vòng lặp** — `const len = arr.length`
- **Memoize các hàm thuần** — `Map<key, result>` ở cấp module
- **Cache các lần đọc `localStorage`** — API đồng bộ; mỗi lần render chỉ đọc một lần
- **Gộp `filter().map()` thành một lượt duyệt** — `flatMap` hoặc một vòng `for`
- **Kiểm tra độ dài array trước** khi so sánh tốn kém
- **Early return** trong hàm
- **Đưa RegExp ra ngoài vòng lặp** — việc biên dịch không miễn phí
- **Dùng vòng lặp để tìm min/max** thay vì `sort()` — `O(n)` so với `O(n log n)`
- **Dùng `Set`/`Map` để kiểm tra membership** — `O(1)` so với `Array.includes` `O(n)`
- **Dùng `toSorted()` thay vì thay đổi trực tiếp (mutation)** khi tính bất biến (immutability) quan trọng
- **`flatMap` để map và filter trong một lượt duyệt**
- **`requestIdleCallback`** cho công việc không quan trọng

## 8. Pattern nâng cao (LOW)

### Dependency của `useEffectEvent`

Các giá trị từ `useEffectEvent` là ổn định — KHÔNG thêm chúng vào dependency của effect.

### Ref cho event handler

Cho các callback ổn định được truyền xuống con đã memoize:

```tsx
const handlerRef = useRef(handler);
useEffect(() => { handlerRef.current = handler; });
const stable = useCallback((arg) => handlerRef.current(arg), []);
```

### Khởi tạo một lần cho mỗi lần tải app

Với các singleton ở cấp module (telemetry, logger), hãy bảo vệ bằng một flag ở module scope — không dùng `useEffect`.

### `useLatest` cho ref callback ổn định

```tsx
function useLatest<T>(value: T) {
  const ref = useRef(value);
  ref.current = value;
  return ref;
}
```

## Công cụ tự động

Nhiều rule trong số này hiện đã được tự động hóa:

- **Next.js 13.5+ Optimize Package Imports** — tối ưu barrel import
- **React Compiler** (RFC, ở bản canary) — tự động memoize
- **Turbopack** — build nhanh hơn, tree-shaking tốt hơn
- **Bundle Analyzer** (`@next/bundle-analyzer`) — trực quan hóa JS tải lần đầu

Khi dự án đã dùng React Compiler, hãy hạ các rule memoize thủ công `rerender-*` xuống mức "chỉ review" — compiler đã xử lý chúng. `useMemo`/`useCallback` thủ công trở thành nhiễu không cần thiết.

## Ánh xạ Lighthouse / Web Vitals

| Metric | Các nhóm liên quan nhất |
|---|---|
| **LCP** (Largest Contentful Paint) | Waterfall, Bundle Size, Resource Hint |
| **INP** (Interaction to Next Paint) | Re-render, Rendering, JavaScript |
| **CLS** (Cumulative Layout Shift) | Rendering (vị trí đặt Suspense, kích thước ảnh) |
| **TBT** (Total Blocking Time) | Bundle Size, JavaScript, Trì hoãn script bên thứ ba |
| **FID** (cũ) | Bundle Size, Hydration |

## Liên quan

- Skills: [react-patterns](../react-patterns/SKILL.md), [react-testing](../react-testing/SKILL.md), [frontend-patterns](../frontend-patterns/SKILL.md), [accessibility](../accessibility/SKILL.md), [nextjs-turbopack](../nextjs-turbopack/SKILL.md)
- Rules: [rules/react/](../../rules/react/)
- Agents: `react-reviewer` áp dụng các rule này trong code review; `react-build-resolver` xử lý các lỗi build liên quan
- Commands: `/react-review`, `/react-build`, `/react-test`

## Ghi công

Phỏng theo skill `react-best-practices` của Vercel Labs (MIT License, bản quyền Vercel Engineering, v1.0.0 tháng 1/2026). Nguồn: [https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices).

Skill này cấu trúc lại và điều chỉnh bộ danh mục 70 rule gốc thành một tài liệu tham khảo duy nhất, dễ điều hướng. Để xem bộ rule gốc đầy đủ kèm ví dụ mở rộng, hãy xem repo upstream.
