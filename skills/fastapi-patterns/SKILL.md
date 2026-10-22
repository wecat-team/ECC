---
name: fastapi-patterns
description: Best practice FastAPI gồm cấu trúc project, schema Pydantic v2, dependency injection, async handler, authentication, authorization, service layer có transaction, và testing với httpx và pytest. Dùng khi xây dựng hoặc review ứng dụng FastAPI — schema Pydantic, dependency, async handler, auth hoặc test.
metadata:
  origin: ECC
---

# Mẫu FastAPI (FastAPI Patterns)

Phát triển FastAPI hiện đại, đạt chuẩn production: bố cục project, schema Pydantic v2, dependency injection, mẫu async, auth, service method có transaction và testing.

## Cấu trúc project

```text
my_app/
|-- app/
|   |-- main.py               # App factory, lifespan, middleware
|   |-- config.py             # Settings via pydantic-settings
|   |-- dependencies.py       # Shared FastAPI dependencies
|   |-- database.py           # SQLAlchemy engine + session
|   |-- routers/
|   |   `-- users.py
|   |-- models/               # SQLAlchemy ORM models
|   |   `-- user.py
|   |-- schemas/              # Pydantic request/response schemas
|   |   `-- user.py
|   `-- services/             # Business logic layer
|       `-- user_service.py
|-- tests/
|   |-- conftest.py
|   `-- test_users.py
|-- pyproject.toml
`-- .env
```

---

## App Factory và Lifespan

```python
# app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base
from app.routers import users


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Tự động tạo bảng khi khởi động để tiện dùng trong môi trường dev/demo.
    # Với ứng dụng production nghiêm ngặt, hãy quản lý schema bằng Alembic migration.
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown: đóng các tài nguyên pool.
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=settings.allow_credentials,
        allow_methods=settings.allowed_methods,
        allow_headers=settings.allowed_headers,
    )

    app.include_router(users.router, prefix="/users", tags=["users"])

    return app


app = create_app()
```

---

## Cấu hình với pydantic-settings

```python
# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "My App"
    app_version: str = "0.1.0"
    debug: bool = False

    database_url: str
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # Pydantic-settings v2 đánh giá an toàn trực tiếp các list literal có thể thay đổi
    allowed_origins: list[str] = ["http://localhost:3000"]
    allowed_methods: list[str] = ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
    allowed_headers: list[str] = ["Authorization", "Content-Type"]
    allow_credentials: bool = True


settings = Settings()
```

---

## Schema Pydantic (v2)

```python
# app/schemas/user.py
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, model_validator


class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=50)


class UserCreate(UserBase):
    password: str = Field(min_length=8)
    password_confirm: str

    @model_validator(mode="after")
    def passwords_match(self) -> "UserCreate":
        if self.password != self.password_confirm:
            raise ValueError("Passwords do not match")
        return self


class UserUpdate(BaseModel):
    username: str | None = Field(default=None, min_length=3, max_length=50)
    email: EmailStr | None = None


class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserListResponse(BaseModel):
    total: int
    items: list[UserResponse]
```

---

## Dependency Injection

```python
# app/dependencies.py
from typing import Annotated, AsyncGenerator
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import AsyncSessionLocal
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/users/token")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        subject = payload.get("sub")
        if subject is None:
            raise credentials_exception
        user_id = int(subject)
    except (JWTError, TypeError, ValueError):
        raise credentials_exception

    user = await db.get(User, user_id)
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
    return current_user


DbDep = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]
ActiveUserDep = Annotated[User, Depends(get_current_active_user)]
```

---

## Thiết kế Router và Endpoint

```python
# app/routers/users.py
from typing import Annotated
from fastapi import APIRouter, HTTPException, Query, status
from fastapi.security import OAuth2PasswordRequestForm

from app.dependencies import ActiveUserDep, DbDep
from app.schemas.user import UserCreate, UserResponse, UserUpdate, UserListResponse
from app.services.user_service import DuplicateUserError, UserService

router = APIRouter()


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(payload: UserCreate, db: DbDep) -> UserResponse:
    service = UserService(db)
    try:
        return await service.create(payload)
    except DuplicateUserError:
        raise HTTPException(status_code=400, detail="Email already registered")


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: ActiveUserDep) -> UserResponse:
    return current_user


@router.get("/", response_model=UserListResponse)
async def list_users(
    db: DbDep,
    current_user: ActiveUserDep,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> UserListResponse:
    service = UserService(db)
    users, total = await service.list(skip=skip, limit=limit)
    return UserListResponse(total=total, items=users)


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    payload: UserUpdate,
    db: DbDep,
    current_user: ActiveUserDep,
) -> UserResponse:
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    service = UserService(db)
    try:
        user = await service.update(user_id, payload)
    except DuplicateUserError:
        raise HTTPException(status_code=400, detail="Email already registered")
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/token")
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbDep,
) -> dict[str, str]:
    service = UserService(db)
    token = await service.authenticate(form_data.username, form_data.password)
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"access_token": token, "token_type": "bearer"}
```

---

## Service Layer

```python
# app/services/user_service.py
from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class DuplicateUserError(Exception):
    """Raised when a unique user field conflicts with an existing row."""


