# Hook Script Examples

Working hook scripts for common automation tasks.

## Auto-Format on Write

### hooks.json

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh ${TOOL_INPUT_FILE_PATH}",
          "timeout": 10000
        }
      ]
    }
  ]
}
```

### scripts/format.sh

```bash
#!/bin/bash
# Auto-format written files

FILE_PATH="$1"

# Skip if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Get file extension
EXT="${FILE_PATH##*.}"

case "$EXT" in
    js|jsx|ts|tsx|json|md)
        npx prettier --write "$FILE_PATH" 2>/dev/null
        ;;
    py)
        black "$FILE_PATH" 2>/dev/null || python -m black "$FILE_PATH" 2>/dev/null
        ;;
    go)
        gofmt -w "$FILE_PATH" 2>/dev/null
        ;;
    rs)
        rustfmt "$FILE_PATH" 2>/dev/null
        ;;
esac

exit 0
```

## Auto-Test After Changes

### hooks.json

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/run-tests.sh",
          "timeout": 120000
        }
      ]
    }
  ]
}
```

### scripts/run-tests.sh

```bash
#!/bin/bash
# Run tests after code changes

# Detect test framework and run tests
if [[ -f "package.json" ]]; then
    # Node.js project
    if grep -q "jest" package.json; then
        npm test -- --bail --passWithNoTests 2>&1 | tail -20
    elif grep -q "vitest" package.json; then
        npx vitest run --bail 2>&1 | tail -20
    elif grep -q "mocha" package.json; then
        npm test 2>&1 | tail -20
    fi
elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
    # Python project
    pytest --tb=short -q 2>&1 | tail -20
elif [[ -f "Cargo.toml" ]]; then
    # Rust project
    cargo test --quiet 2>&1 | tail -20
elif [[ -f "go.mod" ]]; then
    # Go project
    go test ./... -short 2>&1 | tail -20
fi

exit 0
```

## Block Dangerous Commands

### hooks.json

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-command.sh",
          "timeout": 5000
        }
      ]
    }
  ]
}
```

### scripts/validate-command.sh

```bash
#!/bin/bash
# Block dangerous bash commands

COMMAND="${TOOL_INPUT_COMMAND}"

# Patterns to block
BLOCKED_PATTERNS=(
    "rm -rf /"
    "rm -rf /*"
    "rm -rf ~"
    "> /dev/sda"
    "mkfs."
    ":(){:|:&};:"
    "dd if=/dev/zero of=/dev"
    "chmod -R 777 /"
    "chown -R.*:.*/"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if [[ "$COMMAND" == *"$pattern"* ]]; then
        echo "BLOCKED: Dangerous command pattern detected: $pattern" >&2
        exit 1
    fi
done

# Block force push to protected branches
if [[ "$COMMAND" == *"git push"*"--force"* ]]; then
    if [[ "$COMMAND" == *"main"* ]] || [[ "$COMMAND" == *"master"* ]]; then
        echo "BLOCKED: Force push to protected branch" >&2
        exit 1
    fi
fi

exit 0
```

## Lint on File Write

### hooks.json

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh ${TOOL_INPUT_FILE_PATH}",
          "timeout": 30000
        }
      ]
    }
  ]
}
```

### scripts/lint.sh

```bash
#!/bin/bash
# Lint written files

FILE_PATH="$1"

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"

case "$EXT" in
    js|jsx)
        npx eslint "$FILE_PATH" --fix 2>&1 | grep -E "error|warning" | head -10
        ;;
    ts|tsx)
        npx eslint "$FILE_PATH" --fix 2>&1 | grep -E "error|warning" | head -10
        npx tsc --noEmit "$FILE_PATH" 2>&1 | head -10
        ;;
    py)
        flake8 "$FILE_PATH" 2>&1 | head -10
        mypy "$FILE_PATH" 2>&1 | head -10
        ;;
    go)
        go vet "$FILE_PATH" 2>&1
        ;;
    sh|bash)
        shellcheck "$FILE_PATH" 2>&1 | head -10
        ;;
esac

exit 0
```

## Session Logging

### hooks.json

```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/log-session.sh start"
        }
      ]
    }
  ],
  "SessionEnd": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/log-session.sh end"
        }
      ]
    }
  ]
}
```

### scripts/log-session.sh

```bash
#!/bin/bash
# Log session start/end

ACTION="$1"
LOG_DIR="${CLAUDE_PLUGIN_ROOT}/logs"
LOG_FILE="$LOG_DIR/sessions.log"

# Create log directory if needed
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PROJECT=$(basename "$PWD")

case "$ACTION" in
    start)
        echo "[$TIMESTAMP] SESSION_START project=$PROJECT" >> "$LOG_FILE"
        ;;
    end)
        echo "[$TIMESTAMP] SESSION_END project=$PROJECT" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
        ;;
esac

exit 0
```

## Dockerfile Validation

### hooks.json

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-dockerfile.sh ${TOOL_INPUT_FILE_PATH}"
        }
      ]
    }
  ]
}
```

### scripts/validate-dockerfile.sh

```bash
#!/bin/bash
# Validate Dockerfile best practices

