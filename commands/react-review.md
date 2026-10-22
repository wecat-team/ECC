---
description: Code review React/JSX toàn diện về tính đúng đắn của hook, hiệu năng render, ranh giới server/client component, accessibility và bảo mật đặc thù React. Gọi agent react-reviewer (và typescript-reviewer song song với các thay đổi TSX/JSX).
---

# React Code Review

Lệnh này gọi agent **react-reviewer** để thực hiện code review đặc thù cho React. Với pull request chạm vào file `.tsx`/`.jsx`, cả `react-reviewer` và `typescript-reviewer` đều nên chạy — mỗi agent phụ trách một mảng riêng.

## Lệnh này làm gì

1. **Xác định thay đổi React**: Tìm các file `.tsx`/`.jsx` đã sửa (và các file `.ts`/`.js` có chứa React) qua `git diff`
2. **Chạy lint**: Thực thi `eslint` với `eslint-plugin-react-hooks` và `eslint-plugin-jsx-a11y`
3. **Typecheck**: Chạy `tsc --noEmit` hoặc lệnh typecheck chuẩn của project
4. **Chỉ review các mảng React**: Quy tắc hook, ranh giới RSC, accessibility, hiệu năng render, bảo mật đặc thù React
5. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng (CRITICAL / HIGH / MEDIUM)

## Khi nào dùng

Dùng `/react-review` khi:

- Một PR hoặc commit chạm vào file `.tsx`/`.jsx`
- Sau khi viết hoặc sửa React component, custom hook hoặc page
- Trước khi merge code React
- Audit accessibility trên các UI component
- Review một hook mới về rules-of-hooks và tính đúng đắn của dependency
- Audit ranh giới server/client component trong Next.js App Router

Với thay đổi `.ts`/`.js` thuần không import React, dùng `/code-review` (chung) hoặc gọi trực tiếp `typescript-reviewer`.

## Phạm vi so với `/code-review` và TypeScript Review

| Công cụ | Phạm vi |
|---|---|
| `react-reviewer` (lệnh này) | Quy tắc hook, JSX, RSC, a11y, bảo mật đặc thù React, hiệu năng render |
| `typescript-reviewer` | TS/JS chung — lạm dụng `any`, tính đúng đắn của async, bảo mật Node |
| `security-reviewer` | Audit bảo mật toàn project |
| `/code-review` | Review chung các thay đổi chưa commit hoặc PR |

Với PR TSX/JSX, hãy gọi cả `react-reviewer` và `typescript-reviewer`. Các phát hiện của mỗi bên được thiết kế để không chồng lấn nhau.

## Các nhóm review

### CRITICAL (Phải sửa)

- `dangerouslySetInnerHTML` với đầu vào chưa được sanitize
- `href`/`src` với URL người dùng chưa được kiểm tra (`javascript:`, `data:`)
- Server Action không có kiểm tra đầu vào
- Secret trong client bundle (`NEXT_PUBLIC_*`, `VITE_*`, `REACT_APP_*`)
- Dùng `localStorage`/`sessionStorage` cho session token
- Gọi hook có điều kiện (vi phạm Rules of Hooks)
- Thay đổi state trực tiếp (direct state mutation)
- Hook được gọi bên ngoài component hoặc custom hook

### HIGH (Nên sửa)

- Thiếu dependency của `useEffect`/`useMemo`/`useCallback` (tắt `exhaustive-deps` mà không có lý do)
- Dùng effect cho derived state
- Effect thiếu cleanup
- Stale closure trong handler/interval
- Import chỉ dành cho server trong Client Component
- Rò rỉ dữ liệu nhạy cảm qua props sang Client Component
- Server Action không kiểm tra auth
- Vi phạm accessibility (thiếu label, phần tử tương tác không semantic, dùng ARIA sai)
- `key={index}` trong danh sách động
- State bị trùng lặp, chuỗi useEffect

### MEDIUM (Cân nhắc)

- Memoize quá mức mà không có lợi ích đo được
- Tạo object/function inline mới làm prop cho child đã memoize
- Suspense chỉ ở root của route (không hiển thị dần)
- Danh sách dài không có virtualization
- Giá trị thay đổi tần suất cao qua `useContext`
- Tự viết validation trong form phức tạp
- Prop drilling quá 3 cấp
- Component dài hơn 200 dòng
- Class component trong code mới

## Các kiểm tra tự động được chạy

```bash
# Lint (required for any meaningful review)
npx eslint . --ext .tsx,.jsx,.ts,.js

# Typecheck (skip cleanly for JS-only projects)
npm run typecheck --if-present
[ -f tsconfig.json ] && tsc --noEmit -p tsconfig.json

# Targeted a11y rules
npx eslint . --rule 'jsx-a11y/alt-text: error' \
              --rule 'jsx-a11y/anchor-is-valid: error' \
              --rule 'jsx-a11y/click-events-have-key-events: error'

# Supply-chain
npm audit
```

Nếu `eslint-plugin-react-hooks` hoặc `eslint-plugin-jsx-a11y` chưa được cấu hình, review sẽ đánh dấu khoảng trống đó là vấn đề cấu hình HIGH và tiếp tục.

## Ví dụ sử dụng

````text
User: /react-review

Agent:
# React Code Review Report

## Files Reviewed
- src/components/UserCard.tsx (modified)
- src/hooks/useUser.ts (new)

## Lint Results
PASS: eslint clean
PASS: typecheck clean

## Issues Found

[CRITICAL] Unsanitized dangerouslySetInnerHTML
File: src/components/UserCard.tsx:42
Issue: User-controlled bio rendered as raw HTML.
Why: XSS via stored script tags in user input.
Fix: Sanitize with DOMPurify or render as text:
```tsx
import DOMPurify from "isomorphic-dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(user.bio) }} />
```

[HIGH] Effect cleanup missing
File: src/hooks/useUser.ts:18
Issue: `fetch` call without AbortController; setState on unmounted component possible.
Fix: Add AbortController and cleanup:
```ts
useEffect(() => {
  const ac = new AbortController();
  fetch(`/api/users/${id}`, { signal: ac.signal })
    .then(r => r.json())
    .then(setUser);
  return () => ac.abort();
}, [id]);
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
````

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|---|---|
| PASS: Approve | Không có vấn đề CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| FAIL: Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các lệnh khác

- Chạy `/react-build` trước nếu build đang hỏng
- Chạy `/react-test` để đảm bảo test của component pass
- Chạy `/react-review` trước khi merge
- Dùng `/code-review` cho các mối quan tâm không đặc thù React trên cùng PR

## Liên quan

- Agent: `agents/react-reviewer.md`
- Agent đồng hành: `agents/typescript-reviewer.md` (chạy song song cho PR TSX/JSX)
- Skills: `skills/react-patterns/`, `skills/react-testing/`, `skills/accessibility/`
- Rules: `rules/react/`
