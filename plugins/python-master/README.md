# Python Master Plugin

Comprehensive Python expertise for Claude Code, covering modern Python 3.13+ development, async programming, type hints, FastAPI, testing, Cloudflare deployment, and GitHub Actions optimization.

## Features

This plugin provides expertise in:

- **Python 3.13+ Features** - Free-threading, JIT, pattern matching, type parameters
- **Asyncio Mastery** - TaskGroup, semaphores, uvloop, async patterns
- **Type Hints** - Protocols, TypedDict, generics, mypy/pyright
- **Package Management** - uv, pyproject.toml, src layout, Ruff
- **FastAPI** - Production patterns, Pydantic, async handlers
- **Testing** - pytest, fixtures, mocking, coverage, async tests
- **Cloudflare** - Python Workers, Containers, cold start optimization
- **GitHub Actions** - uv CI/CD, caching, matrix builds, PyPI publishing
- **Security** - OWASP compliance, input validation, secrets management
- **Performance** - Memory profiling, optimization techniques

## Skills

| Skill | Description |
|-------|-------------|
| `python-fundamentals-313` | Python 3.13+ features, syntax, memory optimizations |
| `python-asyncio` | Async/await patterns, TaskGroup, performance |
| `python-type-hints` | Modern type hints, Protocols, generics |
| `python-package-management` | uv, pyproject.toml, Ruff, project structure |
| `python-fastapi` | FastAPI production patterns, Pydantic, deployment |
| `python-testing` | pytest, fixtures, mocking, coverage |
| `python-cloudflare` | Workers, Containers, optimization |
| `python-github-actions` | CI/CD workflows, caching, publishing |
| `python-gotchas` | Common pitfalls and how to avoid them |

## Commands

| Command | Description |
|---------|-------------|
| `/python-init` | Initialize a new Python project with best practices |
| `/python-test` | Run tests with coverage report |

## Quick Reference

### Modern Python (3.12+)

```python
# Type parameters
def first[T](items: list[T]) -> T:
    return items[0]

# Pattern matching
match command:
    case {"action": "create", "name": str(name)}:
        return create(name)
    case _:
        return error()

# Type alias
type JsonValue = str | int | float | bool | None | list["JsonValue"]
```

### Async Patterns

```python
import asyncio

async def fetch_all(urls: list[str]) -> list[dict]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [task.result() for task in tasks]
```

### FastAPI

```python
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float

@app.post("/items/")
async def create_item(item: Item):
    return item
```

### uv Package Management

```bash
# Create project
uv init my-project

# Add dependencies
uv add fastapi pydantic

# Run with virtual env
uv run python main.py

# Sync from lockfile
uv sync
```

### pytest Testing

```python
import pytest

@pytest.fixture
def sample_data():
    return {"key": "value"}

@pytest.mark.asyncio
async def test_async_function(sample_data):
    result = await process(sample_data)
    assert result is not None
```

### Cloudflare Workers

```python
from workers import Response, WorkerEntrypoint

class Default(WorkerEntrypoint):
    async def fetch(self, request):
        return Response("Hello from Python Worker!")
```

### GitHub Actions

```yaml
- uses: astral-sh/setup-uv@v4
  with:
    enable-cache: true
- run: uv sync
- run: uv run pytest
```

## Best Practices Covered

### Code Quality
- Type annotations for all public APIs
- Ruff for consistent formatting/linting
- Mypy strict mode for type safety

### Project Structure
- src layout for packages
- pyproject.toml for all configuration
- uv for fast, reproducible environments

### Testing
- pytest with fixtures
- 80%+ code coverage
- Async test support

### Performance
- Async for I/O-bound operations
- Memory profiling with memray/tracemalloc
- Efficient data structures

### Security
- Input validation with Pydantic
- Parameterized queries
- Dependency auditing with pip-audit

## Installation

### Via GitHub Marketplace (Recommended)

```bash
/plugin marketplace add claude-plugin-marketplace
/plugin install python-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

```bash
unzip python-master.zip -d ~/.local/share/claude/plugins/
```

## License

MIT

## Links

- **Plugin Repository:** [claude-plugin-marketplace](https://github.com/JosiahSiegel/claude-plugin-marketplace)
- **Python Docs:** https://docs.python.org/3/
- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **uv Docs:** https://docs.astral.sh/uv/
- **Ruff Docs:** https://docs.astral.sh/ruff/