class UserService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_email(self, email: str) -> User | None:
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, payload: UserCreate) -> User:
        user = User(
            email=payload.email,
            username=payload.username,
            hashed_password=pwd_context.hash(payload.password),
        )
        self.db.add(user)
        try:
            # Dựa vào ràng buộc nguyên tử của DB thay vì kiểm tra trước ở tầng ứng dụng dễ dính race condition
            await self.db.commit()
        except IntegrityError as exc:
            await self.db.rollback()
            raise DuplicateUserError from exc
        await self.db.refresh(user)
        return user

    async def list(self, skip: int = 0, limit: int = 20) -> tuple[list[User], int]:
        total_result = await self.db.execute(select(func.count(User.id)))
        total = total_result.scalar_one()
        # Áp dụng thứ tự xác định rõ ràng để phân trang đáng tin cậy
        result = await self.db.execute(
            select(User).order_by(User.id).offset(skip).limit(limit)
        )
        return list(result.scalars()), total

    async def update(self, user_id: int, payload: UserUpdate) -> User | None:
        user = await self.db.get(User, user_id)
        if user is None:
            return None
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        try:
            await self.db.commit()
        except IntegrityError as exc:
            await self.db.rollback()
            raise DuplicateUserError from exc
        await self.db.refresh(user)
        return user

    async def authenticate(self, email: str, password: str) -> str | None:
        user = await self.get_by_email(email)
        if user is None or not pwd_context.verify(password, user.hashed_password):
            return None
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.access_token_expire_minutes
        )
        return jwt.encode(
            {"sub": str(user.id), "exp": expire},
            settings.secret_key,
            algorithm=settings.algorithm,
        )
```

> **Lưu ý về thiết kế Database:** Việc xử lý unique ở tầng ứng dụng đòi hỏi phải có unique index ở database bên dưới (ví dụ `unique=True` trên các thuộc tính mapping SQLAlchemy). Nếu thiếu ràng buộc bên dưới, việc bắt lỗi ở tầng ứng dụng không thể ngăn chặn race condition đồng thời một cách an toàn.

---

## Testing với httpx và pytest

```python
# tests/conftest.py
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.database import Base
from app.dependencies import get_db
from app.main import create_app

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(TEST_DATABASE_URL)
TestingSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session():
    async with TestingSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession):
    app = create_app()

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac


@pytest_asyncio.fixture
async def registered_user(client: AsyncClient) -> dict:
    resp = await client.post("/users/", json={
        "email": "test@example.com",
        "username": "testuser",
        "password": "securepass1",
        "password_confirm": "securepass1",
    })
    assert resp.status_code == 201
    return resp.json()


@pytest_asyncio.fixture
async def auth_token(client: AsyncClient, registered_user: dict) -> str:
    resp = await client.post("/users/token", data={
        "username": "test@example.com",
        "password": "securepass1",
    })
    assert resp.status_code == 200
    return resp.json()["access_token"]


@pytest_asyncio.fixture
async def auth_client(client: AsyncClient, auth_token: str) -> AsyncClient:
    client.headers.update({"Authorization": f"Bearer {auth_token}"})
    return client
```

---

## Anti-Pattern

```python
# Bad: business logic nằm trong route handler.
@router.post("/users/")
async def create_user(payload: UserCreate, db: DbDep):
    hashed = bcrypt.hash(payload.password)
    user = User(email=payload.email, hashed_password=hashed)
    db.add(user)
    await db.commit()
    return user

# Good: route mỏng, xử lý transaction trong service.
@router.post("/users/", response_model=UserResponse, status_code=201)
async def create_user(payload: UserCreate, db: DbDep):
    try:
        return await UserService(db).create(payload)
    except DuplicateUserError:
        raise HTTPException(status_code=400, detail="Email already registered")


# Bad: lệnh DB đồng bộ trong route async sẽ chặn event loop.
@router.get("/items/")
async def list_items(db: Session = Depends(get_db)):
    return db.query(Item).all()

# Good: dùng thực thi SQLAlchemy async.
@router.get("/items/")
async def list_items(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Item))
    return result.scalars().all()
```

---

## Best Practice

- LUÔN LUÔN khai báo `response_model` có kiểu để tránh rò rỉ PII/dữ liệu ngoài ý muốn và tạo schema OpenAPI sạch.
- Gom các dependency injection middleware chuẩn bằng type alias: `DbDep = Annotated[AsyncSession, Depends(get_db)]`.
- Bọc các ranh giới thay đổi database trong transaction ở service layer một cách gọn gàng, bắt trực tiếp các lỗi cấu trúc của database.
- Parse tham số JWT một cách phòng thủ, lường trước khả năng lệch kiểu string/integer từ các biến thể payload hiện đại.
- Áp dụng sắp xếp xác định (ví dụ `.order_by(Model.id)`) cho mọi endpoint phân trang offset/limit để tránh bỏ sót dữ liệu.
- Tách các kiểm tra authorization khỏi dependency authentication cốt lõi để trả tín hiệu REST status chính xác (`401` so với `403`).
