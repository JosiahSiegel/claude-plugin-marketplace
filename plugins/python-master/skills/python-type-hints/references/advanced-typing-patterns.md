# Advanced Typing Patterns

Production-ready typing patterns for complex Python applications.

## Generic Repository Pattern

```python
from typing import TypeVar, Generic, Protocol
from abc import abstractmethod
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, update
from sqlalchemy.orm import DeclarativeBase

T = TypeVar("T", bound=DeclarativeBase)


class Repository(Protocol[T]):
    """Repository protocol for data access."""

    async def get(self, id: int) -> T | None: ...
    async def get_all(self) -> list[T]: ...
    async def create(self, entity: T) -> T: ...
    async def update(self, id: int, **fields) -> T | None: ...
    async def delete(self, id: int) -> bool: ...


class SQLAlchemyRepository(Generic[T]):
    """SQLAlchemy implementation of repository."""

    def __init__(self, session: AsyncSession, model: type[T]):
        self.session = session
        self.model = model

    async def get(self, id: int) -> T | None:
        return await self.session.get(self.model, id)

    async def get_all(self) -> list[T]:
        result = await self.session.execute(select(self.model))
        return list(result.scalars().all())

    async def create(self, entity: T) -> T:
        self.session.add(entity)
        await self.session.commit()
        await self.session.refresh(entity)
        return entity

    async def update(self, id: int, **fields) -> T | None:
        await self.session.execute(
            update(self.model).where(self.model.id == id).values(**fields)
        )
        await self.session.commit()
        return await self.get(id)

    async def delete(self, id: int) -> bool:
        result = await self.session.execute(
            delete(self.model).where(self.model.id == id)
        )
        await self.session.commit()
        return result.rowcount > 0


# Type-safe usage
class UserRepository(SQLAlchemyRepository[User]):
    """User-specific repository with additional methods."""

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(
            select(self.model).where(self.model.email == email)
        )
        return result.scalar_one_or_none()


# Usage
repo: Repository[User] = UserRepository(session, User)
user = await repo.get(1)  # Returns User | None
```

## Discriminated Unions

```python
from typing import Literal, Union
from dataclasses import dataclass

@dataclass
class EmailNotification:
    type: Literal["email"] = "email"
    to: str
    subject: str
    body: str

@dataclass
class SMSNotification:
    type: Literal["sms"] = "sms"
    to: str
    message: str

@dataclass
class PushNotification:
    type: Literal["push"] = "push"
    device_token: str
    title: str
    body: str

Notification = Union[EmailNotification, SMSNotification, PushNotification]


async def send_notification(notification: Notification) -> bool:
    match notification.type:
        case "email":
            return await send_email(notification.to, notification.subject, notification.body)
        case "sms":
            return await send_sms(notification.to, notification.message)
        case "push":
            return await send_push(notification.device_token, notification.title, notification.body)


# Type-safe - mypy knows the specific type in each branch
def format_notification(notification: Notification) -> str:
    match notification:
        case EmailNotification(to=to, subject=subject):
            return f"Email to {to}: {subject}"
        case SMSNotification(to=to, message=message):
            return f"SMS to {to}: {message}"
        case PushNotification(device_token=token, title=title):
            return f"Push to {token}: {title}"
```

## Builder Pattern with Type Safety

```python
from typing import TypeVar, Generic, Self
from dataclasses import dataclass, field

@dataclass
class QueryBuilder[T]:
    """Type-safe query builder."""
    _model: type[T]
    _filters: list[str] = field(default_factory=list)
    _order_by: str | None = None
    _limit: int | None = None

    def filter(self, condition: str) -> Self:
        self._filters.append(condition)
        return self

    def order_by(self, field: str) -> Self:
        self._order_by = field
        return self

    def limit(self, n: int) -> Self:
        self._limit = n
        return self

    def build(self) -> str:
        query = f"SELECT * FROM {self._model.__tablename__}"
        if self._filters:
            query += " WHERE " + " AND ".join(self._filters)
        if self._order_by:
            query += f" ORDER BY {self._order_by}"
        if self._limit:
            query += f" LIMIT {self._limit}"
        return query


# Usage
query = (
    QueryBuilder(User)
    .filter("is_active = true")
    .filter("role = 'admin'")
    .order_by("created_at DESC")
    .limit(10)
    .build()
)
```

## Callback Types with ParamSpec

```python
from typing import ParamSpec, TypeVar, Callable, Awaitable
from functools import wraps
import time

P = ParamSpec("P")
R = TypeVar("R")


def timing(func: Callable[P, R]) -> Callable[P, R]:
    """Preserve function signature in decorator."""
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper


def async_timing(func: Callable[P, Awaitable[R]]) -> Callable[P, Awaitable[R]]:
    """Async version preserving signature."""
    @wraps(func)
    async def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        start = time.perf_counter()
        result = await func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper


# Usage - type checker knows exact signature
@timing
def calculate(x: int, y: int, *, precision: int = 2) -> float:
    return round(x / y, precision)

result = calculate(10, 3, precision=4)  # Type: float
```

## Conditional Types with Overloads

