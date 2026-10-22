---
name: django-verification
description: "Chạy toàn bộ vòng lặp verification cho Django — kiểm tra môi trường, linting mypy/ruff/black, an toàn migration, pytest với mục tiêu coverage, quét bảo mật pip-audit và bandit, review settings và logging, review diff — tạo báo cáo pass/fail theo từng giai đoạn trước khi release hoặc tạo PR. Dùng khi chuẩn bị pull request Django, xác thực migration hoặc coverage, hoặc chạy kiểm tra mức sẵn sàng trước khi deploy."
metadata:
  origin: ECC
---

# Vòng lặp Verification cho Django

Chạy trước PR, sau các thay đổi lớn và trước khi deploy để đảm bảo chất lượng và bảo mật của ứng dụng Django.

## Khi nào kích hoạt

- Trước khi mở pull request cho dự án Django
- Sau khi thay đổi model lớn, cập nhật migration hoặc nâng cấp dependency
- Verification trước khi deploy lên staging hoặc production
- Chạy toàn bộ pipeline môi trường → lint → test → bảo mật → mức sẵn sàng deploy
- Xác thực độ an toàn của migration và test coverage

## Giai đoạn 1: Kiểm tra môi trường

```bash
# Verify Python version
python --version  # Should match project requirements

# Check virtual environment
which python
pip list --outdated

# Verify environment variables
python -c "import os; import environ; print('DJANGO_SECRET_KEY set' if os.environ.get('DJANGO_SECRET_KEY') else 'MISSING: DJANGO_SECRET_KEY')"
```

Nếu môi trường được cấu hình sai, hãy dừng lại và sửa.

## Giai đoạn 2: Chất lượng code & Định dạng

```bash
# Type checking
mypy . --config-file pyproject.toml

# Linting with ruff
ruff check . --fix

# Formatting with black
black . --check
black .  # Auto-fix

# Import sorting
isort . --check-only
isort .  # Auto-fix

# Django-specific checks
python manage.py check --deploy
```

Các vấn đề thường gặp:
- Thiếu type hint trên các hàm public
- Vi phạm định dạng PEP 8
- Import chưa được sắp xếp
- Cấu hình debug bị để lại trong cấu hình production

## Giai đoạn 3: Migration

```bash
# Check for unapplied migrations
python manage.py showmigrations

# Create missing migrations
python manage.py makemigrations --check

# Dry-run migration application
python manage.py migrate --plan

# Apply migrations (test environment)
python manage.py migrate

# Check for migration conflicts
python manage.py makemigrations --merge  # Only if conflicts exist
```

Báo cáo:
- Số lượng migration đang chờ
- Bất kỳ xung đột migration nào
- Thay đổi model không có migration

## Giai đoạn 4: Test + Coverage

```bash
# Run all tests with pytest
pytest --cov=apps --cov-report=html --cov-report=term-missing --reuse-db

# Run specific app tests
pytest apps/users/tests/

# Run with markers
pytest -m "not slow"  # Skip slow tests
pytest -m integration  # Only integration tests

# Coverage report
open htmlcov/index.html
```

Báo cáo:
- Tổng số test: X passed, Y failed, Z skipped
- Coverage tổng thể: XX%
- Chi tiết coverage theo từng app

Mục tiêu coverage:

| Thành phần | Mục tiêu |
|-----------|--------|
| Models | 90%+ |
| Serializers | 85%+ |
| Views | 80%+ |
| Services | 90%+ |
| Tổng thể | 80%+ |

## Giai đoạn 5: Quét bảo mật

```bash
# Dependency vulnerabilities
pip-audit
safety check --full-report

# Django security checks
python manage.py check --deploy

# Bandit security linter
bandit -r . -f json -o bandit-report.json

# Secret scanning (if gitleaks is installed)
gitleaks detect --source . --verbose

# Environment variable check
python -c "from django.core.exceptions import ImproperlyConfigured; from django.conf import settings; settings.DEBUG"
```

Báo cáo:
- Các dependency có lỗ hổng được phát hiện
- Vấn đề cấu hình bảo mật
- Secret bị hardcode được phát hiện
- Trạng thái chế độ DEBUG (phải là False trên production)

