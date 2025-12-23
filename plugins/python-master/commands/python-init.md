# Initialize Python Project

Initialize a modern Python project with best practices configuration.

## What This Command Does

Creates a production-ready Python project structure with:

1. **Project Structure** (src layout)
   ```
   project/
   ├── src/
   │   └── package_name/
   │       ├── __init__.py
   │       └── main.py
   ├── tests/
   │   ├── conftest.py
   │   └── test_main.py
   ├── pyproject.toml
   ├── README.md
   └── .gitignore
   ```

2. **Configuration Files**
   - `pyproject.toml` with uv, ruff, mypy, pytest settings
   - `.gitignore` for Python projects
   - Pre-commit hooks (optional)

3. **Development Tools**
   - Ruff for linting and formatting
   - Mypy for type checking
   - Pytest for testing
   - uv for dependency management

## Usage

When running this command, I will:

1. Ask for project name and description
2. Create the directory structure
3. Generate pyproject.toml with modern configuration
4. Initialize git repository
5. Create virtual environment with uv
6. Install development dependencies

## Example pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My Python project"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.0.0",
    "ruff>=0.4.0",
    "mypy>=1.9.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
target-version = "py311"
line-length = 88
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP"]

[tool.mypy]
python_version = "3.11"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["-ra", "-q", "--cov=src"]
```

## Next Steps

After initialization:

```bash
# Activate environment
source .venv/bin/activate  # or just use `uv run`

# Run tests
uv run pytest

# Check code
uv run ruff check .
uv run mypy src

# Add dependencies
uv add requests fastapi
```
