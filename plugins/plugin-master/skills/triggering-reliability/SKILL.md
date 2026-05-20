---
name: triggering-reliability
description: |
  Catalog of common mistakes that break Claude Code agent and skill triggering.
  PROACTIVELY activate for: (1) plugins installed but never trigger, (2) agents failing to route, (3) skills not appearing in discovery, (4) pre-release triggering audit, (5) migrating deprecated agent true flag, (6) zero-frontmatter SKILL.md files, (7) boilerplate in YAML descriptions, (8) abstract descriptions, (9) missing agent <example> blocks, (10) missing PROACTIVELY or Provides sections.
  Provides: anti-patterns, fixes, before/after examples, and audit checklist.
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

Description is over 1024 characters, or pushes past 1000 with diluted trigger phrases competing with each other.

### Root cause

Three distinct caps apply to descriptions (see "Description length limits" below). Crossing the 1024-char API spec ceiling means the skill may be rejected by authoring tools or have its tail truncated. Even below the ceiling, descriptions over ~1000 chars typically indicate the skill is doing too much.

### Fix

- Target 400-1000 characters per skill or agent description.
- Hard ceiling: 1024 characters (Claude Code API spec).
- Front-load trigger keywords — the front of the description always survives any truncation.
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

## Severity table for validation reports

Use these tiers when reporting validation findings on a plugin:

| Tier | Meaning | Examples |
|---|---|---|
| **P0 - critical, must fix before ship** | Plugin will not load or component will not appear in discovery | plugin.json missing or invalid JSON; required field missing; wrong field type (`author` as string, `version` as number, `keywords` as string); skill with no YAML frontmatter; agent using deprecated `agent: true`; Windows/docs boilerplate inside YAML `description` (actively poisons routing) |
| **P1 - major, should fix before ship** | Plugin loads but triggers unreliably | Agent missing `<example>` blocks; skill description missing `PROACTIVELY activate for:` / `Provides:` enumeration; description describes WHAT instead of WHEN; skill or agent description over 1024 characters (per Claude Code API spec hard ceiling — see "Description length limits" below) |
| **P2 - polish** | Cosmetic or efficiency improvements | Missing `model: inherit`, `color:`, or `tools:` (defaults apply); description over the 400-700 char target (still well under the 1024 hard ceiling); trigger-phrase overlap between sibling skills; SKILL.md body over 3,000 words |

## Description length limits (Claude Code, current as of 2026)

Three distinct caps apply to skill and agent descriptions. Authors must respect all three.

| Cap | Value | What it means |
|---|---|---|
| **API spec hard ceiling** | 1024 chars per `description` field | Maximum allowed by the skill metadata spec. Authoring tools (e.g. the official `skill-creator` plugin's `quick_validate.py`) reject anything over this. Treat as a hard ceiling. |
| **Listing-cap for matching** | 1536 chars per entry (combined `description` + `when_to_use`) | What Claude actually sees when matching a query against installed skills. Raised from 250 → 1536 in Claude Code v2.1.105. Beyond this, the rest of the description is invisible to the router. |
| **Aggregate budget** | ~1% of model context window (~15-20k chars on Sonnet-class models) | Total budget across ALL installed skills' descriptions. When exceeded (v2.1.129+), descriptions of least-recently-used skills are dropped from the listing rather than truncating individual descriptions. |

**Authoring targets:**

- **Target: ~400-1000 chars per description.** Below 400 is usually too thin to provide good routing signal; above 1000 risks the API spec ceiling and dilutes matching for sibling skills.
- **Hard ceiling: 1024 chars.** Never exceed this. If you genuinely need more triggers, split the skill.
- **Front-load trigger keywords.** If aggregate-budget truncation kicks in for any reason (older clients, very large skill collections), the front of your description is what survives.
- **Dense plugins legitimately need more trigger surface.** A plugin covering many sub-workflows can sit in the 500-1000 range without harm. The old "soft 500" target was based on a since-superseded 250-char listing cap and is no longer the right ceiling.

## Canonical pre-publish checklist

Before publishing any plugin, every item below must be true:

- [ ] `plugin.json` exists at `.claude-plugin/plugin.json` and is valid JSON
- [ ] `name` is kebab-case
- [ ] `author` is an object `{ "name": "..." }` — not a string
- [ ] `version` is a string `"1.0.0"` — not a number
- [ ] `keywords` is an array — not a string
- [ ] No `agents` / `skills` / `slashCommands` fields in `plugin.json` (auto-discovered)
- [ ] Every agent file starts with `---` (YAML frontmatter present)
- [ ] Every agent has a `name:` field (not the deprecated `agent: true` flag)
- [ ] Every agent has `model: inherit`
- [ ] Every agent has at least one `<example>` block (4-6 preferred)
- [ ] Every agent has a `color:` field
- [ ] Every agent has `tools:` (minimal set) or omits the field for full tool access
- [ ] Every `SKILL.md` starts with `---` (NOT `# Title`)
- [ ] Every skill `description:` contains `PROACTIVELY activate for:` enumeration
- [ ] Every skill `description:` contains `Provides:` capability list
- [ ] Every skill `description:` is under 1024 characters (target 400-1000)
- [ ] No Windows / docs / cross-cutting boilerplate inside any YAML `description:` field
- [ ] If a `marketplace.json` exists at repo root, the plugin is registered there with matching `description` and `keywords`

## One-line greps for the canonical checks

Run these from a plugin directory. Any output is a finding.

```
grep -L "^---" skills/*/SKILL.md                                            # zero-frontmatter skills (P0)
grep -l "^agent: true" agents/*.md                                          # deprecated agents (P0)
grep -L "<example>" agents/*.md                                             # agents with no example blocks (P1)
grep -L "PROACTIVELY activate for:" skills/*/SKILL.md                       # skills missing trigger enumeration (P1)
grep -L "Provides:" skills/*/SKILL.md                                       # skills missing capability list (P1)
grep -L "^model: inherit" agents/*.md                                       # agents not inheriting model (P2)
grep -l "MANDATORY: Always Use Backslashes" agents/*.md skills/*/SKILL.md   # Windows boilerplate in YAML (P0)
```
