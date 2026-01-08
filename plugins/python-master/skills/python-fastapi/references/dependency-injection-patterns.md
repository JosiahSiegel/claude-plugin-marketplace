# FastAPI Dependency Injection Patterns

Advanced dependency injection patterns for production FastAPI applications.

## Type Aliases for Clean Signatures

```python
from typing import Annotated
from fastapi import Depends, Query, Header
from sqlalchemy.ext.asyncio import AsyncSession

# Database session
async def get_db() -> AsyncIterator[AsyncSession]:
    async with async_session() as session:
        yield session

DbSession = Annotated[AsyncSession, Depends(get_db)]

# Current user
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: DbSession,
) -> User:
    user = await authenticate_user(token, db)
    if not user:
        raise HTTPException(401, "Invalid token")
    return user

CurrentUser = Annotated[User, Depends(get_current_user)]

# Active user (verified, not banned)
async def get_active_user(user: CurrentUser) -> User:
    if not user.is_active:
        raise HTTPException(403, "User is inactive")
    return user

ActiveUser = Annotated[User, Depends(get_active_user)]

# Admin user
async def get_admin_user(user: ActiveUser) -> User:
    if not user.is_admin:
        raise HTTPException(403, "Admin access required")
    return user

AdminUser = Annotated[User, Depends(get_admin_user)]


# Usage - clean endpoint signatures
@router.get("/users/me")
async def get_me(user: CurrentUser) -> UserResponse:
    return user

@router.delete("/users/{user_id}")
async def delete_user(user_id: int, admin: AdminUser, db: DbSession) -> None:
    await db.execute(delete(User).where(User.id == user_id))
    await db.commit()
```

## Pagination Dependency

```python
from dataclasses import dataclass
from typing import Annotated, Generic, TypeVar
from fastapi import Query

T = TypeVar("T")

@dataclass
class PaginationParams:
    page: int
    size: int
    offset: int

    @property
    def limit(self) -> int:
        return self.size


def get_pagination(
    page: Annotated[int, Query(ge=1, description="Page number")] = 1,
    size: Annotated[int, Query(ge=1, le=100, description="Items per page")] = 20,
) -> PaginationParams:
    return PaginationParams(
        page=page,
        size=size,
        offset=(page - 1) * size,
    )

Pagination = Annotated[PaginationParams, Depends(get_pagination)]


@dataclass
class PagedResponse(Generic[T]):
    items: list[T]
    total: int
    page: int
    size: int
    pages: int


# Usage
@router.get("/users", response_model=PagedResponse[UserResponse])
async def list_users(
    db: DbSession,
    pagination: Pagination,
) -> PagedResponse[UserResponse]:
    # Count total
    total = await db.scalar(select(func.count()).select_from(User))

    # Get page
    query = select(User).offset(pagination.offset).limit(pagination.limit)
    result = await db.execute(query)
    users = result.scalars().all()

    return PagedResponse(
        items=users,
        total=total,
        page=pagination.page,
        size=pagination.size,
        pages=(total + pagination.size - 1) // pagination.size,
    )
```

## Sorting and Filtering

```python
from enum import Enum
from typing import Annotated
from fastapi import Query

class SortOrder(str, Enum):
    ASC = "asc"
    DESC = "desc"

@dataclass
class SortParams:
    field: str
    order: SortOrder

def get_sort(
    sort_by: Annotated[str, Query(description="Field to sort by")] = "created_at",
    order: Annotated[SortOrder, Query(description="Sort order")] = SortOrder.DESC,
) -> SortParams:
    return SortParams(field=sort_by, order=order)

Sort = Annotated[SortParams, Depends(get_sort)]


@dataclass
class FilterParams:
    search: str | None
    status: str | None
    created_after: datetime | None
    created_before: datetime | None

def get_filters(
    search: Annotated[str | None, Query(description="Search term")] = None,
    status: Annotated[str | None, Query(description="Status filter")] = None,
    created_after: Annotated[datetime | None, Query()] = None,
    created_before: Annotated[datetime | None, Query()] = None,
) -> FilterParams:
    return FilterParams(
        search=search,
        status=status,
        created_after=created_after,
        created_before=created_before,
    )

Filters = Annotated[FilterParams, Depends(get_filters)]


# Usage
@router.get("/items")
async def list_items(
    db: DbSession,
    pagination: Pagination,
    sort: Sort,
    filters: Filters,
) -> PagedResponse[ItemResponse]:
    query = select(Item)

    # Apply filters
    if filters.search:
        query = query.where(Item.name.ilike(f"%{filters.search}%"))
    if filters.status:
        query = query.where(Item.status == filters.status)
    if filters.created_after:
        query = query.where(Item.created_at >= filters.created_after)
    if filters.created_before:
        query = query.where(Item.created_at <= filters.created_before)

    # Apply sorting
    sort_column = getattr(Item, sort.field, Item.created_at)
    if sort.order == SortOrder.DESC:
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    # Apply pagination
    query = query.offset(pagination.offset).limit(pagination.limit)

    result = await db.execute(query)
    return result.scalars().all()
```

## Service Layer Dependencies

