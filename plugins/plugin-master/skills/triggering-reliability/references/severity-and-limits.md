# Severity tiers and description length limits

This reference holds two tables that are consulted during validation reporting but not during day-to-day authoring. They live here to keep the parent SKILL.md under its word-count ceiling.

## Severity table for validation reports

Use these tiers when reporting validation findings on a plugin:

| Tier | Meaning | Examples |
|---|---|---|
| **P0 - critical, must fix before ship** | Plugin will not load or component will not appear in discovery | plugin.json missing or invalid JSON; required field missing; wrong field type (`author` as string, `version` as number, `keywords` as string); skill with no YAML frontmatter; agent using deprecated `agent: true`; Windows/docs boilerplate inside YAML `description` (actively poisons routing) |
| **P1 - major, should fix before ship** | Plugin loads but triggers unreliably | Agent missing `<example>` blocks **when body > 2,500 words** (lean orchestrators under that threshold are exempt — see `agent-development` SKILL.md tier table); skill description missing `PROACTIVELY activate for:` / `Provides:` enumeration; description describes WHAT instead of WHEN; skill or agent description over 1024 characters (per Claude Code API spec hard ceiling — see length-limits table below) |
| **P2 - polish** | Cosmetic or efficiency improvements | Missing `model: inherit`, `color:`, or `tools:` (defaults apply); description over the 400-700 char target (still well under the 1024 hard ceiling); trigger-phrase overlap between sibling skills; SKILL.md body over 3,000 words |

## Description length limits (Claude Code, current as of 2026)

Three caps apply to every skill/agent description:

| Cap | Value | What it means |
|---|---|---|
| **API spec hard ceiling** | 1024 chars | Hard ceiling per `description` field. Authoring tools reject anything over this. |
| **Listing-cap for matching** | 1536 chars | Combined `description` + `when_to_use` Claude sees when routing. Raised from 250 in v2.1.105. |
| **Aggregate budget** | ~1% of context window | Total across ALL installed skills. Over-budget (v2.1.129+) drops least-recently-used skills' descriptions rather than truncating. |

**Authoring targets:** target 400-1000 chars; hard ceiling 1024; front-load trigger keywords so the front survives any truncation; if you genuinely need 15+ triggers, split the skill rather than bloating the description.
