---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/components/**/*.js"
  - "**/app/**/*.tsx"
  - "**/pages/**/*.tsx"
---
# Pattern React

> File này mở rộng [typescript/patterns.md](../typescript/patterns.md) và [common/patterns.md](../common/patterns.md) với nội dung riêng cho React. Về các quy tắc riêng của hook, xem [hooks.md](./hooks.md).

## Tách Container / Presentational

Container component sở hữu việc fetch dữ liệu, state và side effect. Presentational component nhận props và render — không gọi service, không dùng hook nào ngoài state UI cục bộ.

```tsx
// Container — owns data
export function UserPage({ userId }: { userId: string }) {
  const { data: user, isLoading } = useUser(userId);
  if (isLoading) return <Spinner />;
  if (!user) return <NotFound />;
  return <UserCard user={user} onSelect={handleSelect} />;
}

// Presentational — pure
export function UserCard({ user, onSelect }: { user: User; onSelect: (id: string) => void }) {
  return <button onClick={() => onSelect(user.id)}>{user.name}</button>;
}
```

## Cây quyết định vị trí đặt State

1. Dùng bởi một component → `useState` bên trong nó
2. Dùng bởi cha + vài con → nâng lên (lift) tới tổ tiên chung gần nhất, truyền qua props
3. Dùng ở các nhánh cách xa nhau → React Context **chỉ cho các lần đọc tần suất thấp** (theme, auth, locale)
4. Cập nhật tần suất cao được chia sẻ khắp cây → external store (Zustand, Jotai, Redux Toolkit)
5. Dữ liệu có nguồn gốc từ server → thư viện server-state (TanStack Query, SWR, RSC fetch) — không phải application state

Dùng Context sai cách cho các giá trị thay đổi thường xuyên khiến mọi consumer re-render ở mỗi lần cập nhật.

## Ranh giới Server / Client Component (RSC, Next.js App Router)

- Server Component là mặc định — chúng chạy trên server, không được gửi xuống client, và có thể `await` trực tiếp
- Client Component được bật bằng `"use client"` ở đầu file
- Dữ liệu chảy xuống: Server Component có thể render Client Component và truyền các props serialize được
- Client Component không thể import Server Component, nhưng có thể nhận một Server Component qua `children` hoặc các slot có tên

```tsx
// Server (default)
export default async function Page() {
  const user = await fetchUser();
  return <UserClient user={user} />;
}

// Client
"use client";
export function UserClient({ user }: { user: User }) {
  const [tab, setTab] = useState("profile");
  return <Tabs value={tab} onChange={setTab}>{user.name}</Tabs>;
}
```

- Không bao giờ import các package `"server-only"` (DB client, secret) từ file Client Component — hãy bọc chúng trong Server Component hoặc Server Action
- Đánh dấu các module nhạy cảm bằng `import "server-only"` để bundler báo lỗi nếu file client import chúng

## Suspense + Error Boundary

Mỗi Suspense boundary cần một Error Boundary phía trên nó. Cặp này xử lý cả hai trạng thái.

```tsx
<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<Skeleton />}>
    <UserDetails id={id} />
  </Suspense>
</ErrorBoundary>
```

- Đặt Suspense boundary gần nơi cần dữ liệu, không đặt ở gốc route
- Nhiều boundary hẹp hơn sẽ hiển thị dần nội dung đã tải xong
- Error Boundary phải là Class Component (React 19 chưa có bản tương đương dạng function) HOẶC dùng một wrapper của thư viện như `react-error-boundary`

## Form

### Uncontrolled (React 19 + form action)

Ưu tiên input uncontrolled cùng form action khi form có bước submit rõ ràng. Trình duyệt giữ giá trị; React đọc nó qua `FormData` khi submit.

```tsx
async function action(formData: FormData) {
  "use server";
  await saveUser({ name: String(formData.get("name")) });
}

export function UserForm() {
  return (
    <form action={action}>
      <input name="name" required />
      <button type="submit">Save</button>
    </form>
  );
}
```

### Controlled

