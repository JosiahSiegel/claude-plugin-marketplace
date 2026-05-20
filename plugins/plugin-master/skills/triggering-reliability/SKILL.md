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

Three distinct caps apply to descriptions (see "Description length limits" below). Crossing the 1024-char API spec ceiling means the skill may be rejected by authoring tools or have its tail truncated. Even below the ceiling, descriptions over ~1000 chars typically indicate the skill is doing too much.

### Fix

- Target 400-1000 characters per skill or agent description.
- Hard ceiling: 1024 characters (Claude Code API spec).
- Front-load trigger keywords — the front of the description always survives any truncation.
- If you genuinely have 15+ triggers, split the skill into two focused skills.
- Collapse near-duplicate triggers into a single item.

## Audit process for an existing plugin

Run the audit sweeps from the repo root, in priority order (P0 → P2). Every row of output is a triggering bug. Fix earlier items first — they have larger blast radius.

The full bash and PowerShell sweep scripts (7 audit probes plus the positive-signal validation greps) live in `references/audit-greps.md`. The quick one-liners are also reproduced under **One-line greps for the canonical checks** at the bottom of this file.

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

Three caps apply to every skill/agent description:

| Cap | Value | What it means |
|---|---|---|
| **API spec hard ceiling** | 1024 chars | Hard ceiling per `description` field. Authoring tools reject anything over this. |
| **Listing-cap for matching** | 1536 chars | Combined `description` + `when_to_use` Claude sees when routing. Raised from 250 in v2.1.105. |
| **Aggregate budget** | ~1% of context window | Total across ALL installed skills. Over-budget (v2.1.129+) drops least-recently-used skills' descriptions rather than truncating. |

**Authoring targets:** target 400-1000 chars; hard ceiling 1024; front-load trigger keywords so the front survives any truncation; if you genuinely need 15+ triggers, split the skill rather than bloating the description.

## Precondition: size check before adding content to an existing skill

Before adding ANY new paragraph, table, or section to an existing SKILL.md, run a word-count check. The 3,000-word ceiling is a hard limit, not an aspiration — a SKILL.md that lands at 3,050 words is broken, not "close enough."

On bash/macOS/Linux:

```bash
wc -w plugins/<plugin>/skills/<skill>/SKILL.md
```

On PowerShell (Windows):

```powershell
(Get-Content plugins/<plugin>/skills/<skill>/SKILL.md | Measure-Object -Word).Words
```

**Decision rule:**

| Current word count | Action before adding content |
|---|---|
| < 2,500 words | Safe to add. Proceed. |
| 2,500-2,799 words | Add cautiously. After the addition, re-count; if over 2,800, start planning the extraction. |
| 2,800-3,000 words (within 200 of the ceiling) | **Extraction to `references/` is mandatory BEFORE adding.** Identify the largest reference-style section (detailed table, exhaustive checklist, full sweep script) and move it to `references/<topic>.md`, leaving a one-line pointer in SKILL.md. Then add the new content. |
| > 3,000 words | The skill is already broken. Do not add anything — extract until SKILL.md is back under 2,000 words. |

This precondition prevents the common failure mode where each individual addition looks small but the skill silently crosses the ceiling.

## Mandatory DRY-gate before any content add

Cross-cutting paragraphs, tables, and checklists that get pasted into multiple files are the #1 source of plugin bloat. Before adding any block longer than ~3 lines to a SKILL.md or reference file, run this grep from the plugin root:

```bash
# Replace FIRST_DISTINCTIVE_LINE with the first distinctive line of the candidate block.
grep -rn "FIRST_DISTINCTIVE_LINE" skills/ agents/ commands/ README.md
```

On PowerShell (Windows):

```powershell
Get-ChildItem -Recurse -Path skills,agents,commands,README.md -Include *.md -ErrorAction SilentlyContinue `
  | Select-String -Pattern 'FIRST_DISTINCTIVE_LINE'
```

**Decision rule** (from `skill-development` skill, "≥ 2 verbatim copies = extract" gate):

| grep finds the block in | Action |
|---|---|
| 0 other files | Safe to add. Proceed. |
| 1 other file (this will be the 2nd copy) | **STOP.** Extract to `skills/_shared/<topic>.md` (cross-skill) or `skills/<this-skill>/references/<topic>.md` (single-skill). Replace both call sites with a one-line pointer. |
| 2+ other files | Treat as a P1 bug. Extract immediately, then audit for further occurrences. |

This gate is mandatory, not advisory. Skipping it is the mechanism that lets identical canonical text drift into two or three files.

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
- [ ] No verbatim duplicate blocks across skills — the mandatory DRY-gate grep (see "Mandatory DRY-gate before any content add" above) has been run for every newly added block and any 2nd-copy hit was extracted to `skills/_shared/` or `references/` before commit
- [ ] No smart-punctuation inside fenced code blocks — see "Code-sample sanity pass" section below
- [ ] Every fenced code block has a language tag — see "Code-sample sanity pass" section below
- [ ] Every executable snippet is dual-form (POSIX + PowerShell) or explicitly platform-tagged — see "Code-sample sanity pass" section below
- [ ] Every SKILL.md is under the 3,000-word ceiling, and any skill within 200 words of the ceiling has had its largest reference-style sections extracted to `references/` (see "Precondition: size check before adding content to an existing skill" above)
- [ ] If the plugin ships any vendored, derived, or licensed third-party content, `NOTICES.md` exists at the plugin root, has no duplicate H2 sections for the same upstream, preserves required license text, and is cross-referenced from `README.md` and `plugin.json` where applicable (see `plugin-master` skill, `references/publishing-guide.md` publishing checklist)
- [ ] If a `marketplace.json` exists at repo root, the plugin is registered there with matching `description` and `keywords`

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

## One-line greps for the canonical checks

Run these from a plugin directory. Any output is a finding.

On bash/macOS/Linux:

```bash
grep -L "^---" skills/*/SKILL.md                                            # zero-frontmatter skills (P0)
grep -l "^agent: true" agents/*.md                                          # deprecated agents (P0)
grep -L "<example>" agents/*.md                                             # agents with no example blocks (P1)
grep -L "PROACTIVELY activate for:" skills/*/SKILL.md                       # skills missing trigger enumeration (P1)
grep -L "Provides:" skills/*/SKILL.md                                       # skills missing capability list (P1)
grep -L "^model: inherit" agents/*.md                                       # agents not inheriting model (P2)
grep -l "MANDATORY: Always Use Backslashes" agents/*.md skills/*/SKILL.md   # Windows boilerplate in YAML (P0)
```

On PowerShell (Windows), `references/audit-greps.md` carries the equivalent sweeps (probes 1-7) plus the positive-signal validation queries.
