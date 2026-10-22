---
paths:
  - "**/app/**/*.py"
  - "**/fastapi/**/*.py"
  - "**/*_api.py"
---
# Rule cho FastAPI

Dùng các rule này cho dự án FastAPI cùng với các rule Python chung.

## Cấu trúc

- Đặt việc dựng app trong `create_app()`.
- Giữ router mỏng; chuyển persistence và hành vi nghiệp vụ vào service hoặc các CRUD helper.
- Tách riêng request schema, update schema và response schema.
- Giữ database session và auth trong dependency.

## Async

- Dùng `async def` cho các endpoint thực hiện I/O.
- Dùng database và HTTP client bất đồng bộ từ các endpoint async.
- Không gọi `requests`, session SQLAlchemy đồng bộ, hay các thao tác file/mạng gây chặn từ các route async.

## Dependency Injection

```python
@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ...
```

Không tạo `SessionLocal()` hay các client sống lâu bên trong route handler.

## Schema

- KHÔNG BAO GIỜ đưa mật khẩu, password hash, access token, refresh token hay trạng thái auth nội bộ vào response model.
- Dùng `response_model` trên các endpoint trả về dữ liệu ứng dụng.
- Dùng ràng buộc field thay cho validation viết tay khi Pydantic có thể diễn đạt được rule đó.

## Bảo mật

- Giữ CORS origin riêng theo từng môi trường.
- Không kết hợp wildcard origin với CORS có credential.
- Validate hạn dùng (expiry), issuer, audience và thuật toán của JWT.
- Rate-limit các endpoint auth và các endpoint ghi nhiều.
- Che (redact) credential, cookie, authorization header và token khỏi log.

## Kiểm thử

- Override đúng dependency được dùng bởi `Depends`.
- Xóa `app.dependency_overrides` sau khi test.
- Ưu tiên async test client cho ứng dụng async.

Xem skill: `fastapi-patterns`.
