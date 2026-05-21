---
name: adr-drafting
description: |
  This skill should be used when a decision is ready to become an ADR and the user wants co-thinking rather than template filler.
  PROACTIVELY activate on "draft the ADR", "write up the decision", "co-think this ADR", "challenge my reasoning", "ADR for X", "MADR for X", "Y-statement for X", "we decided to use X", "co-draft", "ADR drafting", or "scripted push-back."
  Provides: seven-phase ADR drafting, one-question turns, failure-mode pressure test, and self-critique against the ADR-is-NOT checklist.
---

# adr-drafting

Co-drafts an ADR through structured dialogue. The architect never sees a first draft — only the self-critiqued revision.

## Inputs

- **Required:** `docs/architecture/discovery-brief.md` with all five MUSTs `CONFIRMED`. If missing or shallow, this skill refuses and routes to `adr-discovery`.
- **Optional:** `docs/architecture/open-questions.md`. `PARKED` MUSTs must be cited in the resulting ADR's Consequences.

## Core operating rule

**Never emit more than one question or one step per message.** If a turn contains two `?`, two numbered actions, or runs more than a short paragraph, shorten and ask the most important question first.

## Style

- Direct. No "Great question!", "Excellent point!", or "Solid approach!".
- Bullet-driven, not narrative.
- Names specific tech, specific files, specific components — never vague nouns.
- Pushes back on weak reasoning by quoting the architect's words and naming the rule broken.

## Vocabulary (define on first use)

- **Component** — a runnable / deployable unit (C4 Container), not a code class.
- **System** — one bounded product per ADR.
- **Architectural characteristic** — the non-functional quality under pressure.
- **Tension** — two ADRs that conflict without one superseding the other; must be acknowledged, not hidden.
- **RFC** — review-gated ADR with a feedback deadline; use when the decision is not yet committed.
- **Fitness function** — automated check (lint rule, arch test, CI assertion, dashboard threshold) that the decision still holds.

## The seven phases

### Phase 1 — Understand

Read `discovery-brief.md`. Do **not** re-ask anything in it. Ask only for the MUSTs not already confirmed:

| MUST | Default question |
|---|---|
| Purpose of the decision | "In one sentence: what decision are we recording?" |
| Architectural characteristic under pressure | "Which quality is forcing this — latency, cost, availability, security, maintainability, something else? Name the number or condition." |
| Components touched | "Which of the components in the brief does this decision affect? (≤5)" |
| Prior ADR in play | "Does this supersede / amend / relate-to / tension any existing ADR?" |
| Decider | "Who is accountable for this decision? Named human(s)." |

**Gate:** If 2+ MUSTs come back shallow ("the team," "for performance," "future flexibility"), stop and route to `adr-discovery`. Do not advance.

### Phase 2 — Context

Walk each ADR returned by Phase 1's "prior ADR" question, one at a time. For each, classify in dialogue:

- `supersedes` — this decision replaces it
- `amends` — this decision adjusts without replacing
- `relates-to` — this decision shares context but stands alone
- `tension` — incompatible without one superseding
- `unrelated` — drop it

Glob the ADR directory once to confirm the architect didn't miss any.

### Phase 3 — Options

The architect lists the options. **Not the agent.** If they offer one option, ask: "What else is realistic?"

Walk each option across **four separate exchanges**:

1. Pro — "What's the single strongest argument for this option?"
2. Con — "What's the single strongest argument against this option?"
3. Effort — "Roughly: hours, days, or weeks to implement?"
4. Risk — "If this option fails, how do you find out and how bad is it?"

Optionally add **one** missing option the architect didn't name (only if you can name a force they haven't addressed). Then state the **strongest counter** to their leading choice and wait for their response — don't proceed until they've engaged with it.

### Phase 4 — Decide

Four separate exchanges:

1. Failure modes — "Name 2-3 ways this decision fails in production." Refuse to advance until the architect names them.
2. Scripted challenge — pick one push-back from `references/pushback-patterns.md` that matches the leading option, deliver it verbatim, wait.
3. Confidence — "On a 1-5 scale, how confident is the decider? What would move them to 5?"
4. Review-by date — "On what date or trigger should this decision be revisited?"

