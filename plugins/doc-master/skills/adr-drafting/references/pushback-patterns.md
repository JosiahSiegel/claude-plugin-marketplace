# Push-back patterns (Phase 4, step 2)

The skill must deliver **one scripted push-back per ADR** — verbatim, in the architect's face — before accepting the decision. The patterns below match common weak-reasoning shapes. Pick the one that fits and deliver it.

## Pattern 1 — "Industry standard"

**Trigger:** the architect justifies a choice as "best practice," "industry standard," or "what everyone does."

**Push-back:**

> This reads like a best practice, not a decision. What's the specific force in our context — number, deadline, constraint — making this the right call rather than a defensible-but-wrong one?

## Pattern 2 — Future-proofing

**Trigger:** the architect justifies with "this will scale," "this is future-proof," "we'll need this eventually."

**Push-back:**

> You're optimizing for forces you can't name. Decisions are made for known forces today; unknown future load is a re-evaluation trigger, not a decision driver. What's the **known** force today?

## Pattern 3 — Team familiarity alone

**Trigger:** the only reason is "the team knows X."

**Push-back:**

> Team familiarity is a real driver, but on its own it's a justification, not a decision. What architectural characteristic does this choice optimize for, separate from familiarity?

## Pattern 4 — One option deep, no alternatives

**Trigger:** the architect has not seriously considered alternatives, or names alternatives only to dismiss them in one line.

**Push-back:**

> You've named one option in depth and three in passing. Pick the strongest alternative you skipped and tell me — in one paragraph — why it loses. If you can't, you haven't decided yet; you've defaulted.

## Pattern 5 — Bundled decision

**Trigger:** the "decision" covers two or more independent choices (DB + ORM + hosting; framework + state library + bundler).

**Push-back:**

> This is two decisions in one ADR. Future-you will want to revisit them separately. Which one is primary, and which gets a follow-up ADR?

## Pattern 6 — Hedging confidence

**Trigger:** the architect rates confidence `low` but wants to mark the ADR `accepted`.

**Push-back:**

> Low confidence on a decided ADR is a smell. Either name the unknown that's blocking you (we'll PARK it) and ship as `proposed` with an RFC deadline, or do the work that would move confidence to `medium` or `high`, and come back.

## Pattern 7 — No failure mode

**Trigger:** Phase 4 step 1 asked for 2-3 failure modes and got vague answers ("if it doesn't work, we'll fix it") or no answer.

**Push-back:**

> "We'll fix it" is not a failure mode. Tell me: in production, what is the **specific** signal that this decision was wrong? Latency number, cost number, incident type, complaint from whom?

## Pattern 8 — Hidden cost

**Trigger:** the architect's "pros" section is long and the "cons" section is short or empty.

**Push-back:**

> The cons section is too short. Name the single biggest cost we're accepting by going this way — operational, financial, team-skills, vendor-lock-in, migration-debt. Every real decision has one.

## Pattern 9 — Decision-by-AI

**Trigger:** the architect cites "the model recommended," "most teams do this," or otherwise outsources the rationale.

**Push-back:**

> "What most teams do" is an abdication, not a justification. The Deciders field exists because humans decide. Tell me the local force — in our system, our team, our constraints — that makes this the right call.

## Pattern 10 — Solved-elsewhere

**Trigger:** the proposed "decision" is settled by a platform-level ADR, a corporate policy, a regulatory requirement, or a linter — i.e., not a decision the team is empowered to make.

**Push-back:**

> This isn't a decision we're making — it's a decision someone else already made and we're inheriting. Cite the upstream source (platform ADR, policy, regulation) and skip the ADR; a one-line note in `CONTRIBUTING.md` or the relevant module is enough.

## How to deliver

- One pattern per ADR. Picking more than one in a single push-back dilutes them.
- Quote the architect's words when possible: "You said 'industry standard' — …"
- Wait for the architect's response. Do **not** accept the decision until they've engaged.
- If their response strengthens the rationale, record the strengthened version in the Decision section.
- If they cannot answer, route to `adr-discovery` or downgrade to RFC.

## Phrases that are NOT push-back

- "Great point, but…"
- "I love this decision, just one thing…"
- "Looks good overall, minor nit…"

These are affirmations. They defeat the purpose. Use a plain, direct opening: "Push-back:" or just the question.
