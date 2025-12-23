# Run Python Tests

Run tests with pytest and display coverage report.

## What This Command Does

1. Runs pytest with coverage enabled
2. Shows test results and coverage summary
3. Identifies uncovered code
4. Suggests improvements

## Usage

I will execute:

```bash
uv run pytest -v --cov --cov-report=term-missing
```

Or if uv is not available:

```bash
pytest -v --cov --cov-report=term-missing
```

## Options

You can specify:
- **Test path**: `tests/unit/test_users.py`
- **Test pattern**: `-k "test_create"`
- **Parallel**: `-n auto` (with pytest-xdist)
- **Stop on failure**: `-x`
- **Show locals**: `-l`

## Coverage Report

The command displays:
- Files and their coverage percentage
- Missing lines that need tests
- Branch coverage (if enabled)

## Example Output

```
tests/test_users.py::test_create_user PASSED
tests/test_users.py::test_get_user PASSED
tests/test_users.py::test_delete_user PASSED

---------- coverage: platform linux, python 3.12 ----------
Name                    Stmts   Miss  Cover   Missing
-----------------------------------------------------
src/mypackage/users.py     45      5    89%   23-25, 42-43
src/mypackage/utils.py     12      0   100%
-----------------------------------------------------
TOTAL                      57      5    91%

3 passed in 0.45s
```

## Troubleshooting

If tests fail, I will:
1. Analyze the failure message
2. Identify the root cause
3. Suggest fixes
4. Help implement corrections
