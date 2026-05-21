# Agent validation and audit caveats

This reference expands the agent-development SKILL.md on two related topics:

1. How `scripts/validate_plugins.py` enforces agent rules in this marketplace.
2. How to avoid the "contradictory audit" failure mode where a follow-up review recommends re-adding content that an earlier refactor deliberately removed.

## Pre-recommendation intent check (audit caveat)

Before recommending a fix to an existing agent — especially one that involves re-adding content that has been stripped — confirm that the apparent defect is not the result of a deliberate prior decision. This caveat exists because example-block stripping during lean-orchestrator refactors is a routine and intentional operation, and a follow-up audit that flags "agent missing examples" without checking word count produces a false-positive backlog of contradictory remediation work.

### Three-question check before listing an agent issue in an audit report

1. **What does the size tier say?** Compute the agent body word count. If it's under 2,500 words, the lean-orchestrator rule applies and missing examples are by design. The tier table lives in `SKILL.md` under "Example-block requirement by agent body size".
2. **What does `git log` say?** Has the agent been touched in a recent refactor that explicitly removed examples? A commit message like "lean orchestrator refactor" or "stripped redundant example blocks" is a strong signal that the absence is intentional.
3. **What does `scripts/validate_plugins.py` say?** Run the validator on the plugin. If it does not flag the agent, the absence is consistent with current marketplace policy. Do not invent stricter rules in the audit than the validator enforces.

Only after all three questions return "the defect is real" should missing examples appear as a remediation item.

### Why this matters

The first-encounter failure mode that produced this reference: an earlier pass through the marketplace refactored fat agents into lean orchestrators and deliberately stripped `<example>` blocks below the 2,500-word threshold. A subsequent validator-and-audit pass then flagged every one of those agents as "missing examples" and recommended re-authoring them — which would have undone the refactor. The fix is structural: gate the example-block check on body word count (already in the validator) AND require auditors to check intent before listing example-block findings (this caveat).

The same pattern applies to other "stripped on purpose" content:

- Cross-cutting boilerplate moved from skill YAML descriptions to a shared body section — do not re-add it to YAML during a later sweep.
- Domain-knowledge dumps moved from agent bodies into skills — do not pull them back into the agent body during a "completeness" audit.
- Trigger-phrase enumerations consolidated to remove overlap — do not re-broaden them during a later "trigger coverage" audit.

In all of these cases the corrective action is the same: read the recent commit history, identify the intent behind the absence, and either honour it or open a discussion to revisit the design — never silently re-add removed content.

## Validation by `scripts/validate_plugins.py`

The repo ships a read-only quality gate at `scripts/validate_plugins.py`. It is the single source of truth for what counts as "good" agent frontmatter in this marketplace. When the validator and the SKILL.md disagree, the validator wins — open a PR to bring the SKILL.md back into sync rather than working around the validator.

### Agent-level rules the validator enforces (current as of 2026)

| Check | Severity | What triggers it |
|---|---|---|
| `Agent missing model: inherit` | error | Frontmatter does not contain the literal line `model: inherit` |
| `Deprecated agent: true` | error | Frontmatter contains the legacy `agent: true` flag |
| `Agent description too long` | error | Description exceeds 1024 characters (Claude Code API spec ceiling) |
| `Agent missing PROACTIVELY` | warning | Description does not contain `PROACTIVELY` |
| `Agent missing Provides` | warning | Description does not contain `Provides` |
| `Agent oversized` | warning | Agent body exceeds 3,000 words (the hard ceiling) |
| `Agent missing examples` | warning | Agent body exceeds 2,500 words AND no `<example>` block is present (lean orchestrators under 2,500 words are exempt) |
| Code-fence checks | warning | Smart-punctuation inside a fence, or a bare opening fence with no language tag |

### Skill-level rules the validator also enforces

| Check | Severity | What triggers it |
|---|---|---|
| `Skill missing frontmatter` | error | SKILL.md does not begin with YAML frontmatter |
| `Skill description too long` | error | Description exceeds 1024 characters |
| `Skill missing PROACTIVELY` | warning | Description does not contain `PROACTIVELY` |
| `Skill missing Provides` | warning | Description does not contain `Provides` |
| `Skill oversized` | error | SKILL.md exceeds 3,000 words |
| `Skill over target` | warning | SKILL.md exceeds 2,000 words (target) |

### Plugin-level rules

| Check | Severity | What triggers it |
|---|---|---|
| `Missing plugin.json` | error | `.claude-plugin/plugin.json` absent |
| `Missing required fields` | error | `plugin.json` missing `name`, `version`, `description`, or `author` |
| `Name mismatch` | error | `plugin.json` name does not match the marketplace registration |
| `Version mismatch` | error | `plugin.json` version does not match the marketplace entry |
| `Description too long` | error | `plugin.json` description exceeds 1024 characters |
| `Orphan working files` | error | `.bak`, `.tmp`, or `.draft` files exist under `plugins/` |
| `Unregistered plugin directory` | warning | A directory under `plugins/` is not in `marketplace.json` |

### Recommended invocations

```bash
python scripts/validate_plugins.py                    # whole marketplace
python scripts/validate_plugins.py --plugin my-plugin # one plugin
python scripts/validate_plugins.py --strict           # warnings fail the build
python scripts/validate_plugins.py --json             # machine-readable
```

### Known gaps in the current validator

The current implementation does not yet flag:

- Project-specific references (company names, internal repo paths) that violate the public-marketplace constraint.
- `tools:` field schema (presence and shape) — currently advisory only.
- Trigger-phrase overlap between sibling skills (this remains a manual audit step).
- Cross-skill duplicate content blocks (the DRY-gate is a manual grep, not a validator pass).

If you want to add or change a rule, change the validator first and update the table in this reference and the SKILL.md tier table in lockstep.

## Authoring vs. auditing: a quick contrast

| Activity | Primary question | Primary tool |
|---|---|---|
| Authoring a new agent | "Will this agent route reliably for the queries I care about?" | The tier table in SKILL.md; the canonical frontmatter template |
| Auditing an existing agent | "Is each apparent defect a real defect or a deliberate prior choice?" | The three-question intent check above + `scripts/validate_plugins.py` |

Treating these as the same activity is the proximal cause of the contradictory-audit failure mode this reference exists to prevent.
