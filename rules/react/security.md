---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/app/**/*.ts"
  - "**/pages/**/*.ts"
---
# Bảo mật React

> File này mở rộng [typescript/security.md](../typescript/security.md) và [common/security.md](../common/security.md) với nội dung riêng cho React.

## XSS qua `dangerouslySetInnerHTML`

CRITICAL. Tên prop này cố tình nghe đáng sợ — hãy coi mọi lần sử dụng là điểm dừng bắt buộc trong code review.

```tsx
// CRITICAL: unsanitized user input
<div dangerouslySetInnerHTML={{ __html: userBio }} />

// CORRECT options:
// 1. Render as text
<div>{userBio}</div>

// 2. Render parsed markdown via a library that sanitizes
<ReactMarkdown>{userBio}</ReactMarkdown>

// 3. If raw HTML is required, sanitize first with DOMPurify
import DOMPurify from "isomorphic-dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userBio) }} />
```

Checklist audit cho mỗi lời gọi `dangerouslySetInnerHTML`:

- Đầu vào có luôn nằm dưới sự kiểm soát của chúng ta không? Hãy ghi lại nguồn.
- Nếu có nguồn gốc từ người dùng: nó đã được sanitize **ngay tại vị trí gọi** chưa? (Sanitize ở ranh giới API chỉ chấp nhận được nếu mọi consumer đều được xác minh.)
- Cấu hình sanitizer có dùng allowlist các thẻ thay vì denylist không?

## URL Scheme không an toàn

URL `javascript:` và `data:` trong `href`, `src` và `xlink:href` thực thi code tùy ý.

```tsx
// CRITICAL: javascript: URL injection
<a href={user.website}>Visit</a>   // if user.website = "javascript:alert(1)"

// CORRECT: validate scheme
function safeUrl(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    if (["http:", "https:", "mailto:"].includes(parsed.protocol)) return url;
  } catch {
    return undefined;
  }
  return undefined;
}
<a href={safeUrl(user.website)}>Visit</a>
```

React cảnh báo về URL `javascript:` trong `href` ở chế độ development, nhưng không chặn chúng lúc runtime. URL `data:` và các scheme khác cũng lọt qua. Luôn luôn validate.

## `target="_blank"` không có `rel`

`<a target="_blank">` không có `rel="noopener noreferrer"` cho phép trang đích truy cập `window.opener` và thực hiện chiếm quyền điều hướng.

```tsx
// WRONG
<a href={externalUrl} target="_blank">External</a>

// CORRECT
<a href={externalUrl} target="_blank" rel="noopener noreferrer">External</a>
```

Các trình duyệt hiện đại mặc định áp dụng `noopener` khi `target="_blank"`, nhưng đừng dựa vào mặc định của trình duyệt — hãy khai báo tường minh.

## Kiểm tra đầu vào của Server Action

Server Action (`"use server"`) chạy với cùng mức tin cậy như một endpoint API công khai. Hãy validate mọi đầu vào.

```tsx
"use server";
import { z } from "zod";

const Input = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(120),
});

export async function updateUser(_state: unknown, formData: FormData) {
  const parsed = Input.safeParse({
    email: formData.get("email"),
    age: Number(formData.get("age")),
  });
  if (!parsed.success) return { error: parsed.error.flatten() };
  // ...
}
```

- Xác thực (authenticate) bên trong action — không tin vào cổng chặn route phía client
- Phân quyền (authorize): xác nhận người dùng hiện tại có quyền với đúng bản ghi mà họ đang thay đổi
- Áp dụng rate limit cho các action nhạy cảm

## Lộ secret qua biến môi trường

Các biến môi trường có prefix được đóng gói vào client. Hãy coi chúng là công khai.

| Framework | Prefix công khai | Riêng tư |
|---|---|---|
| Next.js | `NEXT_PUBLIC_*` | Tất cả còn lại |
| Vite | `VITE_*` | `.env` chỉ phía server |
| Create React App | `REACT_APP_*`, cộng với `NODE_ENV` và `PUBLIC_URL` | Tất cả còn lại (mọi thứ không có prefix `REACT_APP_` chỉ ở phía server) |
| Remix | Truy cập `process.env` chỉ trong `loader`/`action` | Như nhau |

```ts
// CRITICAL: secret leaked to client bundle
const apiKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY;
```

Hãy audit ở mọi PR đụng tới biến môi trường: chuỗi này nằm trong bundle công khai thì có vấn đề không?

## Xác thực / Phân quyền

- Không bao giờ lưu session trong `localStorage` — mọi XSS đều truy cập được. Hãy dùng cookie httpOnly secure.
- Không bao giờ tin state do client đặt để chặn UI nhạy cảm. Chặn render trong JSX chỉ ngăn hiển thị, không ngăn truy cập — API phải thực thi việc đó.
- CSRF: xác thực bằng cookie cần CSRF token hoặc cookie `SameSite=Strict`/`Lax`
- Dùng double-submit cookie hoặc xác minh origin cho form action khi không dùng mặc định của framework

## Content Security Policy (CSP)

Cấu hình phía server. CSP tối thiểu chấp nhận được cho một app React:

```
default-src 'self';
script-src 'self' 'nonce-{REQUEST_NONCE}';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
connect-src 'self' https://api.example.com;
frame-ancestors 'none';
```

- Tránh `unsafe-inline` và `unsafe-eval` trong `script-src`
- Với SSR có script inline (streaming của Next.js, dữ liệu hydration), dùng nonce theo từng request — cả Next.js và Remix đều hỗ trợ chèn nonce
- `style-src 'unsafe-inline'` thường khó tránh với các thư viện CSS-in-JS — hãy ghi lại sự đánh đổi này

## Prototype Pollution qua Object Spread

```tsx
// WRONG: untrusted JSON spread directly into state
const update = await req.json();
setState({ ...state, ...update });    // attacker controls __proto__

// CORRECT: parse with a schema, or guard keys
const Allowed = z.object({ name: z.string(), email: z.string().email() });
const parsed = Allowed.parse(await req.json());
setState({ ...state, ...parsed });
```

## SSR Template Injection

Khi dùng `renderToString` hoặc `renderToPipeableStream`:

- Mọi giá trị render bên trong JSX đều được React escape — an toàn
- Giá trị truyền vào `dangerouslySetInnerHTML` KHÔNG được escape — cùng quy tắc như phía client
- Các wrapper HTML dựng thủ công quanh output của React phải được escape hoặc sanitize — không bao giờ nối đầu vào của người dùng vào HTML template bao quanh

## Component bên thứ ba

- Chạy `npm audit` trước khi thêm bất kỳ thư viện UI nào
- Kiểm tra thư viện không dùng `dangerouslySetInnerHTML` nội bộ trên đầu vào của nó (ví dụ rich text editor)
- Ghim (pin) phiên bản, xem changelog trước các lần nâng cấp major
- Cảnh giác với các component nhận chuỗi HTML qua props

## Lộ Source Map ở môi trường production

Bản build production nên được phát hành không có source map, hoặc có sourcemap được upload lên error tracker (Sentry) và gỡ khỏi bundle công khai. Source map công khai làm lộ logic nội bộ và cấu trúc file.

## Hỗ trợ từ Agent

- Dùng agent `security-reviewer` cho các cuộc audit bảo mật toàn diện trên toàn codebase
- Dùng agent `react-reviewer` cho các pattern riêng của React và các quy tắc trên trong code review thực tế
