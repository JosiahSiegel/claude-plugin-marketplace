# Asyncio Patterns Library

Production-ready async patterns for Python applications.

## Rate Limiter with Token Bucket

```python
import asyncio
from dataclasses import dataclass
from time import monotonic

@dataclass
class TokenBucket:
    """Token bucket rate limiter."""
    rate: float  # tokens per second
    capacity: float
    tokens: float = 0.0
    last_update: float = 0.0

    def __post_init__(self):
        self.tokens = self.capacity
        self.last_update = monotonic()
        self._lock = asyncio.Lock()

    async def acquire(self, tokens: float = 1.0) -> None:
        """Acquire tokens, waiting if necessary."""
        async with self._lock:
            while True:
                now = monotonic()
                elapsed = now - self.last_update
                self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
                self.last_update = now

                if self.tokens >= tokens:
                    self.tokens -= tokens
                    return

                wait_time = (tokens - self.tokens) / self.rate
                await asyncio.sleep(wait_time)


# Usage
limiter = TokenBucket(rate=10, capacity=100)  # 10 req/s, burst of 100

async def rate_limited_request(url: str):
    await limiter.acquire()
    async with httpx.AsyncClient() as client:
        return await client.get(url)
```

## Retry with Exponential Backoff

```python
import asyncio
from functools import wraps
from typing import TypeVar, Callable, Awaitable
import random

T = TypeVar("T")

def retry_async(
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    exceptions: tuple[type[Exception], ...] = (Exception,),
):
    """Retry decorator with exponential backoff."""
    def decorator(func: Callable[..., Awaitable[T]]) -> Callable[..., Awaitable[T]]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            last_exception = None
            for attempt in range(max_retries + 1):
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt == max_retries:
                        raise

                    delay = min(base_delay * (exponential_base ** attempt), max_delay)
                    if jitter:
                        delay *= (0.5 + random.random())

                    await asyncio.sleep(delay)

            raise last_exception  # Should never reach here

        return wrapper
    return decorator


# Usage
@retry_async(max_retries=3, exceptions=(httpx.HTTPError, asyncio.TimeoutError))
async def fetch_with_retry(url: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=10.0)
        response.raise_for_status()
        return response.json()
```

## Connection Pool

```python
import asyncio
from contextlib import asynccontextmanager
from typing import AsyncIterator, TypeVar, Generic

T = TypeVar("T")

class AsyncPool(Generic[T]):
    """Generic async connection pool."""

    def __init__(
        self,
        factory: Callable[[], Awaitable[T]],
        max_size: int = 10,
        min_size: int = 1,
    ):
        self._factory = factory
        self._max_size = max_size
        self._min_size = min_size
        self._pool: asyncio.Queue[T] = asyncio.Queue(maxsize=max_size)
        self._size = 0
        self._lock = asyncio.Lock()

    async def _create_connection(self) -> T:
        conn = await self._factory()
        self._size += 1
        return conn

    @asynccontextmanager
    async def acquire(self) -> AsyncIterator[T]:
        """Acquire a connection from the pool."""
        conn = None

        # Try to get from pool
        try:
            conn = self._pool.get_nowait()
        except asyncio.QueueEmpty:
            # Create new if under limit
            async with self._lock:
                if self._size < self._max_size:
                    conn = await self._create_connection()

        # Wait for available connection
        if conn is None:
            conn = await self._pool.get()

        try:
            yield conn
        finally:
            # Return to pool
            await self._pool.put(conn)


# Usage
async def create_db_connection():
    return await asyncpg.connect("postgresql://...")

pool = AsyncPool(create_db_connection, max_size=20)

async def query_database():
    async with pool.acquire() as conn:
        return await conn.fetch("SELECT * FROM users")
```

## Batch Processor

```python
import asyncio
from typing import TypeVar, Callable, Awaitable
from dataclasses import dataclass, field

T = TypeVar("T")
R = TypeVar("R")

@dataclass
class BatchProcessor(Generic[T, R]):
    """Process items in batches with concurrency control."""
    processor: Callable[[list[T]], Awaitable[list[R]]]
    batch_size: int = 100
    max_concurrent: int = 5
    timeout: float | None = None

    async def process(self, items: list[T]) -> list[R]:
        """Process all items in batches."""
        semaphore = asyncio.Semaphore(self.max_concurrent)
        results: list[R] = []

        async def process_batch(batch: list[T]) -> list[R]:
            async with semaphore:
                return await self.processor(batch)

        # Create batches
        batches = [
            items[i:i + self.batch_size]
            for i in range(0, len(items), self.batch_size)
        ]

        # Process all batches
        if self.timeout:
            async with asyncio.timeout(self.timeout):
                batch_results = await asyncio.gather(
                    *[process_batch(batch) for batch in batches]
                )
        else:
            batch_results = await asyncio.gather(
                *[process_batch(batch) for batch in batches]
            )

        # Flatten results
        for batch_result in batch_results:
            results.extend(batch_result)

        return results


# Usage
async def process_urls(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient() as client:
        responses = await asyncio.gather(*[client.get(url) for url in urls])
        return [r.json() for r in responses]

processor = BatchProcessor(process_urls, batch_size=10, max_concurrent=3)
results = await processor.process(all_urls)
```

## Event Bus

