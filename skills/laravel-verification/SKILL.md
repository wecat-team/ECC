---
name: laravel-verification
description: "Vòng lặp verification cho dự án Laravel: kiểm tra env, linting, phân tích tĩnh, test kèm coverage, quét bảo mật và mức độ sẵn sàng deploy. Dùng khi verify một dự án Laravel trước khi merge hoặc deploy — lint, static analysis, test, coverage, security."
metadata:
  origin: ECC
---

# Vòng lặp Verification cho Laravel

Chạy trước PR, sau các thay đổi lớn và trước khi deploy.

## Khi nào dùng

- Trước khi mở pull request cho dự án Laravel
- Sau các lần refactor lớn hoặc nâng cấp dependency
- Verification trước khi deploy lên staging hoặc production
- Chạy toàn bộ pipeline lint -> test -> security -> mức độ sẵn sàng deploy

## Cách hoạt động

- Chạy các phase tuần tự từ kiểm tra môi trường đến mức độ sẵn sàng deploy để mỗi lớp xây dựng trên lớp trước.
- Kiểm tra môi trường và Composer là điều kiện cửa ngõ cho mọi bước còn lại; dừng ngay nếu chúng thất bại.
- Linting/phân tích tĩnh phải sạch trước khi chạy toàn bộ test và coverage.
- Review bảo mật và migration diễn ra sau test để bạn verify hành vi trước các bước liên quan đến dữ liệu hoặc release.
- Mức độ sẵn sàng build/deploy và kiểm tra queue/scheduler là các cổng cuối; bất kỳ lỗi nào cũng chặn release.

## Phase 1: Kiểm tra môi trường

```bash
php -v
composer --version
php artisan --version
```

- Xác minh `.env` tồn tại và có đủ các key bắt buộc
- Xác nhận `APP_DEBUG=false` cho môi trường production
- Xác nhận `APP_ENV` khớp với môi trường deploy đích (`production`, `staging`)

Nếu dùng Laravel Sail ở local:

```bash
./vendor/bin/sail php -v
./vendor/bin/sail artisan --version
```

## Phase 1.5: Composer và Autoload

```bash
composer validate
composer dump-autoload -o
```

## Phase 2: Linting và phân tích tĩnh

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
```

Nếu dự án của bạn dùng Psalm thay cho PHPStan:

```bash
vendor/bin/psalm
```

## Phase 3: Test và Coverage

```bash
php artisan test
```

Coverage (CI):

```bash
XDEBUG_MODE=coverage php artisan test --coverage
```

Ví dụ CI (format -> phân tích tĩnh -> test):

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
```

## Phase 4: Kiểm tra bảo mật và dependency

```bash
composer audit
```

## Phase 5: Database và Migration

```bash
php artisan migrate --pretend
php artisan migrate:status
```

- Review kỹ các migration có tính phá hủy
- Đảm bảo tên file migration theo dạng `Y_m_d_His_*` (ví dụ `2025_03_14_154210_create_orders_table.php`) và mô tả rõ thay đổi
- Đảm bảo có thể rollback
- Kiểm tra các method `down()` và tránh mất dữ liệu không thể khôi phục nếu không có backup rõ ràng

## Phase 6: Mức độ sẵn sàng Build và Deploy

```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

- Đảm bảo cache warmup thành công trong cấu hình production
- Xác minh queue worker và scheduler đã được cấu hình
- Xác nhận `storage/` và `bootstrap/cache/` có quyền ghi trong môi trường đích

## Phase 7: Kiểm tra Queue và Scheduler

```bash
php artisan schedule:list
php artisan queue:failed
```

Nếu dùng Horizon:

```bash
php artisan horizon:status
```

Nếu có `queue:monitor`, hãy dùng nó để kiểm tra backlog mà không xử lý job:

```bash
php artisan queue:monitor default --max=100
```

Verification chủ động (chỉ trên staging): dispatch một job no-op vào queue riêng và chạy một worker đơn để xử lý nó (đảm bảo đã cấu hình queue connection không phải `sync`).

```bash
php artisan tinker --execute="dispatch((new App\\Jobs\\QueueHealthcheck())->onQueue('healthcheck'))"
php artisan queue:work --once --queue=healthcheck
```

Xác minh job tạo ra side effect mong đợi (log entry, dòng trong bảng healthcheck, hoặc metric).

Chỉ chạy bước này trên các môi trường không phải production, nơi việc xử lý một job thử nghiệm là an toàn.

## Ví dụ

Luồng tối thiểu:

```bash
php -v
composer --version
php artisan --version
composer validate
vendor/bin/pint --test
vendor/bin/phpstan analyse
php artisan test
composer audit
php artisan migrate --pretend
php artisan config:cache
php artisan queue:failed
```

Pipeline kiểu CI:

```bash
composer validate
composer dump-autoload -o
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
composer audit
php artisan migrate --pretend
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan schedule:list
```
