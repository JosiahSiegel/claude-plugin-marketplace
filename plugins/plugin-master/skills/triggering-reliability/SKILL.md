---
name: triggering-reliability
description: |
  Catalog of common mistakes that break Claude Code agent and skill triggering, plus marketplace validation rules.
  PROACTIVELY activate for: (1) plugins installed but never trigger, (2) agents failing to route, (3) skills not appearing in discovery, (4) pre-release triggering audit, (5) migrating deprecated agent true flag, (6) zero-frontmatter SKILL.md files, (7) boilerplate in YAML descriptions, (8) abstract descriptions, (9) missing example blocks on fat agents above 2,500 words, (10) missing PROACTIVELY or Provides sections, (11) running validate_plugins.py, (12) auditing a plugin without contradicting earlier intentional refactors.
  Provides: anti-patterns, fixes, before/after examples, audit checklist, and validator rule index.
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

## Nine canonical anti-patterns (summary)

Full symptom / root cause / fix narrative for each lives in `references/anti-patterns-catalog.md`. Quick table:

| # | Anti-pattern | Severity | One-line fix |
|---|---|---|---|
| 1 | Zero-frontmatter skill — no `---` | P0 | Add canonical YAML frontmatter (`name:`, `description:`) |
| 2 | Deprecated `agent: true` flag | P0 | Replace with `name: <kebab>` |
| 3 | Abstract "Use this agent for X" description | P1 | Rewrite with `PROACTIVELY activate for: (1)... (N)...` and `Provides:` |
| 4 | Description describes WHAT, not WHEN | P1 | Flip to user-intent triggers; lead with `PROACTIVELY activate for:` |
| 5 | Fat agent (>2,500 words) missing `<example>` blocks | P1 | Add 3-5 example blocks; lean orchestrators exempt |
| 6 | Windows/docs boilerplate inside YAML `description:` | P0 | Move boilerplate to a named body section |
| 7 | Missing or hard-coded `model:` field | P2 | Set `model: inherit` |
| 8 | Trigger-phrase overlap across skills | P1 | Assign exclusive ownership; add disambiguation in skill activation table |
| 9 | Description over 1024 chars or 15+ diluted triggers | P1 | Trim to 400-1000 chars; front-load triggers; split skill if needed |

The "lean orchestrator with no examples" shape is **not** anti-pattern 5 — see the tier table in `agent-development` and the audit caveat in `agent-development/references/validation-and-audits.md` before re-adding examples during an audit.

### Description length caps (from anti-pattern 9)

- **400-1000 characters** — recommended target.
- **1024 characters** — Claude Code API spec hard ceiling. Never exceed.
- **1536 characters** — current listing cap (combined description + when_to_use, v2.1.105+).
- **~1% of context window** — aggregate budget across all installed skills.

Front-load triggers — the front of the description survives any truncation.

## Audit process for an existing plugin

Run the audit sweeps from the repo root, in priority order (P0 → P2). Every row of output is a triggering bug. Fix earlier items first — they have larger blast radius.

The full bash and PowerShell sweep scripts (7 audit probes plus the positive-signal validation greps) live in `references/audit-greps.md`. The quick one-liners are also reproduced under **One-line greps for the canonical checks** at the bottom of this file.

## Per-mistake fix priority

1. **P0** - zero-frontmatter skills and `agent: true` agents (invisible/broken).
2. **P0** - Windows/docs boilerplate inside YAML (actively poisons routing).
3. **P1** - missing `<example>` blocks on fat agents (body > 2,500 words) that back multiple skills. Lean orchestrators under the 2,500-word threshold are exempt by design.
4. **P1** - descriptions missing `PROACTIVELY activate for:` / `Provides:` enumeration.
5. **P2** - metadata hygiene (`model: inherit`, `color:`, `tools:` tightening).
6. **P2** - trigger-phrase overlap audit and disambiguation.

Fix in priority order - do not spend time on P2 while P0 bugs exist.

## Severity tiers and description length limits

When reporting findings, use P0 / P1 / P2 tiers (plugin-breaking / routing-unreliable / polish). Description length is governed by three caps: 1024-char API spec hard ceiling, 1536-char listing cap that Claude sees during routing, and a ~1% context-window aggregate budget across all installed skills.

Full tier table with concrete examples for each severity, the description-length cap table with values and meanings, and the authoring targets: see `references/severity-and-limits.md`.

## Pre-commit size and DRY gates (mandatory)

Two gates run before any content addition to a SKILL.md or reference file:

1. **Size gate** — `wc -w` (or PowerShell `Measure-Object -Word`) the target file. If it is in the 2,800-3,000 word band, extract a reference-style section to `references/` BEFORE adding. Over 3,000 words = already broken, extract down to under 2,000 before doing anything else.
2. **DRY gate** — `grep -rn` (or `Select-String`) the first distinctive line of the candidate block across `skills/`, `agents/`, `commands/`, `README.md`. Even one hit elsewhere means the block must be extracted to `skills/_shared/` (cross-skill) or `references/` (single-skill) instead of pasted.

Full decision tables, exact commands for bash and PowerShell, and the combined workflow: see `references/size-and-dry-gates.md`.

## Canonical pre-publish checklist

The full 26-item checklist (plugin.json shape, agent and skill frontmatter, description content, DRY-gate grep, code-sample sanity, size ceilings, NOTICES.md, marketplace.json registration) lives in `references/pre-publish-checklist.md`. Run every item before shipping.

