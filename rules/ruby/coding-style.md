---
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/*.gemspec"
  - "**/config.ru"
---
# Coding Style Ruby

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho Ruby và Rails.

## Tiêu chuẩn

- Nhắm tới **Ruby 3.3+** cho công việc Rails mới, trừ khi dự án đã ghim một runtime cũ hơn vẫn được hỗ trợ.
- Chỉ bật **YJIT** ở production sau khi đã đo thời gian khởi động, bộ nhớ và thông lượng request/job.
- Thêm `# frozen_string_literal: true` vào các file Ruby mới khi dự án dùng quy ước này.
- Ưu tiên Ruby rõ ràng hơn metaprogramming khéo léo; cô lập code nặng DSL sau các ranh giới hẹp, có test.

## Định dạng và Linting

- Dùng cấu hình RuboCop đã commit của dự án. Với app Rails 8+, hãy bắt đầu từ `rubocop-rails-omakase` và chỉ tùy chỉnh ở nơi codebase có quy ước thực sự.
- Giữ các lệnh formatter/linter phía sau binstub hoặc script để CI và lần chạy cục bộ giống nhau:

```bash
bundle exec rubocop
bundle exec rubocop -A
```

- Không tắt cop inline trừ khi ngoại lệ đó hẹp, được ghi chú lại, và khó diễn đạt gọn gàng hơn trong code.

## Style Rails

- Tuân theo quy ước đặt tên và thư mục của Rails trước khi thêm cấu trúc tùy chỉnh.
- Giữ controller tập trung vào tầng truyền tải: xác thực, phân quyền, xử lý tham số, hình dạng response.
- Đặt hành vi domain tái sử dụng trong model, concern, service object, query object hoặc form object tùy theo độ phức tạp thực tế, không phải làm nghi thức mặc định.
- Ưu tiên `bin/rails`, `bin/rake` và các binstub đã commit hơn các lệnh cài đặt toàn cục.

## Xử lý lỗi

- Rescue các exception cụ thể. Tránh các khối `rescue StandardError` rộng trừ khi chúng raise lại hoặc giữ đủ context cho người vận hành.
- Dùng `ActiveSupport::Notifications` hoặc logger của app cho các sự kiện vận hành; không để lại `puts`, `pp` hay `debugger` trong code ứng dụng đã commit.

## Tham chiếu

Xem skill: `backend-patterns` để biết hướng dẫn rộng hơn về phân tầng service/repository.
