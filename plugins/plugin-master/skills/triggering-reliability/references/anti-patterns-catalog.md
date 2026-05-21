# Triggering-Reliability Anti-Patterns Catalog

Nine canonical anti-patterns that cause agents and skills to never trigger. SKILL.md keeps a summary table; this reference has the full symptom / root cause / fix narrative for each.

## Anti-pattern 1: Missing YAML frontmatter (zero-frontmatter skill)

### Symptom

`skills/my-skill/SKILL.md` starts with `# My Skill` or plain prose. No `---` line. The skill silently fails to appear in discovery.

### Root cause

Skill discovery parses YAML frontmatter for `name:` and `description:`. With no frontmatter, the skill has no identity, no description, and no way to match user queries.

### Fix

Prepend canonical frontmatter with a proper description:

```markdown
---
name: my-skill
description: One-sentence summary. PROACTIVELY activate for: (1) trigger, (2) trigger, ..., (N) trigger. Provides: capability list.
---

# My Skill
(rest of body)
```

### How to find these

```bash
for f in plugins/*/skills/*/SKILL.md; do
  head -1 "$f" | grep -q "^---" || echo "BROKEN: $f"
done
```

## Anti-pattern 2: Deprecated `agent: true` flag

### Symptom

`plugins/my-plugin/agents/my-expert.md` has `agent: true` as a frontmatter field but no `name:` field. The agent is not routable by name.

### Root cause

`agent: true` is a legacy flag from an older plugin format. Modern agent routing requires `name:` as a kebab-case identifier. Without it, the agent cannot be invoked deliberately and can be missed by auto-discovery.

### Fix

Replace `agent: true` with `name: <kebab-name>` derived from the filename.

### How to find these

```bash
grep -rn "^agent: true" plugins/*/agents/*.md
# Expected output: zero matches
```

## Anti-pattern 3: Abstract "Use this agent for X" description

### Symptom

Description reads like a capability statement:

```yaml
description: Use this agent for help with Azure.
```

### Root cause

Claude routes to agents based on trigger-phrase matching against the description. A description that describes the agent in the third person, without enumerating concrete triggers and query shapes, provides almost no routing signal.

### Fix

Rewrite the description with the `PROACTIVELY activate for: (1)... (N)...` enumeration and a `Provides: ...` capability list, AND add 4-6 `<example>` blocks.

## Anti-pattern 4: Description describes WHAT, not WHEN

### Symptom

```yaml
description: This skill contains a comprehensive reference for Terraform AzureRM provider usage.
```

### Root cause

Claude routes based on matching user intent. "Contains a reference" tells Claude nothing about when the user would need this. The description must be phrased as trigger conditions from the user's point of view.

### Fix

Flip the perspective. Lead with `PROACTIVELY activate for:` and enumerate named triggers as the user would phrase them.

## Anti-pattern 5: Missing example blocks on a fat agent

### Symptom

Agent `description:` is a single paragraph with no `<example>` blocks, AND the agent body is more than 2,500 words.

### Root cause

`<example>` blocks give Claude concrete query shapes to match against. On a substantial agent body where the description alone cannot disambiguate routing, the absence forces loose prose matching, which is far less reliable.

### Fix

Add 3-5 `<example>` blocks. Each block must include Context, user quote, assistant response (1-2 sentences), and commentary with trigger keywords. Use `description: |` (YAML block scalar) so the `<example>` blocks parse correctly.

**Skill coverage rule (applies only when examples are present):** every skill the agent delegates to must have at least one `<example>` that would route to it. If a fat agent has 9 skills and only 4 `<example>` blocks, 5 skills will trigger unreliably. This rule does NOT compel adding examples to a lean orchestrator that has none by design.

### Not an anti-pattern: lean orchestrator with no examples

A lean orchestrator (agent body under 2,500 words) deliberately omits `<example>` blocks and relies on the `PROACTIVELY activate for:` enumeration in the description plus the skill activation table in the body to drive routing. This is the correct shape for most modern Claude Code agents — do not "fix" it. See the tier table in `agent-development` SKILL.md ("Example-block requirement by agent body size") and the audit caveat in `agent-development/references/validation-and-audits.md`.

## Anti-pattern 6: Windows / docs boilerplate inside YAML description

### Symptom

```yaml
description: |
  Complete Docker expertise. Use backslashes on Windows for file paths. Never create documentation files unless requested...
```

### Root cause

Cross-cutting boilerplate that appears in many agent/skill descriptions poisons routing. The boilerplate contains generic phrases that match many unrelated queries, so the agent over-triggers on irrelevant requests.

### Fix

Move the boilerplate to a dedicated body section under a named heading. The YAML `description:` stays purely routing-focused.

## Anti-pattern 7: Missing or hard-coded model field

### Symptom

```yaml
# Either missing entirely, or:
model: sonnet
```

### Root cause

The marketplace convention is `model: inherit` so the agent adopts the parent session's model. Hard-coding a model breaks the user's model preference and can silently downgrade capability on long-context sessions.

### Fix

Set `model: inherit`. Only deviate when the agent has a documented capability requirement.

## Anti-pattern 8: Trigger-phrase overlap across skills

### Symptom

Two skills in the same plugin both claim the same keyword in their descriptions. Users' queries route inconsistently between them.

### Root cause

Claude has no tiebreaker when two skills match the same query with similar strength.

### Fix

Assign exclusive ownership of each ambiguous keyword. The other skill should use a more specific phrase. Add a disambiguation hint in the agent's skill-activation table.

## Anti-pattern 9: Description too long / too many triggers

### Symptom

Description is over 1024 characters, or pushes past 1000 with diluted trigger phrases competing with each other.

### Root cause

Three distinct caps apply to descriptions (see `references/severity-and-limits.md`). Crossing the 1024-char API spec ceiling means the skill may be rejected by authoring tools or have its tail truncated. Even below the ceiling, descriptions over ~1000 chars typically indicate the skill is doing too much.

### Fix

- Target 400-1000 characters per skill or agent description.
- Hard ceiling: 1024 characters (Claude Code API spec).
- Front-load trigger keywords — the front of the description always survives any truncation.
- If you genuinely have 15+ triggers, split the skill into two focused skills.
- Collapse near-duplicate triggers into a single item.

