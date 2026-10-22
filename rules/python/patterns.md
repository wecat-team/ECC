---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Pattern Python

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Python.

## Protocol (Duck Typing)

```python
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

## Dataclass làm DTO

```python
from dataclasses import dataclass

@dataclass
class CreateUserRequest:
    name: str
    email: str
    age: int | None = None
```

## Context Manager & Generator

- Dùng context manager (câu lệnh `with`) để quản lý tài nguyên
- Dùng generator cho lazy evaluation và duyệt tiết kiệm bộ nhớ

## Tham chiếu

Xem skill: `python-patterns` để có các pattern toàn diện bao gồm decorator, concurrency và tổ chức package.