FILE_PATH="$1"

# Only validate Dockerfiles
[[ ! "$FILE_PATH" =~ Dockerfile ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

echo "Validating Dockerfile: $FILE_PATH"

WARNINGS=0

# Check for latest tag
if grep -q ":latest" "$FILE_PATH"; then
    echo "Warning: Using ':latest' tag - consider pinning to specific version"
    ((WARNINGS++))
fi

# Check for ADD instead of COPY
if grep -q "^ADD " "$FILE_PATH"; then
    echo "Warning: Using ADD instead of COPY - COPY is preferred for local files"
    ((WARNINGS++))
fi

# Check for root user
if ! grep -q "^USER " "$FILE_PATH"; then
    echo "Warning: No USER instruction - container will run as root"
    ((WARNINGS++))
fi

# Check for .dockerignore
DIR=$(dirname "$FILE_PATH")
if [[ ! -f "$DIR/.dockerignore" ]]; then
    echo "Warning: No .dockerignore file found"
    ((WARNINGS++))
fi

if [[ $WARNINGS -eq 0 ]]; then
    echo "Dockerfile validation passed"
else
    echo "Found $WARNINGS warning(s)"
fi

exit 0
```

## Git Pre-Commit Check

### hooks.json

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit-check.sh"
        }
      ]
    }
  ]
}
```

### scripts/pre-commit-check.sh

```bash
#!/bin/bash
# Check before git commit operations

COMMAND="${TOOL_INPUT_COMMAND}"

# Only check git commit commands
[[ ! "$COMMAND" =~ "git commit" ]] && exit 0

# Check for staged changes
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
if [[ $STAGED -eq 0 ]]; then
    echo "Warning: No files staged for commit"
fi

# Check for large files
LARGE_FILES=$(git diff --cached --name-only | xargs -I {} du -k {} 2>/dev/null | awk '$1 > 1024 {print $2}')
if [[ -n "$LARGE_FILES" ]]; then
    echo "Warning: Large files staged (>1MB):"
    echo "$LARGE_FILES"
fi

# Check for sensitive files
SENSITIVE=$(git diff --cached --name-only | grep -E '\.(env|pem|key|secrets)$')
if [[ -n "$SENSITIVE" ]]; then
    echo "Warning: Potentially sensitive files staged:"
    echo "$SENSITIVE"
fi

exit 0
```

## Making Scripts Executable

After creating hook scripts, make them executable:

```bash
chmod +x scripts/*.sh
```

Or in the plugin setup:

```bash
find "${CLAUDE_PLUGIN_ROOT}/scripts" -name "*.sh" -exec chmod +x {} \;
```
