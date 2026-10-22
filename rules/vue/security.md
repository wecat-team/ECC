---
paths:
  - "**/*.vue"
---

# Bảo mật Vue

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho Vue.

## Những gì Vue tự động escape

- Nội suy văn bản `{{ }}` và binding thuộc tính động (`:title`) được tự động escape. Các vector bên dưới KHÔNG được bảo vệ.

## Quy tắc số 1: Chỉ dùng template từ nguồn tin cậy

- Không bao giờ dùng nội dung không đáng tin làm template của component. Không biên dịch template lúc runtime từ đầu vào của người dùng.
- Không dùng `:is` do người dùng kiểm soát để phân giải component từ một chuỗi tùy ý.

## v-html và Render Function

- `v-html` bỏ qua việc escape và là vector XSS trực tiếp. Tránh dùng nó trên nội dung của người dùng.
- Nếu không tránh được, hãy sanitize bằng DOMPurify (cấu hình allowlist) trước khi bind, hoặc render trong iframe sandbox. Chính Vue khuyến nghị sanitize ở backend trước khi lưu.
- Output của render function và scoped slot mang cùng rủi ro. Truyền HTML của người dùng qua `h()` với `innerHTML` chính là `v-html` dưới một tên khác. Hãy sanitize trước.

## Injection qua URL, Style và Event

- `:href` và `:src` không được escape. URL `javascript:` sẽ thực thi. Hãy validate scheme, chỉ cho phép `http` / `https` / `mailto`. Tài liệu Vue tham chiếu `@braintree/sanitize-url`, nhưng hãy sanitize ở backend trước khi lưu.
- `:style` với đầu vào của người dùng là không an toàn (CSS exfiltration). Dùng cú pháp object với các thuộc tính trong whitelist, không bao giờ dùng chuỗi thô từ người dùng.
- Không bao giờ bind đầu vào của người dùng vào `onclick`, `onfocus` hay bất kỳ thuộc tính event nào.

## Secret trong Client Bundle

- Mọi thứ trong `import.meta.env.VITE_*` đều được gửi tới trình duyệt. Hãy giữ API key và token ở phía server.
- Dùng cookie httpOnly cho session token. Không bao giờ đóng gói credential vào client.

```vue
<!-- unsafe -->
<div v-html="userBio" />
<!-- safe -->
<div v-html="sanitize(userBio)" />
```

## Tham chiếu

- Skill ECC: `frontend-patterns`, `vite-patterns`.
- Tài liệu: <https://vuejs.org/guide/best-practices/security.html> · <https://github.com/cure53/DOMPurify> · <https://github.com/braintree/sanitize-url>