```python
from typing import Protocol, Annotated
from fastapi import Depends

# Service protocol
class UserServiceProtocol(Protocol):
    async def get_by_id(self, user_id: int) -> User | None: ...
    async def create(self, data: UserCreate) -> User: ...
    async def update(self, user_id: int, data: UserUpdate) -> User: ...
    async def delete(self, user_id: int) -> bool: ...


# Service implementation
class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: int) -> User | None:
        return await self.db.get(User, user_id)

    async def create(self, data: UserCreate) -> User:
        user = User(**data.model_dump(exclude={"password"}))
        user.hashed_password = hash_password(data.password)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update(self, user_id: int, data: UserUpdate) -> User:
        user = await self.get_by_id(user_id)
        if not user:
            raise HTTPException(404, "User not found")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def delete(self, user_id: int) -> bool:
        result = await self.db.execute(
            delete(User).where(User.id == user_id)
        )
        await self.db.commit()
        return result.rowcount > 0


# Dependency
def get_user_service(db: DbSession) -> UserService:
    return UserService(db)

UserSvc = Annotated[UserService, Depends(get_user_service)]


# Usage
@router.get("/users/{user_id}")
async def get_user(user_id: int, service: UserSvc) -> UserResponse:
    user = await service.get_by_id(user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return user

@router.post("/users", status_code=201)
async def create_user(data: UserCreate, service: UserSvc) -> UserResponse:
    return await service.create(data)
```

## Request Context / Scope Dependency

```python
from contextvars import ContextVar
from uuid import uuid4
from fastapi import Request

# Context variables
request_id_ctx: ContextVar[str] = ContextVar("request_id", default="")
user_ctx: ContextVar[User | None] = ContextVar("current_user", default=None)


# Middleware to set request context
@app.middleware("http")
async def request_context_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid4()))
    request_id_ctx.set(request_id)

    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


# Access context anywhere
def get_request_id() -> str:
    return request_id_ctx.get()

RequestId = Annotated[str, Depends(get_request_id)]


# Usage in logging
import structlog

def get_logger() -> structlog.BoundLogger:
    return structlog.get_logger().bind(request_id=request_id_ctx.get())

Logger = Annotated[structlog.BoundLogger, Depends(get_logger)]


@router.post("/orders")
async def create_order(
    data: OrderCreate,
    db: DbSession,
    user: CurrentUser,
    request_id: RequestId,
    logger: Logger,
) -> OrderResponse:
    logger.info("Creating order", user_id=user.id)
    # ... create order
```

## Feature Flags Dependency

```python
from dataclasses import dataclass

@dataclass
class FeatureFlags:
    new_dashboard: bool
    beta_api: bool
    dark_mode: bool


async def get_feature_flags(user: CurrentUser | None = None) -> FeatureFlags:
    """Get feature flags for current user."""
    # Could fetch from database, config, or feature flag service
    base_flags = FeatureFlags(
        new_dashboard=True,
        beta_api=False,
        dark_mode=True,
    )

    # User-specific overrides
    if user and user.is_beta_tester:
        base_flags.beta_api = True

    return base_flags

Features = Annotated[FeatureFlags, Depends(get_feature_flags)]


@router.get("/dashboard")
async def get_dashboard(features: Features) -> dict:
    if features.new_dashboard:
        return {"version": "v2", "data": [...]}
    return {"version": "v1", "data": [...]}
```

## Rate Limiting Dependency

```python
from fastapi import HTTPException, Request
from dataclasses import dataclass
import redis.asyncio as redis

@dataclass
class RateLimitResult:
    allowed: bool
    remaining: int
    reset_at: int


class RateLimiter:
    def __init__(self, redis_client: redis.Redis, limit: int, window: int):
        self.redis = redis_client
        self.limit = limit
        self.window = window

    async def check(self, key: str) -> RateLimitResult:
        now = int(time.time())
        window_start = now - self.window

        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(key, 0, window_start)
        pipe.zadd(key, {str(now): now})
        pipe.zcard(key)
        pipe.expire(key, self.window)
        _, _, count, _ = await pipe.execute()

        return RateLimitResult(
            allowed=count <= self.limit,
            remaining=max(0, self.limit - count),
            reset_at=now + self.window,
        )


def rate_limit(limit: int = 100, window: int = 60):
    """Rate limit dependency factory."""
    async def dependency(request: Request) -> None:
        limiter = RateLimiter(request.app.state.redis, limit, window)
        key = f"rate_limit:{request.client.host}:{request.url.path}"

        result = await limiter.check(key)
        if not result.allowed:
            raise HTTPException(
                status_code=429,
                detail="Too many requests",
                headers={
                    "X-RateLimit-Remaining": str(result.remaining),
                    "X-RateLimit-Reset": str(result.reset_at),
                },
            )

    return Depends(dependency)


# Usage
@router.post("/api/expensive-operation", dependencies=[rate_limit(10, 60)])
async def expensive_operation() -> dict:
    # Limited to 10 requests per minute
    return {"status": "ok"}
```

## Caching Dependency

```python
import hashlib
import json
from typing import Callable

def cached(ttl: int = 300, key_prefix: str = ""):
    """Cache decorator for endpoints."""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, request: Request, **kwargs):
            # Generate cache key
            key_data = {
                "path": request.url.path,
                "query": str(request.query_params),
                "prefix": key_prefix,
            }
            cache_key = hashlib.md5(
                json.dumps(key_data, sort_keys=True).encode()
            ).hexdigest()

            # Check cache
            redis = request.app.state.redis
            cached = await redis.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute and cache
            result = await func(*args, request=request, **kwargs)
            await redis.setex(cache_key, ttl, json.dumps(result))
            return result

        return wrapper
    return decorator


# Usage
@router.get("/products")
@cached(ttl=60, key_prefix="products")
async def list_products(request: Request, db: DbSession) -> list[ProductResponse]:
    result = await db.execute(select(Product))
    return result.scalars().all()
```
