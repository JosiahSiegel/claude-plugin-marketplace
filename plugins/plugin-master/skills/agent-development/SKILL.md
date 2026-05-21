---
name: agent-development
description: |
  Canonical guide to authoring Claude Code agent frontmatter and system prompts.
  PROACTIVELY activate for: (1) creating a new agent, (2) adding an agent to a plugin, (3) writing agent frontmatter, (4) designing a system prompt, (5) configuring <example> trigger blocks, (6) restricting tools, (7) setting model inherit, (8) migrating deprecated agent true flag, (9) fixing "agent never triggers", (10) ensuring skills have agent trigger coverage.
  Provides: agent templates, lean-orchestrator pattern, and validation checklist.
---

# Agent Development for Claude Code Plugins

## Overview

Agents are autonomous subprocesses that handle complex, multi-step tasks independently. Each agent is a markdown file in the `agents/` directory with YAML frontmatter defining its configuration and a markdown body serving as its system prompt.

## Canonical agent frontmatter template (MANDATORY shape)

This is the template every new agent MUST follow. Deviating from this shape is the #1 cause of agents that never trigger.

```yaml
---
name: my-agent                                    # REQUIRED: kebab-case, 3-50 chars, alphanumeric start/end
model: inherit                                    # REQUIRED: always `inherit` unless you have a hard reason
color: blue                                       # RECOMMENDED: one of blue/cyan/green/yellow/magenta/red
tools: Read, Write, Edit, Glob, Grep, Bash        # RECOMMENDED: minimal set; omit for full access
description: |
  One-sentence summary of what the agent does. PROACTIVELY activate for: (1) concrete trigger, (2) concrete trigger, ..., (N) concrete trigger. Provides: comma-separated capability nouns.

  <example>
  Context: Realistic situation where the agent should fire
  user: "A realistic user quote -- the kind of thing someone would actually type"
  assistant: "Short 1-2 sentence response. Mention loading a specific skill if relevant."
  <commentary>Triggers for specific-keyword-1, specific-keyword-2, specific-keyword-3</commentary>
  </example>

  <example>
  Context: Another realistic situation covering a different capability
  user: "..."
  assistant: "..."
  <commentary>Triggers for ...</commentary>
  </example>

  <example>
  Context: A debugging / troubleshooting scenario
  user: "..."
  assistant: "..."
  <commentary>Triggers for ...</commentary>
  </example>

  <example>
  Context: A "when to pick this vs. that" scenario
  user: "..."
  assistant: "..."
  <commentary>Triggers for ...</commentary>
  </example>
---

You are [role] specializing in [domain]. [Lean orchestrator body -- see "Lean Orchestrator Pattern" below.]
```

### Hard rules for the frontmatter

1. **`name:` is required.** Do NOT use the deprecated `agent: true` flag — that pattern is legacy and results in an unnamed agent that cannot be referenced or routed to reliably. If you find `agent: true` in an existing file, replace it with `name: <kebab-name-from-filename>`.
2. **`model: inherit` is required.** Never hard-code a model unless the agent has a documented capability requirement.
3. **`description:` MUST include the enumerated `PROACTIVELY activate for: (1)... (2)... (N)...` pattern AND a `Provides: ...` capability list.** A description that only says "Use this agent for help with X" will not route reliably.
4. **`<example>` blocks are conditional, not unconditional.** Whether the description needs `<example>` blocks depends on the agent's body word count — see **"Example-block requirement by agent body size"** below. Lean orchestrators deliberately omit them; fat agents need them. Do not blanket-require examples on every agent.
5. **Use `description: |` (YAML block scalar)** whenever the description spans multiple lines or contains `<example>` blocks. A folded scalar (`>`) or implicit flow scalar will mangle the examples.
6. **Do NOT put cross-cutting boilerplate (Windows path rules, documentation policy, etc.) inside the YAML `description:` block.** That text is used for routing-match, and boilerplate that appears in many agents poisons the signal. Put it in the markdown body under a clearly named `## Windows file path requirements` section (or similar) instead.

