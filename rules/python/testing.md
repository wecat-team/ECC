---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Kiểm thử Python

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Python.

## Framework

Dùng **pytest** làm testing framework.

## Coverage

```bash
pytest --cov=src --cov-report=term-missing
```

## Tổ chức Test

Dùng `pytest.mark` để phân loại test:

```python
import pytest

@pytest.mark.unit
def test_calculate_total():
    ...

@pytest.mark.integration
def test_database_connection():
    ...
```

## Tham chiếu

Xem skill: `python-testing` để có các pattern pytest và fixture chi tiết.
