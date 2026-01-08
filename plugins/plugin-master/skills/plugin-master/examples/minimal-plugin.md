# Minimal Plugin Example

The simplest working Claude Code plugin.

## Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── agents/
    └── my-expert.md
```

## Files

### .claude-plugin/plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief description of what this plugin does",
  "author": {
    "name": "Your Name"
  },
  "license": "MIT"
}
```

### agents/my-expert.md

```markdown
---
name: my-expert
description: |
  Use this agent when users need help with [domain]. Examples:

  <example>
  Context: User needs domain help
  user: "Help me with [task]"
  assistant: "I'll use the my-expert agent to help you."
  <commentary>Domain task requested, trigger expert agent.</commentary>
  </example>

model: inherit
color: blue
---

You are an expert in [domain].

## Your Responsibilities
1. Help users with [domain] tasks
2. Provide best practices guidance
3. Troubleshoot issues

## Process
1. Understand the user's request
2. Apply domain knowledge
3. Provide clear, actionable guidance

## Output
Provide clear explanations with working examples.
```

## Installation

### Local Testing

```bash
# Copy to Claude Code plugins directory
cp -r my-plugin ~/.claude/plugins/local/
```

### From Marketplace

If published to a marketplace:
```
/plugin marketplace add username/marketplace
/plugin install my-plugin@username
```

## Testing

After installation, test by asking:
- "Help me with [domain task]"
- The agent should trigger and provide assistance

## Expanding

To add more functionality:

1. **Add a command**: Create `commands/do-task.md`
2. **Add a skill**: Create `skills/domain-knowledge/SKILL.md`
3. **Add hooks**: Create `hooks/hooks.json`

See `full-plugin.md` for a complete example with all component types.