## Giai đoạn 6: Django Management Command

```bash
# Check for model issues
python manage.py check

# Collect static files
python manage.py collectstatic --noinput --clear

# Create superuser (if needed for tests)
echo "from apps.users.models import User; User.objects.create_superuser('admin@example.com', 'admin')" | python manage.py shell

# Database integrity
python manage.py check --database default

# Cache verification (if using Redis)
python -c "from django.core.cache import cache; cache.set('test', 'value', 10); print(cache.get('test'))"
```

## Giai đoạn 7: Kiểm tra hiệu năng

```bash
# Django Debug Toolbar output (check for N+1 queries)
# Run in dev mode with DEBUG=True and access a page
# Look for duplicate queries in SQL panel

# Query count analysis
django-admin debugsqlshell  # If django-debug-sqlshell installed

# Check for missing indexes
python manage.py shell << EOF
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SELECT table_name, index_name FROM information_schema.statistics WHERE table_schema = 'public'")
    print(cursor.fetchall())
EOF
```

Báo cáo:
- Số truy vấn trên mỗi trang (nên < 50 với trang thông thường)
- Thiếu index database
- Phát hiện truy vấn trùng lặp

## Giai đoạn 8: Static Asset

```bash
# Check for npm dependencies (if using npm)
npm audit
npm audit fix

# Build static files (if using webpack/vite)
npm run build

# Verify static files
ls -la staticfiles/
python manage.py findstatic css/style.css
```

## Giai đoạn 9: Review cấu hình

```python
# Run in Python shell to verify settings
python manage.py shell << EOF
from django.conf import settings
import os

# Critical checks
checks = {
    'DEBUG is False': not settings.DEBUG,
    'SECRET_KEY set': bool(settings.SECRET_KEY and len(settings.SECRET_KEY) > 30),
    'ALLOWED_HOSTS set': len(settings.ALLOWED_HOSTS) > 0,
    'HTTPS enabled': getattr(settings, 'SECURE_SSL_REDIRECT', False),
    'HSTS enabled': getattr(settings, 'SECURE_HSTS_SECONDS', 0) > 0,
    'Database configured': settings.DATABASES['default']['ENGINE'] != 'django.db.backends.sqlite3',
}

for check, result in checks.items():
    status = '✓' if result else '✗'
    print(f"{status} {check}")
EOF
```

## Giai đoạn 10: Cấu hình Logging

```bash
# Test logging output
python manage.py shell << EOF
import logging
logger = logging.getLogger('django')
logger.warning('Test warning message')
logger.error('Test error message')
EOF

# Check log files (if configured)
tail -f /var/log/django/django.log
```

## Giai đoạn 11: Tài liệu API (nếu dùng DRF)

```bash
# Generate schema
python manage.py generateschema --format openapi-json > schema.json

# Validate schema
# Check if schema.json is valid JSON
python -c "import json; json.load(open('schema.json'))"

# Access Swagger UI (if using drf-yasg)
# Visit http://localhost:8000/swagger/ in browser
```

## Giai đoạn 12: Review Diff

```bash
# Show diff statistics
git diff --stat

# Show actual changes
git diff

# Show changed files
git diff --name-only

# Check for common issues
git diff | grep -i "todo\|fixme\|hack\|xxx"
git diff | grep "print("  # Debug statements
git diff | grep "DEBUG = True"  # Debug mode
git diff | grep "import pdb"  # Debugger
```

Checklist:
- Không có câu lệnh debug (print, pdb, breakpoint())
- Không có comment TODO/FIXME trong code quan trọng
- Không có secret hay credential bị hardcode
- Có kèm database migration cho các thay đổi model
- Các thay đổi cấu hình được ghi tài liệu
- Có xử lý lỗi cho các lời gọi bên ngoài
- Có quản lý transaction ở nơi cần thiết

## Mẫu đầu ra

