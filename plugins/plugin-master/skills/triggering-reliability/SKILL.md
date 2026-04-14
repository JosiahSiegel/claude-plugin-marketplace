---
name: triggering-reliability
description: Catalog of common mistakes that break Claude Code agent and skill triggering, with concrete fixes. PROACTIVELY activate for: (1) plugins that installed but never trigger, (2) agents that fail to route for obvious queries, (3) skills not appearing in discovery, (4) auditing a plugin's triggering quality before release, (5) migrating deprecated agent true flag, (6) diagnosing zero-frontmatter SKILL.md files, (7) cleaning Windows/docs boilerplate out of YAML descriptions, (8) rewriting abstract descriptions that describe capability instead of when-to-use, (9) adding missing example blocks to agents, (10) spotting descriptions that lack PROACTIVELY activate for / Provides enumeration, (11) pre-release triggering audit. Provides: anti-pattern catalog, root-cause analysis for each mistake, before-and-after examples, repeatable audit process, and a greppable validation checklist.
---

# Common mistakes that break triggering

This skill is the reference catalog of everything that makes Claude Code agents and skills fail to trigger. Every mistake below has been observed in real plugins. Treat this as a checklist before shipping any plugin, and as the first place to look when an existing plugin installed fine but nothing happens.

## Quick triage: symptoms to likely cause

| Symptom | Most-likely cause |
|---|---|
| Skill directory exists but never loads | Missing YAML frontmatter (file starts with `#` not `---`) |
| Agent file exists but cannot be invoked by name | Deprecated `agent: true` flag with no `name:` field |
| Agent rarely triggers despite obvious queries | Missing `<example>` blocks or abstract-capability description |
| Skill triggers inconsistently | Description describes WHAT it does, not WHEN to use it |
| Multiple skills fight over the same query | Trigger-phrase overlap between descriptions |
| Agent description matches generic unrelated queries | Windows/docs boilerplate inside YAML `description:` poisons routing |
| Agent uses wrong model | `model:` field missing or hard-coded instead of `inherit` |

## Anti-pattern 1: Missing YAML frontmatter (zero-frontmatter skill)

### Symptom

`skills/my-skill/SKILL.md` starts with `# My Skill` or plain prose. No `---` line. The skill silently fails to appear in discovery.

### Root cause

Skill discovery parses YAML frontmatter for `name:` and `description:`. With no frontmatter, the skill has no identity, no description, and no way to match user queries.

### Fix

Prepend canonical frontmatter with a proper description:

```
---
name: my-skill
description: One-sentence summary. PROACTIVELY activate for: (1) trigger, (2) trigger, ..., (N) trigger. Provides: capability list.
---

# My Skill
(rest of body)
```

### How to find these

