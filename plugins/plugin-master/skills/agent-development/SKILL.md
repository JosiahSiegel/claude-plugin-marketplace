---
name: agent-development
description: |
  This skill should be used when the user asks to "create an agent", "add an agent to a plugin",
  "write agent frontmatter", "design a system prompt", "configure agent triggering", "restrict agent tools",
  "choose agent model", or needs guidance on agent file structure, description examples, triggering conditions,
  system prompt design, or agent development best practices for Claude Code plugins.
---

# Agent Development for Claude Code Plugins

## Overview

Agents are autonomous subprocesses that handle complex, multi-step tasks independently. Each agent is a markdown file in the `agents/` directory with YAML frontmatter defining its configuration and a markdown body serving as its system prompt.

## Agent File Format

```markdown
---
name: agent-identifier
description: |
  Use this agent when [triggering conditions].

  <example>
  Context: [Situation]
  user: "[User request]"
  assistant: "[How to respond and invoke agent]"
  <commentary>
  [Why this agent should trigger]
  </commentary>
  </example>

model: inherit
color: blue
tools:
  - Read
  - Write
  - Grep
---

System prompt body in second person ("You are...")
```

## Frontmatter Fields Reference

### name (required)

Agent identifier for namespacing and invocation.

| Rule | Detail |
|------|--------|
| Length | 3-50 characters |
| Format | Lowercase letters, numbers, hyphens only |
| Start/end | Must be alphanumeric (not hyphen) |
| Convention | Role-based: `code-reviewer`, `test-generator`, `domain-expert` |

**Invalid names:** `ag` (too short), `-agent-` (starts/ends with hyphen), `my_agent` (underscores)

### description (required - most critical field)

Defines WHEN Claude should trigger this agent. Poor descriptions = agent never triggers.

**Must include:**
1. Triggering conditions ("Use this agent when...")
2. 2-4 `<example>` blocks showing usage scenarios
3. Each example: context, user request, assistant response, commentary
4. Both proactive and reactive triggering scenarios

**Good description pattern:**
```yaml
description: |
  Use this agent when the user needs help with [domain]. Trigger for:
  - [Scenario 1]
  - [Scenario 2]
  - [Scenario 3]

  <example>
  Context: [Specific situation]
  user: "[What user says]"
  assistant: "[How Claude responds and invokes agent]"
  <commentary>
  [Why this is the right agent for this request]
  </commentary>
  </example>
```

**Common mistake:** Vague descriptions without examples. "Helps with code review" will rarely trigger. Include concrete examples with exact user phrases.

### model (required)

| Value | When to use |
|-------|-------------|
| `inherit` | **Default choice** - uses parent session's model |
| `sonnet` | Balanced capability/speed |
| `opus` | Most capable, for complex reasoning |
| `haiku` | Fast/cheap, for simple validation |

**Always use `inherit` unless the agent specifically needs a different capability level.**

### color (required)

Visual identifier in UI. Choose based on agent function:

| Color | Use for |
|-------|---------|
| `blue` / `cyan` | Analysis, review, research |
| `green` | Success-oriented, generation, creation |
| `yellow` | Caution, validation, checking |
| `red` | Critical, security, destructive operations |
| `magenta` | Creative, design, architecture |

Use distinct colors for different agents within the same plugin.

### tools (optional)

Restrict agent to specific tools. **Principle of least privilege** - only grant what's needed.

```yaml
# Read-only analysis
tools: ["Read", "Grep", "Glob"]

# Code generation
tools: ["Read", "Write", "Edit", "Grep", "Glob"]

# Full access (omit field entirely)
# tools: (not specified)
```

Common tool names: `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `WebSearch`, `WebFetch`, `Skill`, `Agent`

MCP tools use format: `mcp__server-name__tool-name`

## System Prompt Design

The markdown body becomes the agent's system prompt. Write in **second person** ("You are...", "You will...").

### Structure Template

```markdown
You are [role] specializing in [domain].

## Core Responsibilities
1. [Primary responsibility]
2. [Secondary responsibility]

## Process
1. [Step one]
2. [Step two]
3. [Step three]

## Quality Standards
- [Standard 1]
- [Standard 2]

## Output Format
- [What to include]
- [How to structure results]

## Edge Cases
- [Situation]: [How to handle]
```

### Best Practices

**DO:**
- Write in second person ("You are...", "You will...")
- Be specific about responsibilities and process steps
- Define output format clearly
- Address edge cases
- Keep under 10,000 characters
- Include skill activation instructions if the agent should load skills

**DON'T:**
- Write in first person ("I am...", "I will...")
- Be vague or generic ("help with stuff")
- Skip process steps
- Leave output format undefined
- Omit quality standards

## Agent Design Principles (2025)

### Agent-First Plugin Design

- Primary plugin interface is ONE expert agent named `{domain}-expert`
- Plugin named `docker-master` → agent named `docker-expert`
- Only 0-2 slash commands for automation workflows
- Users interact conversationally, not through command menus

### Single Responsibility

Each agent should have a clear, focused purpose. Don't create "do everything" agents. If a plugin needs multiple capabilities, use one expert agent that loads different skills based on context.

### Skill Integration

Expert agents should load relevant skills before answering. Include skill activation instructions in the system prompt:

```markdown
## Skill Activation
When the user asks about [topic], load `plugin-name:skill-name` before responding.
```

## Validation Checklist

Before finalizing an agent:

- [ ] Name: 3-50 chars, lowercase, hyphens, starts/ends alphanumeric
- [ ] Description: includes triggering conditions and 2-4 `<example>` blocks
- [ ] Model: set to `inherit` (unless specific need)
- [ ] Color: appropriate for agent function
- [ ] Tools: restricted to minimum needed (or omitted for full access)
- [ ] System prompt: second person, clear responsibilities, defined process and output
- [ ] Frontmatter: valid YAML with all required fields
- [ ] File location: `agents/agent-name.md`

## Testing

1. Write agent with specific triggering examples
2. Use similar phrasing to examples in your test queries
3. Verify Claude loads the agent for matching requests
4. Test that the agent follows its defined process
5. Check output matches defined format
6. Test edge cases mentioned in system prompt

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vague description without examples | Add 2-4 `<example>` blocks with concrete user phrases |
| `model: sonnet` when `inherit` works | Use `inherit` unless agent needs specific capability |
| Too many tools granted | Restrict to minimum needed tools |
| Generic system prompt | Be specific about process, output format, quality standards |
| No skill activation | Add skill loading instructions for knowledge-dependent agents |
| Multiple agents in one plugin | Use one expert agent with skills for different topics |
