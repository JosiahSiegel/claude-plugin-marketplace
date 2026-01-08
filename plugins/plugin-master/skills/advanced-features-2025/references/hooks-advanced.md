# Advanced Hook Patterns

Comprehensive guide to Claude Code hook development.

## Hook Architecture

### Event Flow

```
User Action → Event Triggered → Matchers Evaluated → Hooks Execute → Result Returned
```

### Hook Types

1. **Command hooks**: Execute shell commands
2. **Prompt hooks**: Provide instructions to Claude

## Complete Hook Schema

```json
{
  "EventName": [
    {
      "matcher": "ToolName|OtherTool",
      "hooks": [
        {
          "type": "command",
          "command": "shell-command",
          "timeout": 30000,
          "description": "What this hook does",
          "env": {
            "VAR_NAME": "value"
          }
        }
      ]
    }
  ]
}
```

## Event Reference

### PreToolUse

Fires BEFORE a tool executes. Use for validation, preparation.

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/check-lint.sh",
          "description": "Validate code before writing"
        }
      ]
    }
  ]
}
```

**Return codes:**
- 0: Allow tool execution
- Non-zero: Block execution (with error message)

### PostToolUse

Fires AFTER a tool executes. Use for testing, formatting, notifications.

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "npm test -- --bail",
          "timeout": 60000,
          "description": "Run tests after code changes"
        }
      ]
    }
  ]
}
```

### SessionStart

Fires when Claude Code session begins.

```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo 'Session: '$(date) >> ${CLAUDE_PLUGIN_ROOT}/logs/sessions.log"
        }
      ]
    }
  ]
}
```

### SessionEnd

Fires when session terminates.

```json
{
  "SessionEnd": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh"
        }
      ]
    }
  ]
}
```

### UserPromptSubmit

Fires after user submits a prompt.

```json
{
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo \"Prompt received: $(date)\" >> prompts.log"
        }
      ]
    }
  ]
}
```

### PreCompact

Fires before context compaction (when context gets too long).

```json
{
  "PreCompact": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/save-state.sh"
        }
      ]
    }
  ]
}
```

## Matcher Patterns

### Exact Match

```json
"matcher": "Write"
```

### Multiple Tools

```json
"matcher": "Write|Edit|Bash"
```

### Regex Pattern

```json
"matcher": "Write.*"
```

### All Tools

```json
"matcher": ".*"
```

**Warning:** Avoid `.*` unless necessary - causes hook to run on every tool.

## Environment Variables

### Built-in Variables

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin installation directory |
| `${TOOL_INPUT_FILE_PATH}` | File path (Write/Edit tools) |
| `${TOOL_INPUT_COMMAND}` | Command (Bash tool) |
| `${TOOL_INPUT_*}` | Any tool input parameter |

### Custom Variables

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh",
      "env": {
        "ENVIRONMENT": "production",
        "DEBUG": "true",
        "API_KEY": "${API_KEY}"
      }
    }
  ]
}
```

## Advanced Patterns

### Conditional Execution

Script that checks conditions:

```bash
#!/bin/bash
# Only run for certain file types

FILE_PATH="${TOOL_INPUT_FILE_PATH}"

if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]]; then
    npm run lint "$FILE_PATH"
fi
```

### Chained Hooks

Multiple hooks run in sequence:

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "prettier --write ${TOOL_INPUT_FILE_PATH}",
          "description": "Format code"
        },
        {
          "type": "command",
          "command": "eslint ${TOOL_INPUT_FILE_PATH}",
          "description": "Lint code"
        },
        {
          "type": "command",
          "command": "npm test",
          "description": "Run tests"
        }
      ]
    }
  ]
}
```

### Blocking Hook

PreToolUse hook that can block execution:

```bash
#!/bin/bash
# Block dangerous commands

COMMAND="${TOOL_INPUT_COMMAND}"

# Block rm -rf /
if [[ "$COMMAND" == *"rm -rf /"* ]]; then
    echo "ERROR: Blocked dangerous command: $COMMAND" >&2
    exit 1
fi

# Block force push to main
if [[ "$COMMAND" == *"git push"*"--force"*"main"* ]]; then
    echo "ERROR: Force push to main is not allowed" >&2
    exit 1
fi

exit 0
```

### Notification Hook

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "osascript -e 'display notification \"File saved: ${TOOL_INPUT_FILE_PATH}\" with title \"Claude Code\"'"
        }
      ]
    }
  ]
}
```

## Prompt-Based Hooks

Instead of shell commands, provide instructions to Claude:

```json
{
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "After writing this file, run the related tests and report any failures."
        }
      ]
    }
  ]
}
```

## Debugging Hooks

### Enable Debug Mode

```bash
claude --debug
```

Shows hook registration, matching, and execution.

### Test Hook Scripts

```bash
# Test script independently
TOOL_INPUT_FILE_PATH="/path/to/file.ts" ./scripts/lint.sh
```

### Log Hook Execution

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "echo \"Hook triggered: $(date)\" >> ${CLAUDE_PLUGIN_ROOT}/logs/hooks.log && original-command"
    }
  ]
}
```

## Best Practices

### Performance

- Set reasonable timeouts (default 30s)
- Avoid blocking on long operations
- Use async operations when possible

### Security

- Validate inputs in scripts
- Don't execute arbitrary user content
- Use `${CLAUDE_PLUGIN_ROOT}` for paths

### Reliability

- Handle errors gracefully
- Provide meaningful error messages
- Test on all target platforms

### Organization

- Document each hook's purpose
- Use descriptive script names
- Keep scripts in `scripts/` directory
