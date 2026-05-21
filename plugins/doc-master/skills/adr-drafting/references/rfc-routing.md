# RFC routing — when an ADR should ship as `status: rfc`

ADRs are for **made decisions**. When the decision is not yet committed, shipping it as `status: accepted` is a top failure mode (premature ADR), but losing it in chat is also a failure mode. RFC status splits the difference: it's still in the ADR log, still numbered, still discoverable — but it has a deadline.

## Default to RFC when any of these are true

1. **Confidence ≤ 3.** The decider is not yet sure. An RFC window gives the team a structured period to surface objections.
2. **Decider is not a single named human.** "The team" or "leadership" cannot accept an ADR; an RFC lets the team converge on the decider.
3. **Touches > 5 components.** Likely the decision is bundled (route to splitting) — but if it genuinely spans many surfaces, an RFC widens the review.
4. **Touches multiple repos / multiple teams.** An RFC's deadline forces upstream teams to weigh in or implicitly consent.
5. **The decision touches a platform-level concern** (auth, data residency, observability) where another team has standing to object.
6. **Significant migration cost** — once committed, the cost of un-committing is high. The RFC window is the last cheap moment to object.

## Default to `accepted` (not RFC) when all of these are true

- Confidence ≥ 4
- Single named decider with authority
- Scope is one repo, ≤ 5 components
- No platform / cross-team implications
- Migration cost is recoverable within days

## RFC mechanics

| Field | Value |
|---|---|
| `status` | `rfc` |
| `rfc-deadline` | ISO date — default two weeks from drafting |
| `deciders` | Still required; the decider commits to flipping the status to `accepted` or `rejected` by the deadline |

The body of an RFC ADR is **the same as an accepted ADR**. The only differences are:

- The `status` field
- A required `rfc-deadline`
- The Consequences section may include `Pending review` items that will resolve into concrete consequences after acceptance

## Status transitions at the deadline

```text
  rfc + objections resolved   --> accepted
  rfc + decider declines      --> rejected
  rfc + deadline passes silently --> NOT auto-accepted
```

**Silent deadlines do not auto-accept.** If nobody objected and nobody actively accepted, the decider must still flip the status manually. Silent consent in ADRs is a well-known failure mode (decisions in limbo).

## Migration after RFC closes

When an RFC becomes `accepted`:

1. Update `status` from `rfc` to `accepted`.
2. Update `date` to the acceptance date (not the RFC drafting date).
3. Remove `rfc-deadline`.
4. Resolve any `Pending review` notes in Consequences into concrete consequences.
5. Update the decision-log index `README.md`.

When an RFC becomes `rejected`:

1. Update `status` to `rejected`.
2. Keep the body — a rejected ADR with good "why not" reasoning is a real asset for future decisions.
3. Update the index.

## RFC and `proposed`: pick one

Some teams use `proposed` for the same purpose. Both are valid. The skill defaults to `rfc` because:

- `proposed` has no deadline by convention, so proposed ADRs accumulate forever (top failure mode).
- `rfc` carries a deadline as a required field, forcing closure.

If the project already uses `proposed`, the skill adopts that convention rather than introducing both. Document the project's stance in the decision log's `README.md` and stick to it.
