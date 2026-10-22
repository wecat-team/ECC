---
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/Gemfile.lock"
  - "**/config/routes.rb"
---
# Hook Ruby

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung riêng cho Ruby và Rails.

## Hook PostToolUse

Cấu hình các hook cục bộ của dự án để ưu tiên binstub và công cụ đã commit:

- **RuboCop**: chạy `bundle exec rubocop -A <file>` hoặc lệnh formatter an toàn hơn của dự án sau khi sửa Ruby.
- **Brakeman**: chạy `bundle exec brakeman --no-progress` sau các thay đổi Rails nhạy cảm về bảo mật.
- **Tests**: chạy lệnh `bin/rails test ...` hoặc `bundle exec rspec ...` hẹp nhất khớp với các file đã chạm tới.
- **Bundler audit**: chạy `bundle exec bundle-audit check --update` khi `Gemfile` hoặc `Gemfile.lock` thay đổi và dự án đã cài bundler-audit.

## Cảnh báo

- Cảnh báo khi code ứng dụng có lời gọi `debugger`, `binding.irb`, `binding.pry`, `puts`, `pp` hoặc `p` đã commit.
- Cảnh báo khi một thay đổi tắt bảo vệ CSRF, mở rộng mass-assignment, hoặc thêm SQL thô không tham số hóa.
- Cảnh báo khi một migration thay đổi dữ liệu theo cách phá hủy mà không có đường lui (reversible) hoặc kế hoạch rollout được ghi lại.

## Gợi ý CI Gate

```bash
bundle exec rubocop
bundle exec brakeman --no-progress
bin/rails test
bundle exec rspec
```

Chỉ dùng các lệnh có sẵn trong dự án; không cài thêm dependency mới cho hook khi chưa được maintainer chấp thuận.