Dùng input controlled khi giá trị điều khiển UI khác, cần validate theo thời gian thực, hoặc cần định dạng.

```tsx
const [email, setEmail] = useState("");
return <input value={email} onChange={(e) => setEmail(e.target.value)} />;
```

### Thư viện Form

Với form phức tạp (nhiều bước, mảng field động, validate chéo giữa các field), hãy dùng thư viện:

- React Hook Form — ít re-render nhất, ưu tiên uncontrolled
- TanStack Form — có type, không phụ thuộc framework
- Final Form — khi việc re-render dựa trên subscription quan trọng

## Fetch dữ liệu

| Chiến lược | Khi nào |
|---|---|
| RSC fetch (`await` trong Server Component) | Dữ liệu theo từng request trong Next.js App Router, không cần cache phía client |
| TanStack Query | Cache phía client, mutation, optimistic update, polling |
| SWR | Cache nhẹ + revalidation, đơn giản hơn TanStack Query |
| `fetch` trong `useEffect` | Tránh — có race condition, không cache, không retry. Chỉ chấp nhận cho tác vụ fire-and-forget dùng một lần |

Không bao giờ fetch trong `useEffect` khi đã có thư viện cache thực thụ — chúng xử lý dedupe, vô hiệu hóa cache, retry khi lỗi và tích hợp Suspense.

## Danh sách và Key

- `key` phải ổn định giữa các lần render — không bao giờ dùng `index` cho bất kỳ danh sách nào có thể bị sắp xếp lại, chèn hoặc xóa
- `key` phải duy nhất giữa các phần tử anh em (sibling), không cần duy nhất toàn cục
- Danh sách bị sắp xếp lại khi dùng index làm key khiến state của component con gắn nhầm vào hàng khác

## Composition thay vì Inheritance

- Truyền `children` cho kiểu composition dạng slot
- Truyền hàm render-prop cho việc render có tham số
- Truyền kiểu component cho các điểm plug-in: `renderItem={UserRow}`
- Không bao giờ extend một class component để chuyên biệt hóa hành vi

## Compound Component

Với các control liên quan nhau (Tabs, Accordion, Menu), dùng compound component chia sẻ state qua Context:

```tsx
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Panel value="profile"><ProfileForm /></Tabs.Panel>
  <Tabs.Panel value="settings"><SettingsForm /></Tabs.Panel>
</Tabs>
```

## Portal

Dùng `createPortal` cho modal, tooltip, toast container — mọi thứ phải thoát khỏi `overflow: hidden` hoặc stacking context `z-index` của phần tử cha. Render vào một DOM node ổn định được mount trong `index.html`.

## Ref và Forwarding (React 19+)

React 19 cho phép function component nhận `ref` như một prop thông thường — không còn cần `forwardRef`.

```tsx
export function Input({ ref, ...rest }: { ref?: React.Ref<HTMLInputElement> } & InputProps) {
  return <input ref={ref} {...rest} />;
}
```

Các codebase cũ trên React 18 vẫn cần `forwardRef`.

## Ngoài phạm vi (các mục trỏ tới nơi khác)

### Next.js (App Router)

- Server Action, Route Handler, Middleware, Parallel/Intercepted Route, streaming Metadata
- Được coi là mối quan tâm riêng của framework — khi thêm các pattern chuyên sâu của Next, hãy đề xuất một track riêng `rules/nextjs/`
- Hiện tại hãy theo tài liệu chính thức của Next.js về các chi tiết của App Router

### React Native

- Import theo nền tảng (`Platform.OS`, `.ios.tsx` / `.android.tsx`), `StyleSheet`, các thư viện điều hướng (React Navigation, Expo Router)
- Được coi là một track riêng — `rules/react-native/` chưa có
- Các hook/pattern lõi của React trong file này vẫn áp dụng

## Tham chiếu Skill

Để tìm hiểu sâu về React, xem `skills/react-patterns/SKILL.md`. Với các vấn đề frontend xuyên framework, xem `skills/frontend-patterns/SKILL.md`. Về accessibility, xem `skills/accessibility/SKILL.md`.
