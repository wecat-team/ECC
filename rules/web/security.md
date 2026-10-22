---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/security.md](../common/security.md) với nội dung bảo mật riêng cho web.

# Quy tắc bảo mật Web

## Content Security Policy

Luôn cấu hình CSP cho production.

### CSP dựa trên Nonce

Dùng nonce theo từng request cho script thay vì `'unsafe-inline'`.

```text
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{RANDOM}' https://cdn.jsdelivr.net;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' data: https:;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://*.example.com;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
```

Hãy điều chỉnh các origin theo dự án. Đừng sao chép máy móc (cargo-cult) khối này mà không chỉnh sửa.

## Ngăn chặn XSS

- Không bao giờ inject HTML chưa được sanitize
- Tránh `innerHTML` / `dangerouslySetInnerHTML` trừ khi đã sanitize trước
- Escape các giá trị động trong template
- Sanitize HTML của người dùng bằng một sanitizer cục bộ đã được kiểm chứng khi thực sự cần thiết

## Script bên thứ ba

- Tải bất đồng bộ
- Dùng SRI khi phục vụ từ CDN
- Audit hằng quý
- Ưu tiên tự host cho các dependency quan trọng khi khả thi

## HTTPS và Header

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Form

- Bảo vệ CSRF cho các form làm thay đổi trạng thái
- Rate limiting trên các endpoint submit
- Validate cả phía client lẫn server
- Ưu tiên honeypot hoặc các biện pháp chống lạm dụng nhẹ nhàng thay vì mặc định dùng CAPTCHA nặng tay