```
DJANGO VERIFICATION REPORT
==========================

Phase 1: Environment Check
  ✓ Python 3.11.5
  ✓ Virtual environment active
  ✓ All environment variables set

Phase 2: Code Quality
  ✓ mypy: No type errors
  ✗ ruff: 3 issues found (auto-fixed)
  ✓ black: No formatting issues
  ✓ isort: Imports properly sorted
  ✓ manage.py check: No issues

Phase 3: Migrations
  ✓ No unapplied migrations
  ✓ No migration conflicts
  ✓ All models have migrations

Phase 4: Tests + Coverage
  Tests: 247 passed, 0 failed, 5 skipped
  Coverage:
    Overall: 87%
    users: 92%
    products: 89%
    orders: 85%
    payments: 91%

Phase 5: Security Scan
  ✗ pip-audit: 2 vulnerabilities found (fix required)
  ✓ safety check: No issues
  ✓ bandit: No security issues
  ✓ No secrets detected
  ✓ DEBUG = False

Phase 6: Django Commands
  ✓ collectstatic completed
  ✓ Database integrity OK
  ✓ Cache backend reachable

Phase 7: Performance
  ✓ No N+1 queries detected
  ✓ Database indexes configured
  ✓ Query count acceptable

Phase 8: Static Assets
  ✓ npm audit: No vulnerabilities
  ✓ Assets built successfully
  ✓ Static files collected

Phase 9: Configuration
  ✓ DEBUG = False
  ✓ SECRET_KEY configured
  ✓ ALLOWED_HOSTS set
  ✓ HTTPS enabled
  ✓ HSTS enabled
  ✓ Database configured

Phase 10: Logging
  ✓ Logging configured
  ✓ Log files writable

Phase 11: API Documentation
  ✓ Schema generated
  ✓ Swagger UI accessible

Phase 12: Diff Review
  Files changed: 12
  +450, -120 lines
  ✓ No debug statements
  ✓ No hardcoded secrets
  ✓ Migrations included

RECOMMENDATION: WARNING: Fix pip-audit vulnerabilities before deploying

NEXT STEPS:
1. Update vulnerable dependencies
2. Re-run security scan
3. Deploy to staging for final testing
```

## Checklist trước khi deploy

- [ ] Tất cả test đều pass
- [ ] Coverage ≥ 80%
- [ ] Không có lỗ hổng bảo mật
- [ ] Không có migration chưa được áp dụng
- [ ] DEBUG = False trong settings production
- [ ] SECRET_KEY được cấu hình đúng
- [ ] ALLOWED_HOSTS được đặt đúng
- [ ] Đã bật backup database
- [ ] Static file đã được collect và phục vụ
- [ ] Logging đã được cấu hình và hoạt động
- [ ] Đã cấu hình error monitoring (Sentry, v.v.)
- [ ] Đã cấu hình CDN (nếu áp dụng)
- [ ] Đã cấu hình Redis/cache backend
- [ ] Celery worker đang chạy (nếu áp dụng)
- [ ] Đã cấu hình HTTPS/SSL
- [ ] Biến môi trường đã được ghi tài liệu

## Continuous Integration

### Ví dụ GitHub Actions

```yaml
# .github/workflows/django-verification.yml
name: Django Verification

on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Cache pip
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install ruff black mypy pytest pytest-django pytest-cov bandit safety pip-audit

      - name: Code quality checks
        run: |
          ruff check .
          black . --check
          isort . --check-only
          mypy .

      - name: Security scan
        run: |
          bandit -r . -f json -o bandit-report.json
          safety check --full-report
          pip-audit

      - name: Run tests
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          DJANGO_SECRET_KEY: test-secret-key
        run: |
          pytest --cov=apps --cov-report=xml --cov-report=term-missing

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Tham khảo nhanh

| Kiểm tra | Lệnh |
|-------|---------|
| Môi trường | `python --version` |
| Kiểm tra type | `mypy .` |
| Linting | `ruff check .` |
| Định dạng | `black . --check` |
| Migrations | `python manage.py makemigrations --check` |
| Tests | `pytest --cov=apps` |
| Bảo mật | `pip-audit && bandit -r .` |
| Django check | `python manage.py check --deploy` |
| Collectstatic | `python manage.py collectstatic --noinput` |
| Diff stats | `git diff --stat` |

Hãy nhớ: Verification tự động bắt được các vấn đề phổ biến nhưng không thay thế code review thủ công và việc test trên môi trường staging.
