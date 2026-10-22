---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Phong cách code Python

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Python.

## Tiêu chuẩn

- Tuân theo quy ước **PEP 8**
- Dùng **type annotation** trên mọi function signature

## Bất biến (Immutability)

Ưu tiên cấu trúc dữ liệu bất biến:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class User:
    name: str
    email: str

from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float
```

## Định dạng

- **black** để format code
- **isort** để sắp xếp import
- **ruff** để lint

## Tham chiếu

Xem skill: `python-patterns` để có các idiom và pattern Python toàn diện.
