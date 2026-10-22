---
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/test/**/*.rb"
  - "**/spec/**/*.rb"
  - "**/config/routes.rb"
---
# Kiểm thử Ruby

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung riêng cho Ruby và Rails.

## Framework

- Dùng **Minitest** khi app Rails theo test stack mặc định của Rails.
- Dùng **RSpec** khi nó đã được thiết lập trong dự án hoặc team có quy ước production rõ ràng xoay quanh nó.
- Không trộn Minitest và RSpec trong cùng một khu vực tính năng nếu không có lý do migration.

## Kim tự tháp test (Test Pyramid)

- Đặt hành vi domain cần chạy nhanh vào test model, service, query, policy và job.
- Dùng request/controller test cho hợp đồng HTTP, hành vi auth, redirect, status code và hình dạng response.
- Dùng system test với Capybara chỉ cho các flow quan trọng trên trình duyệt; giữ chúng tập trung và ổn định.
- Bao phủ background job bằng unit test cho hành vi và integration test cho hợp đồng queue/enqueue.

## Fixture và Factory

- Dùng Rails fixture khi đó là mặc định của dự án và đồ thị dữ liệu nhỏ.
- Dùng `factory_bot` khi kịch bản cần dựng object tường minh hoặc trait phức tạp.
- Giữ dữ liệu test gần với hành vi đang được assert; tránh fixture toàn cục che giấu chi phí thiết lập.

## Lệnh

Ưu tiên các lệnh cục bộ của dự án:

```bash
bin/rails test
bin/rails test test/models/user_test.rb
bundle exec rspec
bundle exec rspec spec/models/user_spec.rb
```

## Coverage

- Dùng SimpleCov khi coverage được thực thi bắt buộc; giữ ngưỡng trong CI và tránh "lách" branch coverage bằng các test giá trị thấp.
- Thêm regression test cho bug fix trước khi thay đổi code production.

## Tham chiếu

Xem skill: `tdd-workflow` để biết vòng lặp RED -> GREEN -> REFACTOR dùng chung toàn repo.