## Code-sample sanity pass

Two defects routinely slip into fenced code blocks and silently break readers:

1. **Smart punctuation** (curly quotes, em/en dashes, Unicode ellipsis) inside fenced code blocks breaks copy-paste — grep stops matching, JSON fails to parse, shell quoting falls apart. Authors typing in editors with autocorrect on, or pasting from word processors, introduce these without noticing.
2. **Missing language tags** on fenced code blocks (opening with bare ```` ``` ```` instead of ```` ```bash ```` / ```` ```powershell ```` / ```` ```yaml ````) disable syntax highlighting and, worse, hide the platform assumption. A bash-only snippet that renders as plain text looks identical to a PowerShell snippet — a Windows reader will copy it and watch it fail with no signal as to why.

**Code-sample sanity checklist — run before every ship.** Each unchecked item is a finding to fix manually.

- [ ] No smart-punctuation codepoints (U+2026, U+201C/D, U+2018/9, U+2013/4) inside any fenced code block. Replace with the ASCII equivalent: `...`, `"`, `'`, `-`.
- [ ] Every fenced code block opens with a language tag (e.g. ```` ```bash ````, ```` ```powershell ````, ```` ```yaml ````, ```` ```json ````, ```` ```python ````, ```` ```markdown ````). Bare ```` ``` ```` openings are a defect.
- [ ] Every executable snippet is either **dual-form** (shows both POSIX and PowerShell variants) or **explicitly platform-tagged** with a one-line prose marker such as `On bash/macOS/Linux:` or `On PowerShell (Windows):` immediately before the fence, and the fence language tag matches.

This repo's primary shell is PowerShell on Windows, so a bash-only snippet without a platform tag is a defect.

**Sweeps and full character tables:** see `references/code-sample-sanity.md` for the bash and PowerShell sweep scripts (smart-punctuation probe and fence-language-tag probe), the canonical smart-quote → ASCII fix table, and the list of recognised language tags.

## Validator as canonical quality gate

The single source of truth for what counts as a "real" triggering defect in this marketplace is `scripts/validate_plugins.py`. Manual greps below help locate findings; the validator is what decides whether they ship.

```bash
python scripts/validate_plugins.py                    # whole marketplace
python scripts/validate_plugins.py --plugin my-plugin # one plugin
python scripts/validate_plugins.py --strict           # warnings fail the build
```

Key validator rules with bearing on this skill:

| Validator check | Severity | Maps to |
|---|---|---|
| `Skill missing frontmatter` | error | Anti-pattern 1 |
| `Deprecated agent: true` | error | Anti-pattern 2 |
| `Skill missing PROACTIVELY` / `Provides` | warning | Anti-patterns 3-4 |
| `Agent missing PROACTIVELY` / `Provides` | warning | Anti-patterns 3-4 |
| `Agent missing examples` | warning | Anti-pattern 5 — fires only when agent body > 2,500 words |
| `Agent missing model: inherit` | error | Anti-pattern 7 |
| Description / SKILL.md length checks | error/warning | Anti-pattern 9 + size ceiling |

The complete validator rule index (agent, skill, and plugin level) plus known validator gaps lives in `agent-development/references/validation-and-audits.md`. Keep that table and the validator code in lockstep.

## Audit caveat: check intent before recommending fixes

When auditing an existing plugin, an apparent defect is not automatically a real defect — it may be the deliberate output of a prior refactor. The canonical example: example blocks stripped from lean orchestrators during a fat-to-lean refactor. A follow-up audit that recommends re-adding them would undo the refactor.

Before listing any agent or skill finding in an audit report, run the three-question intent check:

1. **Word count tier** — Does the current size of the agent/skill make the apparent defect a defect, or is it exempt by design?
2. **Git log** — Was the absent content recently removed on purpose? Look for refactor commits.
3. **Validator output** — Does `scripts/validate_plugins.py` flag it? If not, do not invent stricter rules in the audit than the validator enforces.

Only when all three return "real defect" does it belong in the remediation list. Full rationale, the broader list of "stripped on purpose" patterns to watch for, and the authoring-vs-auditing contrast: `agent-development/references/validation-and-audits.md`.

## One-line greps for the canonical checks

Run these from a plugin directory. Any output is a finding.

On bash/macOS/Linux:

```bash
grep -L "^---" skills/*/SKILL.md                                            # zero-frontmatter skills (P0)
grep -l "^agent: true" agents/*.md                                          # deprecated agents (P0)
grep -L "<example>" agents/*.md                                             # agents with no <example> blocks - cross-check body word count before flagging (lean orchestrators under 2,500 words are exempt; see agent-development tier table)
grep -L "PROACTIVELY activate for:" skills/*/SKILL.md                       # skills missing trigger enumeration (P1)
grep -L "Provides:" skills/*/SKILL.md                                       # skills missing capability list (P1)
grep -L "^model: inherit" agents/*.md                                       # agents not inheriting model (P2)
grep -l "MANDATORY: Always Use Backslashes" agents/*.md skills/*/SKILL.md   # Windows boilerplate in YAML (P0)
```

On PowerShell (Windows), `references/audit-greps.md` carries the equivalent sweeps (probes 1-7) plus the positive-signal validation queries.
