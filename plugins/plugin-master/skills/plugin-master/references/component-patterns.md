# Component Patterns

Advanced patterns for creating plugin components.

## Agent Patterns

### Expert Agent Pattern

The standard pattern for domain expertise:

```markdown
---
name: domain-expert
description: |
  Use this agent when users need [domain] expertise. Trigger for:
  - Creating [domain] solutions
  - Troubleshooting [domain] issues
  - Best practices guidance

  <example>
  Context: User needs domain help
  user: "Help me with [domain task]"
  assistant: "I'll use the domain-expert agent to assist you."
  <commentary>Domain expertise needed, trigger expert agent.</commentary>
  </example>

model: inherit
color: blue
---

You are an expert in [domain] with deep knowledge of...

## Core Responsibilities
1. [Responsibility 1]
2. [Responsibility 2]

## Process
1. Analyze the request
2. Apply domain knowledge
3. Provide solution with explanation

## Output Format
- Clear explanation
- Working code/commands
- Next steps
```

### Validator Agent Pattern

For validation and checking tasks:

```markdown
---
name: config-validator
description: |
  Use this agent to validate configuration files. Examples:

  <example>
  Context: User wants validation
  user: "Check if my config is correct"
  assistant: "I'll use the config-validator to analyze your configuration."
  <commentary>Validation request, trigger validator agent.</commentary>
  </example>

model: haiku
color: yellow
tools: ["Read", "Glob", "Grep"]
---

You are a configuration validator that checks files for...

## Validation Process
1. Read configuration file
2. Check required fields
3. Validate format
4. Report issues with severity

## Output Format
- Status: PASS/FAIL
- Issues found (if any)
- Recommendations
```

### Generator Agent Pattern

For code/content generation:

```markdown
---
name: test-generator
description: |
  Use this agent to generate tests. Examples:

  <example>
  Context: User wants tests
  user: "Generate tests for this function"
  assistant: "I'll use the test-generator agent to create comprehensive tests."
  <commentary>Test generation request, trigger generator agent.</commentary>
  </example>

model: sonnet
color: green
---

You are a test generation specialist...

## Generation Process
1. Analyze the code to test
2. Identify test cases (happy path, edge cases, errors)
3. Generate tests following project patterns
4. Include assertions and mocks

## Output
- Complete test file
- Explanation of test coverage
- Suggestions for additional tests
```

## Command Patterns

### Simple Action Command

```markdown
---
description: Run project tests with coverage report
---

Run the test suite and generate a coverage report.

## Process
1. Detect test framework (jest, pytest, etc.)
2. Run tests with coverage flag
3. Parse and display results
4. Highlight failures and low coverage areas

## Expected Output
- Test results summary
- Coverage percentage
- Failed test details
```

### Interactive Command

```markdown
---
description: Configure deployment settings interactively
argument-hint: "[environment]"
---

Guide user through deployment configuration.

## Process
1. If environment not specified, ask user which environment
2. Load current configuration
3. Present options using AskUserQuestion:
   - Target servers
   - Deployment strategy
   - Notification settings
4. Generate configuration file
5. Validate before saving

## Questions to Ask
- Which environment? (staging/production)
- Deployment strategy? (rolling/blue-green)
- Enable notifications? (yes/no)
```

### Workflow Command

```markdown
---
description: Create and submit a pull request
allowed-tools: ["Bash", "Read", "Write"]
---

Automate the PR creation workflow.

## Process
1. Check for uncommitted changes
2. Create/switch to feature branch if needed
3. Stage and commit changes
4. Push to remote
5. Create PR with generated description
6. Return PR URL

## Safety Checks
- Confirm branch name with user
- Show diff before committing
- Warn about force pushes
```

## Skill Patterns

### Domain Knowledge Skill

```markdown
---
name: api-design
description: |
  API design best practices and patterns. Activate for:
  (1) REST API design
  (2) GraphQL schema design
  (3) API versioning strategies
  (4) Error handling patterns
---

# API Design Guide

## Quick Reference
[Tables and key points]

## Core Patterns
[Essential information]

## Best Practices
[Guidelines]

## Additional Resources
See `references/` for detailed patterns.
```

### Workflow Skill

```markdown
---
name: deployment-workflow
description: |
  Production deployment procedures. Activate for:
  (1) Release preparation
  (2) Deployment execution
  (3) Rollback procedures
  (4) Post-deployment verification
---

# Deployment Workflow

## Pre-Deployment Checklist
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Environment ready

## Deployment Steps
1. Tag release
2. Deploy to staging
3. Run smoke tests
4. Deploy to production
5. Monitor metrics

## Rollback Procedure
[Steps for rollback]
```

## Hook Patterns

### Validation Hook

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
      "timeout": 10000
    }]
  }]
}
```

### Auto-Format Hook

```json
{
  "PostToolUse": [{
    "matcher": "Write",
    "hooks": [{
      "type": "command",
      "command": "prettier --write ${TOOL_INPUT_FILE_PATH}",
      "timeout": 5000
    }]
  }]
}
```

### Logging Hook

```json
{
  "SessionStart": [{
    "hooks": [{
      "type": "command",
      "command": "echo \"Session started: $(date)\" >> ${CLAUDE_PLUGIN_ROOT}/logs/sessions.log"
    }]
  }],
  "SessionEnd": [{
    "hooks": [{
      "type": "command",
      "command": "echo \"Session ended: $(date)\" >> ${CLAUDE_PLUGIN_ROOT}/logs/sessions.log"
    }]
  }]
}
```

## MCP Server Patterns

### External API Integration

```json
{
  "mcpServers": {
    "stripe-api": {
      "command": "npx",
      "args": ["-y", "@stripe/mcp-server"],
      "env": {
        "STRIPE_API_KEY": "${STRIPE_API_KEY}"
      }
    }
  }
}
```

### Local Tool Server

```json
{
  "mcpServers": {
    "local-tools": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.js"],
      "env": {
        "CONFIG_PATH": "${CLAUDE_PLUGIN_ROOT}/config.json"
      }
    }
  }
}
```

### Database Integration

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```
