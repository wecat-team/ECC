---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.interceptor.ts"
---
# Bảo mật Angular

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Angular.

## Phòng chống XSS

Angular tự động sanitize các giá trị được bind. KHÔNG BAO GIỜ bỏ qua sanitizer đối với input do người dùng kiểm soát.

```typescript
// WRONG: Bypasses sanitization — XSS risk
this.safeHtml = this.sanitizer.bypassSecurityTrustHtml(userInput);

// CORRECT: Sanitize explicitly before trusting
this.safeHtml = this.sanitizer.sanitize(SecurityContext.HTML, userInput);
```

- KHÔNG BAO GIỜ dùng các method `bypassSecurityTrust*` khi không có lý do được ghi lại và đã qua review
- Tránh `[innerHTML]` với nội dung không đáng tin — dùng `innerText` hoặc một sanitizing pipe
- KHÔNG BAO GIỜ bind `[href]` vào input của người dùng — Angular không chặn URL `javascript:` trong mọi ngữ cảnh
- KHÔNG BAO GIỜ dựng template string từ dữ liệu người dùng

## Bảo mật HTTP

Chỉ dùng `HttpClient` — không dùng `fetch()` hay `XHR` thuần trừ khi không còn lựa chọn nào khác.

```typescript
// WRONG: Bypasses interceptors (auth headers, error handling, logging)
const res = await fetch('/api/users');

// CORRECT
users$ = this.http.get<User[]>('/api/users');
```

- Gắn token xác thực qua interceptor — KHÔNG BAO GIỜ hardcode trong từng lời gọi service
- Định kiểu và validate response của API — coi dữ liệu bên ngoài là `unknown` tại ranh giới
- KHÔNG BAO GIỜ log các HTTP response có thể chứa token, PII hoặc credential

## Quản lý Secret

```typescript
// WRONG: Hardcoded secret in source
const apiKey = 'sk-live-xxxx';

// CORRECT: Injected via environment
import { environment } from '../environments/environment';
const apiKey = environment.apiKey;
```

- Coi `environment.ts` như một khuôn cấu hình — KHÔNG BAO GIỜ lưu secret thật trong các file environment được đưa vào source control
- Inject secret production qua CI/CD (biến môi trường, secret manager)

## Route Guard

Mọi route cần xác thực hoặc giới hạn theo vai trò PHẢI có guard. KHÔNG BAO GIỜ chỉ dựa vào việc ẩn phần tử UI.

```typescript
{
  path: 'admin',
  canMatch: [authGuard, roleGuard('admin')],
  loadChildren: () => import('./admin/admin.routes'),
}
```

Dùng `canMatch` cho các route nhạy cảm — nó ngăn module của route được tải hoàn toàn đối với người dùng không có quyền.

## Bảo mật SSR

Khi dùng Angular SSR:

- KHÔNG BAO GIỜ để lộ biến môi trường phía server ra client qua `TransferState` trừ khi chúng được chủ ý công khai
- Sanitize mọi input trước khi render phía server — DOM-based XSS cũng có thể xảy ra ở phía server
- Tránh `window`, `document`, `localStorage` trên server — chặn bằng `isPlatformBrowser` hoặc inject qua token `DOCUMENT`

## Content Security Policy

Cấu hình CSP header ở phía server. Tránh `unsafe-inline` trong `script-src`. Khi dùng SSR với inline script, dùng nonce thông qua hỗ trợ CSP của Angular.

## Hỗ trợ từ Agent

- Dùng skill **security-reviewer** cho các cuộc kiểm toán bảo mật toàn diện
