---
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/Gemfile.lock"
  - "**/config/routes.rb"
  - "**/config/credentials*.yml.enc"
---
# Bảo mật Ruby

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho Ruby và Rails.

## Mặc định của Rails

- Giữ bật bảo vệ CSRF cho các request trình duyệt làm thay đổi trạng thái.
- Dùng strong parameters hoặc các boundary object có type trước khi mass assignment.
- Lưu secret trong Rails credentials, biến môi trường hoặc một secret manager. KHÔNG BAO GIỜ commit key, token, credential riêng tư dạng plaintext hay giá trị `.env` được sao chép.

## SQL và Active Record

- Ưu tiên API truy vấn của Active Record và SQL tham số hóa.
- Không bao giờ nội suy giá trị từ request, cookie, header, job hay webhook vào chuỗi SQL.
- Phạm vi của model callback cần cân nhắc cẩn thận; các side effect nhạy cảm về bảo mật nên tường minh và được test bao phủ.

## Xác thực và Session

- Dùng generator xác thực của Rails 8 cho session auth đơn giản, hoặc Devise khi cần OAuth, MFA, confirmable, lockable, auth đa model, hoặc quy ước Devise sẵn có.
- Xoay vòng (rotate) session sau khi đăng nhập và khi quyền thay đổi.
- Bảo vệ các flow khôi phục tài khoản bằng thời hạn, token dùng một lần, rate limiting và audit logging.

## Dependency

- Chạy kiểm tra dependency khi lockfile thay đổi:

```bash
bundle exec bundle-audit check --update
bundle exec brakeman --no-progress
```

- Review các gem mới về mức độ hoạt động của maintainer, rủi ro native extension, dependency bắc cầu (transitive), và liệu cùng hành vi đó có thể triển khai bằng Rails core hay không.

## An toàn Web

- Escape output của template theo mặc định. Coi `html_safe`, `raw` và các sanitizer tùy chỉnh là code nhạy cảm về bảo mật.
- Validate file upload theo content type, phần mở rộng, kích thước và đích lưu trữ.
- Coi background job, webhook, message Action Cable và đầu vào Turbo Stream là các ranh giới không đáng tin.

## Tham chiếu

Xem skill: `security-review` để biết các pattern review secure-by-default.
