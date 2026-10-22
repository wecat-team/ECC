---
description: Review một ứng dụng FastAPI về kiến trúc, tính đúng đắn của async, dependency injection, Pydantic schema, bảo mật, hiệu năng và khả năng kiểm thử.
---

# FastAPI Review

Gọi agent `fastapi-reviewer` để review FastAPI có trọng tâm.

## Cách dùng

```text
/fastapi-review [file-or-directory]
```

## Các hạng mục review

- App factory, ranh giới router, middleware và exception handler.
- Tách biệt Pydantic schema cho request và response.
- Dependency injection cho database session, auth, phân trang và settings.
- Các pattern async cho database và HTTP bên ngoài.
- CORS, auth, rate limit, logging và xử lý secret.
- Metadata OpenAPI và các response model được tài liệu hóa.
- Thiết lập test client và dependency override.

## Output mong đợi

```text
[SEVERITY] Short issue title
File: path/to/file.py:42
Issue: What is wrong and why it matters.
Fix: Concrete change to make.
```

## Liên quan

- Agent: `fastapi-reviewer`
- Skill: `fastapi-patterns`
- Command: `/python-review`
- Skill: `security-scan`
