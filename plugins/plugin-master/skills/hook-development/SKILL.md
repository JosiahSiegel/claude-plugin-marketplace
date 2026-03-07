---
name: hook-development
description: |
  This skill should be used when the user asks to "create a hook", "add a PreToolUse hook",
  "add a PostToolUse hook", "validate tool use", "implement prompt-based hooks", "block dangerous commands",
  "set up event-driven automation", "configure hooks.json", "use ${CLAUDE_PLUGIN_ROOT} in hooks",
  or mentions hook events (PreToolUse, PostToolUse, Stop, SubagentStop, SessionStart, SessionEnd,
  UserPromptSubmit, PreCompact, Notification). Provides comprehensive hook development guidance.
---

# Hook Development for Claude Code Plugins

## Overview

Hooks are event-driven automation that execute in response to Claude Code events. Use hooks to validate operations, enforce policies, load context, and integrate external tools.

**Two hook types:**
- **Prompt-based** (recommended): LLM-driven, context-aware decisions
- **Command-based**: Shell commands for fast, deterministic checks

## Hook Events Reference

| Event | When | Common Use |
|-------|------|------------|
| PreToolUse | Before tool executes | Validate, approve/deny, modify input |
| PostToolUse | After tool completes | Test, lint, log, provide feedback |
| Stop | Main agent stopping | Verify task completeness |
| SubagentStop | Subagent stopping | Validate subagent work |
| UserPromptSubmit | User sends prompt | Add context, validate, preprocess |
| SessionStart | Session begins | Load context, set environment |
| SessionEnd | Session ends | Cleanup, logging |
| PreCompact | Before context compaction | Preserve critical information |
| Notification | Notification shown | Custom alert reactions |

## Configuration Formats

### Plugin hooks.json (in `hooks/hooks.json`)

**Uses wrapper format with `hooks` field:**

```json
{
  "description": "What these hooks do (optional)",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### User settings format (in `.claude/settings.json`)

**Direct format, no wrapper:**

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "script.sh" }]
    }
  ]
}
```

**Critical difference:** Plugin hooks.json wraps events inside `{"hooks": {...}}`. Settings format puts events at top level.

## Prompt-Based Hooks (Recommended)

Use LLM reasoning for context-aware decisions:

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this tool use is appropriate. Check for: system paths, credentials, path traversal. Return 'approve' or 'deny'.",
  "timeout": 30
}
```

**Supported events:** PreToolUse, PostToolUse, Stop, SubagentStop, UserPromptSubmit

**Benefits:** Context-aware, flexible, better edge case handling, easier to maintain.

## Command Hooks

Execute shell commands for deterministic checks:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
  "timeout": 60
}
```

**Always use `${CLAUDE_PLUGIN_ROOT}` for portable paths.**

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (stdout shown in transcript) |
| 2 | Blocking error (stderr fed back to Claude) |
| Other | Non-blocking error |

## Matchers

Control which tools trigger hooks:

```json
"matcher": "Write"              // Exact match
"matcher": "Write|Edit|Bash"    // Multiple tools
"matcher": "mcp__.*__delete.*"  // Regex (all MCP delete tools)
"matcher": "*"                  // All tools (use sparingly)
```

Matchers are case-sensitive.

## Hook Input/Output

### Input (all hooks receive via stdin)

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.txt",
  "cwd": "/current/working/dir",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "/path/to/file" }
}
```

Event-specific fields: `tool_name`, `tool_input`, `tool_result`, `user_prompt`, `reason`

Access in prompts: `$TOOL_INPUT`, `$TOOL_RESULT`, `$USER_PROMPT`

### Output

**Standard (all hooks):**
```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message for Claude"
}
```

**PreToolUse decisions:**
```json
{
  "hookSpecificOutput": {
    "permissionDecision": "allow|deny|ask",
    "updatedInput": { "field": "modified_value" }
  }
}
```

**Stop/SubagentStop decisions:**
```json
{
  "decision": "approve|block",
  "reason": "Explanation"
}
```

## Environment Variables

| Variable | Available | Purpose |
|----------|-----------|---------|
| `$CLAUDE_PLUGIN_ROOT` | All hooks | Plugin directory (portable paths) |
| `$CLAUDE_PROJECT_DIR` | All hooks | Project root path |
| `$CLAUDE_ENV_FILE` | SessionStart only | Persist env vars for session |

**SessionStart can persist variables:**
```bash
echo "export PROJECT_TYPE=nodejs" >> "$CLAUDE_ENV_FILE"
```

## Common Patterns

### Validate file writes (PreToolUse)

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "prompt",
      "prompt": "Check if this file write is safe. Deny writes to: .env, credentials, system paths, or files with path traversal (..). Return 'approve' or 'deny' with reason."
    }]
  }]
}
```

### Auto-test after changes (PostToolUse)

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "npm test -- --bail",
      "timeout": 60
    }]
  }]
}
```

### Verify task completion (Stop)

```json
{
  "Stop": [{
    "matcher": "*",
    "hooks": [{
      "type": "prompt",
      "prompt": "Verify: tests run, build succeeded, all questions answered. Return 'approve' to stop or 'block' with reason to continue."
    }]
  }]
}
```

### Load project context (SessionStart)

```json
{
  "SessionStart": [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/load-context.sh",
      "timeout": 10
    }]
  }]
}
```

## Security Best Practices

### In command hook scripts:

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path')

# Always validate inputs
if [[ ! "$file_path" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
  echo '{"decision": "deny", "reason": "Invalid path"}' >&2
  exit 2
fi

# Block path traversal
if [[ "$file_path" == *".."* ]]; then
  echo '{"decision": "deny", "reason": "Path traversal detected"}' >&2
  exit 2
fi

# Block sensitive files
if [[ "$file_path" == *".env"* ]]; then
  echo '{"decision": "deny", "reason": "Sensitive file"}' >&2
  exit 2
fi

# Always quote variables
echo "$file_path"
```

## Lifecycle and Limitations

**Hooks load at session start.** Changes to hook configuration require restarting Claude Code.

- Editing `hooks/hooks.json` won't affect the current session
- Adding new hook scripts won't be recognized until restart
- All matching hooks run **in parallel** (not sequentially)
- Hooks don't see each other's output - design for independence

**To test changes:** Exit Claude Code, restart with `claude` or `claude --debug`.

## Debugging

```bash
# Enable debug mode to see hook execution
claude --debug

# Test hook scripts directly
echo '{"tool_name": "Write", "tool_input": {"file_path": "/test"}}' | \
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh

# Validate hook JSON output
output=$(./hook-script.sh < test-input.json)
echo "$output" | jq .

# View loaded hooks in session
# Use /hooks command
```

## Validation Checklist

- [ ] hooks.json uses correct format (plugin wrapper or settings direct)
- [ ] All script paths use `${CLAUDE_PLUGIN_ROOT}` (no hardcoded paths)
- [ ] Scripts are executable and handle errors (`set -euo pipefail`)
- [ ] Scripts validate all inputs and quote all variables
- [ ] Matchers are specific (avoid `*` unless necessary)
- [ ] Timeouts are set appropriately (default: command 60s, prompt 30s)
- [ ] Hook output is valid JSON
- [ ] Tested with `claude --debug`
