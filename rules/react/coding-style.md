---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/components/**/*.js"
  - "**/hooks/**/*.ts"
  - "**/hooks/**/*.js"
---
# Coding Style React

> File này mở rộng [typescript/coding-style.md](../typescript/coding-style.md) và [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho React.

## Phần mở rộng file

- `.tsx` cho mọi file chứa JSX, kể cả đoạn snippet một dòng
- `.ts` cho logic thuần, custom hook không có JSX, định nghĩa type, utility
- `.test.tsx` / `.test.ts` phản chiếu file nguồn
- Chỉ dùng `.jsx` khi dự án chủ ý tránh TypeScript — đánh dấu mọi file React mới không có type trong review

## Đặt tên

- Component: `PascalCase` cho cả symbol lẫn tên file (`UserCard.tsx`, default export `UserCard`)
- Custom hook: `useCamelCase` cho symbol, kebab-case cho tên file khi quy ước của dự án là kebab-case (`use-debounce.ts` export `useDebounce`)
- Context: symbol `<Domain>Context`, provider component `<Domain>Provider`, consumer hook `use<Domain>`
- Event handler: `handleClick`, `handleSubmit` bên trong component; prop nhận handler là `onClick`, `onSubmit`
- Prop boolean: `isLoading`, `hasError`, `canSubmit` — không bao giờ chỉ dùng `loading` hay `error` cho boolean

## Hình dạng component

```tsx
type Props = {
  user: User;
  onSelect: (id: string) => void;
};

export function UserCard({ user, onSelect }: Props) {
  return (
    <button type="button" onClick={() => onSelect(user.id)}>
      {user.name}
    </button>
  );
}
```

- Ưu tiên `type Props = {}` cho các prop shape đóng của component
- Chỉ dùng `interface` khi type của prop được mở rộng qua declaration merging hoặc được export như điểm mở rộng của API công khai
- Luôn destructure props trong danh sách tham số — không truy cập `props.user` bên trong thân hàm
- Để type của giá trị trả về được suy ra ngầm qua JSX (`function Foo(): JSX.Element` chỉ khi hàm trả về có điều kiện và union làm việc suy luận kiểu bị rối)

## JSX

- Self-close các thẻ không có children: `<img />`, `<UserCard user={u} />`
- Dùng fragment `<>...</>` thay vì `<div>` bọc ngoài khi không cần phần tử DOM
- Render có điều kiện: `{condition && <Foo />}` cho boolean, ternary cho trường hợp hoặc-hoặc, early return cho guard clause
- Không bao giờ đặt logic inline trong JSX khi nó dài nhiều dòng — tách ra một const phía trên return hoặc thành một hàm

```tsx
// Nên dùng
const greeting = user.isAdmin ? "Welcome, admin" : `Hello ${user.name}`;
return <h1>{greeting}</h1>;

// Thay vì
return <h1>{user.isAdmin ? "Welcome, admin" : `Hello ${user.name}`}</h1>;
```

## Ranh giới Server / Client (Next.js App Router, RSC)

- Mặc định file mới là Server Component — chỉ thêm `"use client"` khi file dùng state, effect, ref, browser API hoặc event handler
- Đặt directive `"use client"` ở dòng 1, trước mọi import
- Không bao giờ import một file Client Component từ bên trong file action `"use server"`
- Không bao giờ re-export code chỉ dành cho server qua một module client — bundler sẽ âm thầm đưa nó vào bundle

## Import

- Import React trước: `import { useState } from "react"`
- Sau đó là thư viện bên thứ ba, rồi import tuyệt đối của dự án, rồi import tương đối
- Import chỉ có type: `import type { ReactNode } from "react"` — không bao giờ trộn import runtime và import type trong một câu lệnh khi ESLint đã cấu hình `consistent-type-imports`

## Kỷ luật với Hook

Xem [hooks.md](./hooks.md) để biết đầy đủ bộ quy tắc. Các điểm chính về style:

- Custom hook phải bắt đầu bằng `use` — được `eslint-plugin-react-hooks` thực thi
- Gom mọi lời gọi hook ở đầu component, trước mọi logic có điều kiện
- Tránh tạo hook ad-hoc chỉ để bọc một dòng — hãy inline lời gọi

## State

- Ưu tiên local trước (`useState`), chỉ nâng lên (lift) khi cần chia sẻ
- Context dành cho state xuyên suốt được nhiều component đọc (theme, auth, i18n) — không dùng cho cập nhật tần suất cao
- External store (Zustand, Jotai, Redux Toolkit) khi state phải tồn tại qua các lần đổi route, đồng bộ giữa các tab, hoặc cần debug qua devtools
- Không bao giờ nhân đôi state có thể suy ra được — hãy tính toán trong lúc render

## Class Component

Cấm trong code mới. Hãy chuyển class component cũ sang function component khi chạm vào chúng để thay đổi không nhỏ.

## Bố cục file cho mỗi component

```
components/UserCard/
  UserCard.tsx
  UserCard.module.css   # or styled-components, or Tailwind classes inline
  UserCard.test.tsx
  index.ts              # re-export only
```

Component một file inline là chấp nhận được đối với các phần trình bày đơn giản.
