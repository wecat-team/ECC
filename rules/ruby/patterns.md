---
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/app/**/*.erb"
  - "**/config/routes.rb"
---
# Pattern Ruby

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung riêng cho Ruby và Rails.

## Rails Way trước tiên

- Bắt đầu với Rails MVC thuần và các quy ước Active Record cho tính năng nhỏ và vừa.
- Đưa vào service object, query object, form object, decorator hoặc presenter khi ranh giới model/controller đang gánh nhiều trách nhiệm.
- Đặt tên các object được tách ra theo thao tác nghiệp vụ mà chúng thực hiện, không đặt theo các tầng chung chung như `Manager` hay `Processor`.

## Lưu trữ dữ liệu (Persistence)

- Ưu tiên PostgreSQL cho app Rails production nhiều host, trừ khi nền tảng hiện có có lý do rõ ràng cho MySQL hoặc SQLite.
- Coi các mặc định dựa trên SQLite của Rails 8 là khả thi cho triển khai một host hoặc quy mô khiêm tốn, không phải lựa chọn tự động phù hợp với các hệ thống nhiều service dùng chung.
- Giữ SQL thô phía sau query object hoặc model scope và tham số hóa mọi giá trị động.

## Background Job và Runtime Service

- Dùng **Solid Queue** cho app Rails 8 greenfield có thông lượng khiêm tốn và nhu cầu triển khai đơn giản.
- Dùng **Sidekiq** khi app cần khả năng quan sát trưởng thành, thông lượng cao, hạ tầng Redis sẵn có, hoặc tính năng Pro/Enterprise.
- Dùng **Solid Cache** và **Solid Cable** khi mô hình triển khai của chúng phù hợp với app; dùng Redis khi cần hành vi chia sẻ giữa các service, fanout cao hoặc cấu trúc dữ liệu nâng cao.

## Frontend

- Ưu tiên **Hotwire** với Turbo, Stimulus, Importmap và Propshaft cho app Rails render phía server.
- Dùng React, Vue, Inertia.js hoặc một SPA riêng khi độ phức tạp tương tác, kiến trúc sản phẩm hiện có hoặc quyền sở hữu của team biện minh cho bề mặt client phát sinh thêm.
- Giữ view component, partial và presenter tập trung vào các quyết định render; giữ persistence và phân quyền ra khỏi template.

## Xác thực (Authentication)

- Dùng generator xác thực của Rails 8 cho nhu cầu session auth và reset mật khẩu đơn giản.
- Dùng Devise hoặc một hệ thống auth đã được kiểm chứng khác khi yêu cầu bao gồm OAuth, MFA, flow confirmable/lockable, auth đa model, hoặc dấu ấn Devise sẵn có lớn.

## Tham chiếu

Xem skill: `backend-patterns` để biết về ranh giới service và pattern adapter.
