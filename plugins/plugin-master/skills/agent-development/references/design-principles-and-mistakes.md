# Agent Design Principles & Common Mistakes

## System Prompt Structure Template

The markdown body of an agent becomes its system prompt. Write in **second person**.

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
- Include skill activation instructions if the agent should load skills
- Keep the agent body as a **lean orchestrator**

**DON'T:**
- Write in first person ("I am...", "I will...")
- Be vague or generic ("help with stuff")
- Skip process steps
- Leave output format undefined
- Omit quality standards
- Embed domain knowledge that belongs in skills

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

### Preventing Trigger Phrase Overlap Between Skills

When a plugin has multiple skills, their trigger phrases and description terms must not create ambiguity. If two skills both claim the same keyword (e.g., both "programmatic-development" and "tmdl-mastery" claim "TMDL"), the agent cannot reliably route requests.

**Disambiguation rules:**
1. **Audit trigger terms across all skills** — list every trigger phrase from every skill description side by side. Flag any term that appears in more than one skill.
2. **Assign exclusive ownership** — each ambiguous term must belong to exactly one skill. The other skill should use a more specific phrase (e.g., "TMDL file editing" vs. "programmatic deployment using TMDL").
3. **Add disambiguation hints to the agent's skill activation table** — for terms that could route to multiple skills, add a clarifying note: "TMDL editing/syntax → tmdl-mastery; TMDL in deployment pipelines → programmatic-development".
4. **Test with ambiguous queries** — after writing descriptions, mentally test phrases like "help me with TMDL" and verify the routing is unambiguous.

## Validation Checklist

Before finalizing an agent:

- [ ] Name: 3-50 chars, lowercase, hyphens, starts/ends alphanumeric
- [ ] Description: includes `PROACTIVELY activate for:` enumeration and `Provides:` capability list
- [ ] `<example>` blocks present **if and only if** required by the agent's body word count (see "Example-block requirement by agent body size" tier table). Lean orchestrators under 2,500 words are exempt.
- [ ] **If examples ARE present**, every skill the agent delegates to has at least one example that routes to it
- [ ] **No trigger phrase overlap**: no ambiguous keyword claimed by multiple skills without disambiguation
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
| Vague description on a fat agent (body > 2,500 words) without examples | Either split into lean orchestrator + skills OR add 3-5 `<example>` blocks with concrete user phrases |
| Skills without trigger examples (on agents that DO have examples) | When examples are present, every skill must have at least one example that routes to it. Lean orchestrators that have no examples by design are not subject to this rule. |
| Trigger phrase overlap between skills | Audit all skill descriptions for shared keywords; assign exclusive ownership or add disambiguation |
| `model: sonnet` when `inherit` works | Use `inherit` unless agent needs specific capability |
| Too many tools granted | Restrict to minimum needed tools |
| Generic system prompt | Be specific about process, output format, quality standards |
| No skill activation | Add skill loading instructions for knowledge-dependent agents |
| Multiple agents in one plugin | Use one expert agent with skills for different topics |
| Example blocks with full code/JSON | Keep examples concise (1-2 sentence responses); code belongs in skills |
| Same cross-cutting block in every skill | Put platform guidelines in agent body or one shared reference, not each SKILL.md |
| Re-adding `<example>` blocks to a lean orchestrator during a later audit | Lean orchestrators are exempt by design. Compute the agent body word count first; consult prior intent (recent commits, refactor notes) before "fixing" a missing-examples finding. |

