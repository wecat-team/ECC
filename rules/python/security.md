---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Bảo mật Python

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Python.

## Quản lý Secret

```python
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ["OPENAI_API_KEY"]  # Raises KeyError if missing
```

## Quét bảo mật

- Dùng **bandit** để phân tích bảo mật tĩnh:
  ```bash
  bandit -r src/
  ```

## Tham chiếu

Xem skill: `django-security` để có hướng dẫn bảo mật riêng cho Django (nếu áp dụng).