```
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

```
grep -rn "^agent: true" plugins/*/agents/*.md
# Expected output: zero matches
```

## Anti-pattern 3: Abstract "Use this agent for X" description

### Symptom

Description reads like a capability statement:

```
description: Use this agent for help with Azure.
```

### Root cause

Claude routes to agents based on trigger-phrase matching against the description. A description that describes the agent in the third person, without enumerating concrete triggers and query shapes, provides almost no routing signal.

### Fix

Rewrite the description with the `PROACTIVELY activate for: (1)... (N)...` enumeration and a `Provides: ...` capability list, AND add 4-6 `<example>` blocks.

## Anti-pattern 4: Description describes WHAT, not WHEN

### Symptom

```
description: This skill contains a comprehensive reference for Terraform AzureRM provider usage.
```

### Root cause

Claude routes based on matching user intent. "Contains a reference" tells Claude nothing about when the user would need this. The description must be phrased as trigger conditions from the user's point of view.

### Fix

Flip the perspective. Lead with `PROACTIVELY activate for:` and enumerate named triggers as the user would phrase them.

## Anti-pattern 5: No example blocks in agent description

### Symptom

Agent `description:` is a single paragraph. No `<example>` blocks.

### Root cause

`<example>` blocks give Claude concrete query shapes to match against. Without them, matching falls back to loose prose matching, which is far less reliable.

### Fix

Add 4-6 `<example>` blocks. Each block must include Context, user quote, assistant response (1-2 sentences), and commentary with trigger keywords. Use `description: |` (YAML block scalar) so the `<example>` blocks parse correctly.

**Skill coverage rule:** every skill the agent delegates to must have at least one `<example>` that would route to it. If the plugin has 9 skills and only 4 `<example>` blocks, 5 skills will trigger unreliably.

## Anti-pattern 6: Windows / docs boilerplate inside YAML description

### Symptom

```
description: |
  Complete Docker expertise. Use backslashes on Windows for file paths. Never create documentation files unless requested...
```

### Root cause

Cross-cutting boilerplate that appears in many agent/skill descriptions poisons routing. The boilerplate contains generic phrases that match many unrelated queries, so the agent over-triggers on irrelevant requests.

### Fix

Move the boilerplate to a dedicated body section under a named heading. The YAML `description:` stays purely routing-focused.

## Anti-pattern 7: Missing or hard-coded model field

### Symptom

```
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

Description is 2000+ characters with 20+ enumerated triggers.

### Root cause

Very long descriptions dilute matching quality and often indicate the skill is doing too much. Trigger phrases start competing with each other.

### Fix

- Target under 800 characters per skill description.
- If you genuinely have 15+ triggers, split the skill into two focused skills.
- Collapse near-duplicate triggers into a single item.

## Audit process for an existing plugin

Run these greps from the repo root, in order:

```
# 1. Find skills with no frontmatter (BROKEN)
for f in plugins/*/skills/*/SKILL.md; do
  head -1 "$f" | grep -q "^---" || echo "NO FRONTMATTER: $f"
done

# 2. Find agents still using deprecated agent: true
grep -rn "^agent: true" plugins/*/agents/*.md

# 3. Find agents missing example blocks
for f in plugins/*/agents/*.md; do
  grep -q "<example>" "$f" || echo "NO EXAMPLES: $f"
done

# 4. Find skills missing PROACTIVELY activate for:
for f in plugins/*/skills/*/SKILL.md; do
  head -20 "$f" | grep -q "PROACTIVELY activate for:" || echo "NO ENUMERATION: $f"
done

# 5. Find skills missing Provides:
for f in plugins/*/skills/*/SKILL.md; do
  head -20 "$f" | grep -q "Provides:" || echo "NO PROVIDES: $f"
done

# 6. Find agents missing model: inherit
for f in plugins/*/agents/*.md; do
  head -20 "$f" | grep -q "^model: inherit" || echo "NO MODEL INHERIT: $f"
done

# 7. Find Windows boilerplate inside YAML descriptions
grep -rn "MANDATORY: Always Use Backslashes" plugins/*/agents/*.md plugins/*/skills/*/SKILL.md
```

Every row of output is a triggering bug. Fix in the order listed - earlier items have larger blast radius.

## Validation: what good looks like

After fixes, all seven greps above should produce zero output (or, for items 4 and 5, the count should trend dramatically toward zero as skills are rewritten).

For a positive signal, confirm:

```
# Count agents with example blocks (should equal total agent count)
grep -l "<example>" plugins/*/agents/*.md | wc -l

# Count skills with PROACTIVELY enumeration
grep -l "PROACTIVELY activate for:" plugins/*/skills/*/SKILL.md | wc -l
```

## Per-mistake fix priority

1. **P0** - zero-frontmatter skills and `agent: true` agents (invisible/broken).
2. **P0** - Windows/docs boilerplate inside YAML (actively poisons routing).
3. **P1** - missing `<example>` blocks on agents that back multiple skills.
4. **P1** - descriptions missing `PROACTIVELY activate for:` / `Provides:` enumeration.
5. **P2** - metadata hygiene (`model: inherit`, `color:`, `tools:` tightening).
6. **P2** - trigger-phrase overlap audit and disambiguation.

Fix in priority order - do not spend time on P2 while P0 bugs exist.