```python
import asyncio
from collections import defaultdict
from typing import Callable, Awaitable, Any
from dataclasses import dataclass, field

@dataclass
class AsyncEventBus:
    """Async pub/sub event bus."""
    _handlers: dict[str, list[Callable[..., Awaitable[None]]]] = field(
        default_factory=lambda: defaultdict(list)
    )

    def subscribe(self, event: str, handler: Callable[..., Awaitable[None]]) -> None:
        """Subscribe to an event."""
        self._handlers[event].append(handler)

    def unsubscribe(self, event: str, handler: Callable[..., Awaitable[None]]) -> None:
        """Unsubscribe from an event."""
        self._handlers[event].remove(handler)

    async def publish(self, event: str, **data: Any) -> None:
        """Publish an event to all subscribers."""
        handlers = self._handlers.get(event, [])
        if handlers:
            await asyncio.gather(*[h(**data) for h in handlers])

    async def publish_background(self, event: str, **data: Any) -> None:
        """Publish event without waiting for handlers."""
        handlers = self._handlers.get(event, [])
        for handler in handlers:
            asyncio.create_task(handler(**data))


# Usage
bus = AsyncEventBus()

async def on_user_created(user_id: int, email: str):
    await send_welcome_email(email)

async def on_user_created_analytics(user_id: int, email: str):
    await track_signup(user_id)

bus.subscribe("user.created", on_user_created)
bus.subscribe("user.created", on_user_created_analytics)

await bus.publish("user.created", user_id=123, email="user@example.com")
```

## Async Context Manager for Transactions

```python
from contextlib import asynccontextmanager
from typing import AsyncIterator
from sqlalchemy.ext.asyncio import AsyncSession

@asynccontextmanager
async def transaction(session: AsyncSession) -> AsyncIterator[AsyncSession]:
    """Transaction context manager with automatic rollback on error."""
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise


# Usage
async def create_user_with_profile(session: AsyncSession, user_data: dict):
    async with transaction(session):
        user = User(**user_data)
        session.add(user)
        await session.flush()  # Get user.id

        profile = Profile(user_id=user.id, **profile_data)
        session.add(profile)
        # Commit happens automatically if no exception
```

## Async Cache with TTL

```python
import asyncio
from dataclasses import dataclass, field
from time import monotonic
from typing import TypeVar, Generic, Callable, Awaitable

T = TypeVar("T")

@dataclass
class CacheEntry(Generic[T]):
    value: T
    expires_at: float

@dataclass
class AsyncCache(Generic[T]):
    """Async cache with TTL support."""
    default_ttl: float = 300.0  # 5 minutes
    _cache: dict[str, CacheEntry[T]] = field(default_factory=dict)
    _lock: asyncio.Lock = field(default_factory=asyncio.Lock)

    async def get(self, key: str) -> T | None:
        """Get value from cache."""
        async with self._lock:
            entry = self._cache.get(key)
            if entry is None:
                return None
            if monotonic() > entry.expires_at:
                del self._cache[key]
                return None
            return entry.value

    async def set(self, key: str, value: T, ttl: float | None = None) -> None:
        """Set value in cache."""
        async with self._lock:
            expires_at = monotonic() + (ttl or self.default_ttl)
            self._cache[key] = CacheEntry(value=value, expires_at=expires_at)

    async def get_or_set(
        self,
        key: str,
        factory: Callable[[], Awaitable[T]],
        ttl: float | None = None,
    ) -> T:
        """Get from cache or compute and store."""
        value = await self.get(key)
        if value is not None:
            return value

        value = await factory()
        await self.set(key, value, ttl)
        return value


# Usage
cache = AsyncCache[dict](default_ttl=60)

async def get_user(user_id: int) -> dict:
    return await cache.get_or_set(
        f"user:{user_id}",
        lambda: fetch_user_from_db(user_id),
        ttl=300,
    )
```

## Graceful Shutdown Handler

```python
import asyncio
import signal
from typing import Callable, Awaitable

class GracefulShutdown:
    """Handle graceful shutdown of async applications."""

    def __init__(self):
        self._shutdown_event = asyncio.Event()
        self._cleanup_handlers: list[Callable[[], Awaitable[None]]] = []

    def register_cleanup(self, handler: Callable[[], Awaitable[None]]) -> None:
        """Register a cleanup handler."""
        self._cleanup_handlers.append(handler)

    def is_shutting_down(self) -> bool:
        """Check if shutdown is in progress."""
        return self._shutdown_event.is_set()

    async def wait_for_shutdown(self) -> None:
        """Wait for shutdown signal."""
        await self._shutdown_event.wait()

    async def shutdown(self) -> None:
        """Perform graceful shutdown."""
        self._shutdown_event.set()
        for handler in reversed(self._cleanup_handlers):
            try:
                await handler()
            except Exception as e:
                print(f"Cleanup error: {e}")

    def setup_signals(self) -> None:
        """Set up signal handlers."""
        loop = asyncio.get_event_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(
                sig,
                lambda: asyncio.create_task(self.shutdown())
            )


# Usage
shutdown = GracefulShutdown()
shutdown.setup_signals()

shutdown.register_cleanup(close_database)
shutdown.register_cleanup(close_redis)

async def main():
    # Start services
    server = await start_server()

    # Wait for shutdown
    await shutdown.wait_for_shutdown()

    # Server cleanup
    await server.close()
```