```python
from typing import overload, Literal

@overload
def fetch(url: str, *, as_json: Literal[True]) -> dict: ...
@overload
def fetch(url: str, *, as_json: Literal[False] = False) -> str: ...

def fetch(url: str, *, as_json: bool = False) -> dict | str:
    response = requests.get(url)
    if as_json:
        return response.json()
    return response.text


# Type checker knows the exact return type
data: dict = fetch("https://api.example.com", as_json=True)
text: str = fetch("https://api.example.com")


@overload
def get_item(items: list[int], index: int) -> int: ...
@overload
def get_item(items: list[str], index: int) -> str: ...
@overload
def get_item[T](items: list[T], index: int) -> T: ...

def get_item(items: list, index: int):
    return items[index]


# Type preserved
x: int = get_item([1, 2, 3], 0)
s: str = get_item(["a", "b"], 0)
```

## Typed Decorators Factory

```python
from typing import TypeVar, Callable, ParamSpec, overload
from functools import wraps

P = ParamSpec("P")
R = TypeVar("R")


def retry(
    max_attempts: int = 3,
    exceptions: tuple[type[Exception], ...] = (Exception,)
) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """Retry decorator with preserved types."""
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            last_exception: Exception | None = None
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
            raise last_exception or RuntimeError("Retry failed")
        return wrapper
    return decorator


@retry(max_attempts=3, exceptions=(ValueError, IOError))
def fetch_data(url: str, timeout: int = 30) -> dict:
    # Implementation
    ...

# Type checker knows: fetch_data(url: str, timeout: int = 30) -> dict
```

## Protocol with Class Methods

```python
from typing import Protocol, Self, ClassVar

class Serializable(Protocol):
    """Protocol for serializable objects."""

    @classmethod
    def from_dict(cls, data: dict) -> Self: ...

    def to_dict(self) -> dict: ...


class JSONSerializable(Protocol):
    """Protocol with class variables."""

    json_fields: ClassVar[list[str]]

    def to_json(self) -> str: ...


@dataclass
class User:
    """User implementing both protocols."""
    json_fields: ClassVar[list[str]] = ["id", "name", "email"]

    id: int
    name: str
    email: str

    @classmethod
    def from_dict(cls, data: dict) -> "User":
        return cls(**data)

    def to_dict(self) -> dict:
        return {"id": self.id, "name": self.name, "email": self.email}

    def to_json(self) -> str:
        return json.dumps(self.to_dict())


def serialize(obj: Serializable) -> dict:
    return obj.to_dict()

def deserialize[T: Serializable](cls: type[T], data: dict) -> T:
    return cls.from_dict(data)


# Usage
user_dict = serialize(User(1, "John", "john@example.com"))
user = deserialize(User, user_dict)
```

## Typed Context Variables

```python
from contextvars import ContextVar
from typing import Generic, TypeVar

T = TypeVar("T")


class TypedContextVar(Generic[T]):
    """Type-safe context variable wrapper."""

    def __init__(self, name: str, default: T | None = None):
        self._var: ContextVar[T | None] = ContextVar(name, default=default)

    def get(self) -> T:
        value = self._var.get()
        if value is None:
            raise RuntimeError(f"Context variable not set")
        return value

    def get_or_default(self, default: T) -> T:
        return self._var.get() or default

    def set(self, value: T) -> None:
        self._var.set(value)


# Usage
request_id: TypedContextVar[str] = TypedContextVar("request_id")
current_user: TypedContextVar[User] = TypedContextVar("current_user")

# Type-safe
request_id.set("abc-123")
user = current_user.get()  # Returns User, raises if not set
```

## Recursive Types

```python
from typing import TypeAlias

# JSON type (recursive)
JsonPrimitive: TypeAlias = str | int | float | bool | None
JsonArray: TypeAlias = list["JsonValue"]
JsonObject: TypeAlias = dict[str, "JsonValue"]
JsonValue: TypeAlias = JsonPrimitive | JsonArray | JsonObject


def parse_json(text: str) -> JsonValue:
    import json
    return json.loads(text)


# Tree structure
@dataclass
class TreeNode[T]:
    value: T
    children: list["TreeNode[T]"] = field(default_factory=list)

    def add_child(self, value: T) -> "TreeNode[T]":
        child = TreeNode(value)
        self.children.append(child)
        return child

    def traverse(self) -> Iterator[T]:
        yield self.value
        for child in self.children:
            yield from child.traverse()


# Usage
root: TreeNode[str] = TreeNode("root")
child1 = root.add_child("child1")
child1.add_child("grandchild1")

for value in root.traverse():
    print(value)  # Type: str
```

## Typed Event System

```python
from typing import TypeVar, Generic, Callable, Awaitable
from dataclasses import dataclass, field

E = TypeVar("E")


@dataclass
class Event:
    """Base event class."""
    timestamp: float = field(default_factory=time.time)


@dataclass
class UserCreatedEvent(Event):
    user_id: int
    email: str


@dataclass
class OrderPlacedEvent(Event):
    order_id: int
    user_id: int
    total: float


class TypedEventBus:
    """Type-safe event bus."""

    def __init__(self):
        self._handlers: dict[type, list[Callable]] = {}

    def subscribe[E: Event](
        self,
        event_type: type[E],
        handler: Callable[[E], Awaitable[None]]
    ) -> None:
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        self._handlers[event_type].append(handler)

    async def publish[E: Event](self, event: E) -> None:
        handlers = self._handlers.get(type(event), [])
        await asyncio.gather(*[h(event) for h in handlers])


# Usage
bus = TypedEventBus()

async def on_user_created(event: UserCreatedEvent) -> None:
    print(f"User {event.user_id} created with email {event.email}")

bus.subscribe(UserCreatedEvent, on_user_created)
await bus.publish(UserCreatedEvent(user_id=1, email="test@example.com"))
```