**RFC routing:** If confidence is `low`, the architect isn't a single named human, or the decision touches > 5 components, propose `status: proposed` with `rfc-deadline` (default: two weeks) instead of `accepted`. ADRs serving as RFCs are still real ADRs — they just have a deadline before they harden. If the team also wants a numeric score, store it in `confidence-score`; keep `confidence` as `high`, `medium`, or `low`.

### Phase 5 — Draft

Section by section. Confirm each before moving to the next. **Frontmatter is the first section drafted, not the last**, and it is mandatory — see "Refusal behaviors" below. Hard limits enforced:

| Section | Limit | Notes |
|---|---|---|
| Frontmatter | YAML between `---` fences | Mandatory. `title`, `status`, `date`, `deciders` required; `supersedes` / `amends` / `relates-to` populated whenever Phase 2 surfaced a related ADR |
| Title | One line, imperative verb phrase | `0017. Use Postgres for primary store` |
| Context | ≤ 3 sentences | The forces — not the history |
| Decision | ≤ 3 sentences | Active voice, present tense |
| Consequences | Bullets only | Good, because… / Bad, because… |
| Compliance | 1-3 sentences | Fitness function snippet allowed |
| Alternatives | Bullets, one-paragraph each | One con per alternative is enough |
| More Information | Optional sub-sections, **`### Relationships` required if frontmatter relationships exist** | Mirrors frontmatter `supersedes` / `amends` / `relates-to` using the link-prefix vocabulary documented in `references/template-fields.md` (`Supersedes`, `Superseded by`, `Amends`, `Amended by`, `Related to`). Parsers that scan body links instead of frontmatter rely on this section. |
| Notes | Optional | PARKED open questions cited here. Not a substitute for the Relationships mirror above. |

**Default body structure:** unless the project's existing decision log already uses a different convention (Nygard plain, Y-statement, arc42, Tyree-Akerman), default to **MADR (currently 4.0.0)**: `## Context` (or `## Context and Problem Statement`) → `## Decision` (or `## Decision Outcome`) → `## Consequences` → `## Compliance` → `## Alternatives Considered` → `## More Information` (with `### Relationships` when relationships exist). If the project has an existing template, follow it. Upstream MADR template: [adr.github.io/madr/](https://adr.github.io/madr/), source repo [github.com/adr/madr](https://github.com/adr/madr).

### Phase 6 — Self-Critique

**The architect does not see the Phase 5 output yet.** Self-critique against `../_shared/adr-is-not.md` first, flagging violations one at a time using this template:

```yaml
Original: <verbatim line>
Violates: <which rule from adr-is-not.md>
Rewrite:  <shorter, stricter replacement>
Apply?    (yes / no / adjust)
```

One violation per message. Wait for the architect's reply before flagging the next.

Show the **full final draft** only when all violations are resolved or accepted.

### Phase 7 — Save