### Example-block requirement by agent body size (UNIFIED RULE)

The number of `<example>` blocks a description needs is a function of the agent's markdown body word count. This rule reconciles two earlier conflicting recommendations ("always add 4-6 examples" vs. "lean orchestrators don't need examples") into a single tier table that authoring guidance, the canonical checklist, and `scripts/validate_plugins.py` all share.

| Agent body word count | Tier | Example-block requirement |
|---|---|---|
| < 1,500 words | Sub-target | Optional |
| 1,500-2,500 words | **Lean orchestrator (target band)** | **Optional, often omitted by design** |
| 2,500-3,000 words | Above-target | **Recommended (3-5)** |
| > 3,000 words | Oversized | **Required (3-5) AND extraction mandatory** |

The validator only flags "missing examples" when the body crosses 2,500 words (`AGENT_EXAMPLES_THRESHOLD_WORDS`). Lean orchestrators under that threshold pass cleanly without examples — that absence is by design.

**Authoring distilled:** decide lean-orchestrator vs. fat-agent first; if lean, the `PROACTIVELY activate for:` enumeration carries routing and examples are not required. When refactoring fat -> lean, stripping examples is a legitimate part of the refactor. When auditing, compute body word count BEFORE recommending example-block fixes — see "Pre-recommendation intent check" below.

### Deprecated / broken patterns to migrate

| Broken pattern | What it does | Fix |
|---|---|---|
| `agent: true` (no `name:`) | Agent cannot be named/routed reliably | Replace with `name: <kebab-name>` |
| `description:` without `<example>` blocks (agent body > 2,500 words) | Fat agent that routes ambiguously without examples | Add 3-5 `<example>` blocks OR split into orchestrator + skills (preferred) |
| `description:` with "Use this agent for X" prose only | Vague routing, poor trigger | Rewrite with `PROACTIVELY activate for: (1)...` enumeration |
| Windows boilerplate inside YAML `description:` | Pollutes routing signal | Move to `## Windows file path requirements` in body |
| `model:` missing or hard-coded (e.g. `model: sonnet`) | Fails to inherit session model | Set `model: inherit` |
| Single `<example>` block with full code in `assistant:` | Dilutes matching, bloats description | Keep assistant replies to 1-2 sentences; put code in skills |

## Frontmatter Fields Reference

Detailed rules for each frontmatter field (`name`, `description`, `model`, `color`, `tools`) live in `references/frontmatter-fields-reference.md`. Highlights:

- **name** — kebab-case, 3-50 chars, alphanumeric start/end; role-based convention (`code-reviewer`, `domain-expert`).
- **description** — most critical field; must include `PROACTIVELY activate for: (1)... (N)...` enumeration and `Provides: ...` capability list. `<example>` blocks gated by the body-word-count tier table above.
- **model** — `inherit` is the default; only deviate with a documented capability reason.
- **color** — `blue`/`cyan` (analysis), `green` (generation), `yellow` (validation), `red` (critical/security), `magenta` (creative/architecture).
- **tools** — principle of least privilege; common: `Read, Write, Edit, Grep, Glob, Bash, WebSearch, WebFetch, Skill, Agent`. MCP tools as `mcp__server__tool`.

Load `references/frontmatter-fields-reference.md` when authoring or auditing a real agent.


## System Prompt Design

The markdown body becomes the agent's system prompt. Write in **second person** ("You are...", "You will..."). Required sections: Core Responsibilities, Process, Quality Standards, Output Format, Edge Cases. DO be specific and define output clearly; DON'T write in first person, be vague, or embed domain knowledge that belongs in skills. Full template + DO/DON'T list: `references/design-principles-and-mistakes.md`.

## Lean Orchestrator Pattern (CRITICAL)

An agent body must be a **lean orchestrator**, NOT a domain knowledge dump. The agent delegates to skills for detailed knowledge.

### Agent Body Size Limits

