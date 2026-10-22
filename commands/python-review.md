---
description: Code review Python toàn diện về tuân thủ PEP 8, type hint, bảo mật và các idiom Pythonic. Gọi agent python-reviewer.
---

# Python Code Review

Lệnh này gọi agent **python-reviewer** để thực hiện code review toàn diện dành riêng cho Python.

## Lệnh này làm gì

1. **Xác định thay đổi Python**: Tìm các file `.py` đã sửa qua `git diff`
2. **Chạy phân tích tĩnh**: Thực thi `ruff`, `mypy`, `pylint`, `black --check`
3. **Quét bảo mật**: Kiểm tra SQL injection, command injection, deserialization không an toàn
4. **Review an toàn kiểu (type safety)**: Phân tích type hint và lỗi mypy
5. **Kiểm tra code Pythonic**: Xác minh code tuân theo PEP 8 và các best practice của Python
6. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng

## Khi nào dùng

Dùng `/python-review` khi:
- Sau khi viết hoặc sửa code Python
- Trước khi commit các thay đổi Python
- Review pull request có code Python
- Làm quen với một codebase Python mới
- Học các pattern và idiom Pythonic

## Các nhóm review

### CRITICAL (Phải sửa)
- Lỗ hổng SQL/Command injection
- Dùng eval/exec không an toàn
- Deserialization không an toàn với pickle
- Credential hardcode
- YAML load không an toàn
- Mệnh đề except trần (bare except) che giấu lỗi

### HIGH (Nên sửa)
- Thiếu type hint ở các function public
- Đối số mặc định có thể thay đổi (mutable default argument)
- Nuốt exception một cách im lặng
- Không dùng context manager cho tài nguyên
- Vòng lặp kiểu C thay vì comprehension
- Dùng type() thay vì isinstance()
- Race condition không có lock

### MEDIUM (Cân nhắc)
- Vi phạm định dạng PEP 8
- Thiếu docstring ở các function public
- Dùng print thay vì logging
- Thao tác chuỗi kém hiệu quả
- Magic number không có hằng số đặt tên
- Không dùng f-string để định dạng
- Tạo list không cần thiết

## Các kiểm tra tự động được chạy

```bash
# Type checking
mypy .

# Linting and formatting
ruff check .
black --check .
isort --check-only .

# Security scanning
bandit -r .

# Dependency audit
pip-audit
safety check

# Testing
pytest --cov=app --cov-report=term-missing
```

## Ví dụ sử dụng

```text
User: /python-review

Agent:
# Python Code Review Report

## Files Reviewed
- app/routes/user.py (modified)
- app/services/auth.py (modified)

## Static Analysis Results
✓ ruff: No issues
✓ mypy: No errors
WARNING: black: 2 files need reformatting
✓ bandit: No security issues

## Issues Found

[CRITICAL] SQL Injection vulnerability
File: app/routes/user.py:42
Issue: User input directly interpolated into SQL query
```python
query = f"SELECT * FROM users WHERE id = {user_id}"  # Bad
```
Fix: Use parameterized query
```python
query = "SELECT * FROM users WHERE id = %s"  # Good
cursor.execute(query, (user_id,))
```

[HIGH] Mutable default argument
File: app/services/auth.py:18
Issue: Mutable default argument causes shared state
```python
def process_items(items=[]):  # Bad
    items.append("new")
    return items
```
Fix: Use None as default
```python
def process_items(items=None):  # Good
    if items is None:
        items = []
    items.append("new")
    return items
```

[MEDIUM] Missing type hints
File: app/services/auth.py:25
Issue: Public function without type annotations
```python
def get_user(user_id):  # Bad
    return db.find(user_id)
```
Fix: Add type hints
```python
def get_user(user_id: str) -> Optional[User]:  # Good
    return db.find(user_id)
```

[MEDIUM] Not using context manager
File: app/routes/user.py:55
Issue: File not closed on exception
```python
f = open("config.json")  # Bad
data = f.read()
f.close()
```
Fix: Use context manager
```python
with open("config.json") as f:  # Good
    data = f.read()
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 2

Recommendation: FAIL: Block merge until CRITICAL issue is fixed

## Formatting Required
Run: `black app/routes/user.py app/services/auth.py`
```

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|--------|-----------|
| PASS: Approve | Không có vấn đề CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| FAIL: Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các lệnh khác

- Dùng skill `tdd-workflow` trước để đảm bảo test pass
- Dùng `/code-review` cho các mối quan tâm không đặc thù Python
- Dùng `/python-review` trước khi commit
- Dùng `/build-fix` nếu các công cụ phân tích tĩnh thất bại

## Review theo framework

### Dự án Django
Reviewer kiểm tra:
- Vấn đề N+1 query (dùng `select_related` và `prefetch_related`)
- Thiếu migration khi thay đổi model
- Dùng raw SQL khi ORM đủ dùng
- Thiếu `transaction.atomic()` cho các thao tác nhiều bước

### Dự án FastAPI
Reviewer kiểm tra:
- Cấu hình CORS sai
- Model Pydantic cho việc kiểm tra request
- Tính đúng đắn của response model
- Dùng async/await đúng cách
- Các pattern dependency injection

### Dự án Flask
Reviewer kiểm tra:
- Quản lý context (app context, request context)
- Xử lý lỗi đúng cách
- Tổ chức Blueprint
- Quản lý cấu hình

## Liên quan

- Agent: `agents/python-reviewer.md`
- Skills: `skills/python-patterns/`, `skills/python-testing/`

## Các cách sửa phổ biến

### Thêm Type Hint
```python
# Before
def calculate(x, y):
    return x + y

# After
from typing import Union

def calculate(x: Union[int, float], y: Union[int, float]) -> Union[int, float]:
    return x + y
```

### Dùng Context Manager
```python
# Before
f = open("file.txt")
data = f.read()
f.close()

# After
with open("file.txt") as f:
    data = f.read()
```

### Dùng List Comprehension
```python
# Before
result = []
for item in items:
    if item.active:
        result.append(item.name)

# After
result = [item.name for item in items if item.active]
```

### Sửa Mutable Default
```python
# Before
def append(value, items=[]):
    items.append(value)
    return items

# After
def append(value, items=None):
    if items is None:
        items = []
    items.append(value)
    return items
```

### Dùng f-string (Python 3.6+)
```python
# Before
name = "Alice"
greeting = "Hello, " + name + "!"
greeting2 = "Hello, {}".format(name)

# After
greeting = f"Hello, {name}!"
```

### Sửa việc nối chuỗi trong vòng lặp
```python
# Before
result = ""
for item in items:
    result += str(item)

# After
result = "".join(str(item) for item in items)
```

## Tương thích phiên bản Python

Reviewer ghi chú khi code dùng tính năng của các phiên bản Python mới hơn:

| Tính năng | Python tối thiểu |
|---------|----------------|
| Type hints | 3.5+ |
| f-strings | 3.6+ |
| Walrus operator (`:=`) | 3.8+ |
| Position-only parameters | 3.8+ |
| Match statements | 3.10+ |
| Type unions (&#96;x &#124; None&#96;) | 3.10+ |

Đảm bảo `pyproject.toml` hoặc `setup.py` của dự án chỉ định đúng phiên bản Python tối thiểu.