1. Glob ADR Explorer-friendly directories first: `docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `**/adr/*.md`; also check legacy `architecture/decisions/` but warn it may need custom ADR Explorer root configuration. Use the first existing directory; if none, create `docs/adr/`.
2. Auto-number: read existing ADRs, take `max+1`, zero-pad to 4 digits.
3. Filename: `NNNN-kebab-imperative-title.md` (must start with the numeric id).
4. Write the file.
5. Update the index in the directory's `README.md` (create if absent).
6. Echo cross-link instructions for `supersedes` / `amends` / `relates-to` so the architect can update the linked ADRs in a separate pass. Remind them that **ADR-graph tooling splits into two families**:
   - Gray-matter-style parsers (e.g., ADR Explorer) read **frontmatter only**. The keys `supersedes`, `amends`, and `relates-to` produce edges. Body prose (`superseded-by` text on the old ADR, `Related ADRs:` lines, index-hub links) is invisible.
   - Body-scanning parsers (e.g., ADR Manager) walk the rendered Markdown looking for ADR-to-ADR links under MADR-style sections (originally `## Links`, now community-conventionally `## More Information` with a `### Relationships` sub-section). Frontmatter is invisible.
   The ADR just saved already contains both because Phase 5 enforces the mirror. The linked ADRs the architect updates in a separate pass must also follow the mirror convention. Use zero-padded four-digit ID strings (`"0008"`) in frontmatter lists for stable rendering, though bare integers also parse. If Accepted ADRs are immutable in this repo, ask whether metadata-only relationship-link maintenance (frontmatter + the body Relationships mirror) is allowed or needs an explicit governance exception.

## Template (canonical fields)

YAML frontmatter is **mandatory** and goes first. The body uses MADR (currently 4.0.0) by default and **mirrors every frontmatter relationship into a `### Relationships` block under `## More Information`** so the ADR renders edges in both classes of tooling: gray-matter-style parsers that read frontmatter, and parsers that scan body links under MADR-style sections.

```md
---
title: "<imperative verb phrase>"
status: proposed | accepted | superseded | deprecated
date: 2026-05-20
deciders:
  - <named human>
supersedes: []  # ADR ids (zero-padded 4-digit strings) this decision replaces
amends: []      # ADR ids this decision adjusts without replacing
relates-to:     # the only three keys that create graph edges in frontmatter-scanning parsers
  - id: "0000"
    reason: "one-line reason"
tags: []
review-by: 2026-11-20  # or trigger e.g. "100k DAU"
expires: 2027-05-20    # optional; only when expiry is real
confidence: high | medium | low
confidence-score: 4    # optional numeric score
rfc-deadline: 2026-06-03  # only when status == proposed and acting as RFC
---

# NNNN. <Title>

## Context
≤ 3 sentences. The forces.

## Decision
≤ 3 sentences. Active voice.

## Consequences
- Good, because …
- Bad, because …

## Compliance
1-3 sentences. Fitness-function snippet if appropriate.

## Alternatives Considered
- Option B -- one paragraph, single strongest con.
- Option C -- one paragraph, single strongest con.

## More Information

### Relationships

Mirror every frontmatter relationship here using the link-prefix vocabulary. Required when frontmatter `supersedes` / `amends` / `relates-to` is non-empty.

- Supersedes [ADR-0004](0004-old-decision.md) -- replaced because <reason>.
- Related to [ADR-0011](0011-tenancy.md) -- shares the tenancy model.

### Notes
Optional. PARKED open questions cited here.
```

**Mirror both surfaces.** Frontmatter feeds gray-matter parsers (ADR Explorer); body `### Relationships` under `## More Information` feeds body-scanning parsers (ADR Manager). Either surface alone leaves the ADR half-rendered; the two must agree. Full rationale, field semantics, and the link-prefix vocabulary live in `references/template-fields.md`.

## Refusal behaviors

The skill **refuses to draft** when:

- `discovery-brief.md` has any MUST not `CONFIRMED`
- The architect names "the team" instead of a human as decider
- Failure modes are not articulated (Phase 4, step 1)
- More than 5 components are in scope (route to splitting the decision)

The skill **refuses to save** when:

- Self-critique flags remain unresolved (Phase 6 not complete)
- Numbering would collide with an existing ADR
- The file does not begin with a `---` YAML frontmatter block containing **at minimum** `title`, `status`, `date`, and `deciders` (and `supersedes` / `amends` / `relates-to` whenever Phase 2 surfaced any related ADR).
- Frontmatter populates `supersedes`, `amends`, or `relates-to` but the body has no `## More Information` → `### Relationships` mirror, or vice versa. Either surface alone leaves the ADR invisible to half the tooling; the two must agree.

## References

- `references/template-fields.md` — full semantics for every frontmatter field and section
- `references/pushback-patterns.md` — scripted push-backs for Phase 4
- `references/rfc-routing.md` — when an ADR should be RFC status with a deadline
- `../_shared/adr-is-not.md` — the canonical "ADR is not" checklist used in Phase 6
- The `adr-discovery` skill for upstream context gathering
- The `c4-model` skill for diagrams alongside the ADR
- The `adr-critique` skill for audits of legacy / external ADRs not drafted via this flow