| Metric | Target | Hard Maximum |
|--------|--------|-------------|
| Word count | 1,500-2,500 words | 3,000 words |
| Character count | ~10,000-15,000 chars | 20,000 chars |

### What Belongs in the Agent Body

| Section | Required | Purpose |
|---------|----------|---------|
| Role identity | Yes | "You are [role] specializing in [domain]" |
| Skill activation rules | Yes | Topic-to-skill mapping table |
| High-level process | Yes | Design/workflow steps |
| Output format | Yes | What to include in responses |
| Brief service summaries | Optional | 2-3 sentences per area to help decide which skill to load |
| Edge cases / troubleshooting tips | Optional | Quick reference only |

### What Does NOT Belong in the Agent Body

- **Detailed domain knowledge** — belongs in skills
- **Complete CLI/API references** — belongs in skill references/
- **Full code examples** — belongs in skill examples/
- **Duplicated skill content** — if it's in a skill, do NOT repeat it in the agent

### Anti-Pattern: Content Duplication

**NEVER duplicate content between the agent body and skills.** This is the most common mistake and causes massive context bloat.

**Bad:** Agent body contains a full "Plugin.json Schema" section AND the plugin-master skill also contains it.
**Good:** Agent body says "For plugin.json schema details, load `plugin-master:plugin-master`" and keeps only a 1-sentence summary.

### Lean Orchestrator Template

```markdown
You are [role] specializing in [domain].

## Skill Activation - CRITICAL
[Topic-to-skill mapping table -- this is the heart of the agent]

## Core Responsibilities
[2-5 bullet points on what this agent does]

## Process
[5-7 step workflow for handling user requests]

## Quality Standards
[Brief checklist -- 5-10 items]

## Output Format
[What to include in responses]
```

### Description Size Limits

Agent descriptions should be concise and effective:

| Element | Guideline |
|---------|-----------|
| Intro text | 1-2 sentences on when to trigger |
| Example blocks | 3-7 blocks covering diverse scenarios |
| Total description | Should fit naturally — focus on quality trigger examples over length |

## Agent Design Principles & Common Mistakes

Detailed design principles (agent-first design, single responsibility, skill integration, preventing trigger phrase overlap) and the full Common-Mistakes table live in `references/design-principles-and-mistakes.md`. Core distillation:

- One expert agent per plugin, named `{domain}-expert`. Users converse, not navigate menus.
- Single responsibility per agent; multi-topic needs become skills, not new agents.
- Skill activation instructions belong in the system prompt.
- Trigger-phrase overlap between skills must be audited and disambiguated in the skill activation table.

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

Full table (vague descriptions, model overrides, tool over-grants, cross-cutting boilerplate in every skill, re-adding examples to a lean orchestrator, etc.) lives in `references/design-principles-and-mistakes.md`.

## Pre-recommendation intent check (audit caveat)

Before recommending a fix to an existing agent — especially one that involves re-adding content that has been stripped — confirm the apparent defect is not the result of a deliberate prior decision. Example-block stripping during lean-orchestrator refactors is routine and intentional; a follow-up audit that flags "agent missing examples" without checking word count produces a false-positive backlog of contradictory remediation work.

**Short rule:** before listing any agent finding, run the three-question intent check (size tier, git log, validator output). Only if all three say "real defect" should it appear in the audit report.

Full check, with rationale, expanded list of stripped-on-purpose patterns, and the authoring-vs-auditing contrast: see `references/validation-and-audits.md`.

## Validation by `scripts/validate_plugins.py`

The repo ships a read-only quality gate at `scripts/validate_plugins.py`. It is the single source of truth for what counts as "good" agent frontmatter in this marketplace. When the validator and this skill disagree, the validator wins.

**Quick invocations:**

```bash
python scripts/validate_plugins.py                    # whole marketplace
python scripts/validate_plugins.py --plugin my-plugin # one plugin
python scripts/validate_plugins.py --strict           # warnings fail the build
```

The complete rule tables (agent-level, skill-level, plugin-level) plus the list of known validator gaps live in `references/validation-and-audits.md`.
