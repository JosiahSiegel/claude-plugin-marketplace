# Frontmatter Fields Reference

Detailed rules for each agent frontmatter field — `name`, `description`, `model`, `color`, `tools`. Authoritative source; SKILL.md links here.

## name (required)

Agent identifier for namespacing and invocation.

| Rule | Detail |
|------|--------|
| Length | 3-50 characters |
| Format | Lowercase letters, numbers, hyphens only |
| Start/end | Must be alphanumeric (not hyphen) |
| Convention | Role-based: `code-reviewer`, `test-generator`, `domain-expert` |

**Invalid names:** `ag` (too short), `-agent-` (starts/ends with hyphen), `my_agent` (underscores)

## description (required - most critical field)

Defines WHEN Claude should trigger this agent. Poor descriptions = agent never triggers.

**Must include:**
1. Triggering conditions phrased as `PROACTIVELY activate for: (1)... (N)...`
2. A `Provides: ...` capability list
3. `<example>` blocks **only when required by the agent's body word count** — see the tier table in "Example-block requirement by agent body size" above. For lean orchestrators under 2,500 body words, examples are optional and routinely omitted.
4. Both proactive and reactive triggering scenarios reflected in the `PROACTIVELY activate for:` enumeration

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

**Example block rules (when examples ARE included):**
- Keep example blocks **concise** — assistant response should be 1-2 sentences, not full code
- When the agent body crosses 2,500 words, target **3-5 example blocks** (caps at 7 to avoid dilution)
- Do NOT include full JSON schemas, code samples, or CLI output in examples
- Examples show *when* to trigger and *how to respond*, not the domain content itself

**Skill coverage requirement (applies only when examples are present):**
If the agent description includes `<example>` blocks at all, every skill the agent delegates to should have at least one example that would route to it. Count skills, count examples, and verify coverage. This rule does NOT compel adding examples to a lean orchestrator that has none by design — for lean orchestrators, routing is driven by the `PROACTIVELY activate for:` enumeration and the skill activation table in the body, not by `<example>` blocks.

## model (required)

| Value | When to use |
|-------|-------------|
| `inherit` | **Default choice** - uses parent session's model |
| `sonnet` | Balanced capability/speed |
| `opus` | Most capable, for complex reasoning |
| `haiku` | Fast/cheap, for simple validation |

**Always use `inherit` unless the agent specifically needs a different capability level.**

## color (required)

Visual identifier in UI. Choose based on agent function:

| Color | Use for |
|-------|---------|
| `blue` / `cyan` | Analysis, review, research |
| `green` | Success-oriented, generation, creation |
| `yellow` | Caution, validation, checking |
| `red` | Critical, security, destructive operations |
| `magenta` | Creative, design, architecture |

Use distinct colors for different agents within the same plugin.

## tools (optional)

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
