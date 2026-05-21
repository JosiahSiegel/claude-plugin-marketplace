# Postmortem canon — blameless incident review

The canonical reference for postmortems. Load this when the user says "we had an outage last week," "write up the incident," or "schedule a postmortem."

A postmortem records **what happened, why, and what changes the team commits to** after a notable incident. It is **blameless by construction** — the document focuses on systems, processes, signals, and decisions, never on individuals.

## Two sources, distinct roles

doc-master distinguishes the **template** (the file you fill in) from the **cultural framing** (the discipline that determines whether the document is useful).

| Source                                                                               | Role                          | Use                                              | Licensing notes                                                       |
|--------------------------------------------------------------------------------------|-------------------------------|--------------------------------------------------|-----------------------------------------------------------------------|
| [PagerDuty Incident Response — Post-Mortem Template](https://response.pagerduty.com/after/post_mortem_template/) | The template itself.          | Copy the sections, adapt the wording.            | Open / copyable. Cite as "PagerDuty Incident Response open templates."|
| [Google SRE Workbook, Ch. 10 — Postmortem Culture](https://sre.google/workbook/postmortem-culture/) | The cultural framing.          | Read the chapter; do not copy.                   | CC BY-NC-ND — **link only, do not embody**.                           |

doc-master writes from the PagerDuty template and links to the Google SRE chapter for the cultural framing.

## Required sections (PagerDuty template)

A doc-master postmortem includes these sections, in this order:

1. **Incident Summary** — one paragraph: what, when, who saw it, severity.
2. **Leadup** — what was in flight before the incident: deploys, config changes, traffic shifts, dependency upgrades, holiday weekends. Factual, not causal.
3. **Fault** — the specific failure: which component, which mode, which contract was violated.
4. **Impact** — measurable customer effect: users affected, requests dropped, revenue lost, SLO budget consumed, regulatory implications. Use numbers.
5. **Detection** — how the team learned about it: alert, customer report, internal observation. Note the latency between the fault and detection.
6. **Response** — what the team did, in order. Who was paged. Which runbook fired. Where the response stalled.
7. **Recovery** — what restored service. Whether the recovery was clean (graceful rollback) or messy (manual intervention, lingering effects).
8. **Timeline** — UTC timestamps, single source of truth. Cross-references every other section.
9. **Root Causes** — Five Whys (or equivalent technique). Multiple causes are expected and named separately, not collapsed into one.
10. **Action Items** — what changes the team commits to, each with an owner, a due date, and a tracking ID. Avoid "improve monitoring" — name the specific dashboard, the specific alert, the specific code change.
11. **Lessons Learned** — what generalizes beyond this incident. What the team understands now that it did not understand before.

## When to write a postmortem — predefined triggers

A postmortem is **not** discretionary. The team agrees the triggers in advance, in writing, and writes one for any incident that hits them:

| Trigger                                                  | Examples                                                                              |
|----------------------------------------------------------|----------------------------------------------------------------------------------------|
| Severity threshold                                       | SEV-1 / SEV-2 / "P0" — whatever the org's convention is.                              |
| Customer-facing outage                                   | Anything customers noticed, even briefly.                                              |
| Security incident                                        | Any incident involving credentials, data exposure, or vulnerability exploitation.      |
| SLO budget exhaustion                                    | A single incident consumed > 25% of the monthly error budget (or the team's threshold). |
| Near-miss                                                | The system was about to break and a human caught it — these teach the most.            |
| Recurring pattern                                        | Third incident this quarter from the same subsystem — even if individually small.      |

If the trigger is *subjective* ("was that bad enough?"), the team will under-write postmortems for the incidents that matter most — the loud ones get one, the quiet expensive ones do not. Make the triggers boolean.

## Blameless framing — the discipline

The cultural rule is: **focus on systems and processes, never on people.**

- "The on-call engineer ran the wrong command" → **bad**. Reframe: "The runbook documented two commands with similar names; the more dangerous one was listed first."
- "Alice forgot to update the config" → **bad**. Reframe: "The config change required manual coordination between three repositories with no enforcement."
- "We should have caught this in review" → **bad**. Reframe: "The review checklist did not cover this class of change; we are adding a check for X."

When a postmortem names a person, ask: would changing that person fix the problem, or would the next person hit the same trap? If the latter, the trap is the problem.

For the deeper framing — psychological safety, second stories, hindsight bias, the swap test — read the Google SRE Workbook Ch. 10 referenced above. doc-master does not reproduce that chapter.

## Postmortem is not an ADR

A postmortem and an ADR are **different documents with different audiences**:

| Dimension      | Postmortem                                                | ADR                                                     |
|----------------|-----------------------------------------------------------|---------------------------------------------------------|
| Subject        | A specific incident that already happened.                | A specific decision the team is making (or made).       |
| Audience       | The team and adjacent teams; sometimes leadership.        | Future maintainers and reviewers of the architecture.   |
| Timing         | After the incident, on a calendar deadline.               | Before or at the moment of decision.                    |
| Updates        | One per incident; never edited, only amended.             | Append-only; superseded, not edited.                    |
| Output         | Action items.                                             | A decision and its rationale.                           |

A postmortem may **produce** an ADR — for example, "Add a circuit breaker between the payment service and the fraud service" might appear as an action item in the postmortem, and then become a separate ADR that records the architectural choice. The two documents cross-link; they do not collapse.

## Common failure modes

| Failure                                                  | Symptom                                                                                | Remedy                                                                                  |
|----------------------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| Single root cause                                        | "The cause was the network."                                                            | Five Whys — incidents almost always have multiple contributing causes. Name each.       |
| Action items with no owner / no date                     | "Improve monitoring." Nobody does it.                                                  | Every action item: owner, due date, tracking ID. Otherwise it is wishful thinking.      |
| Person-blame creeping in                                 | "X engineer should have ..."                                                            | Reframe as a systems gap. If you cannot, the postmortem facilitator pushes back.        |
| Postmortem never published                               | Lessons stay with the immediate responders.                                            | Publish to the team-wide channel. Adjacent teams learn more from your incidents than yours. |
| Action items never tracked                               | The list lives in the postmortem and dies there.                                       | Link each action item to a tracker entry. Review at the next team retro.                |
| "What we'd do differently" without commitment           | Lessons learned but no behavior change.                                                | Each lesson becomes an action item *or* an ADR. Otherwise it is not a lesson.           |

## Routing — when this is not the answer

- "What to do *during* the incident?" → **runbook** (`runbook-canon.md`). The runbook is forward-looking; the postmortem is backward-looking.
- "Why did we pick this architecture in the first place?" → **ADR** (`alternatives-catalog.md`).
- "What's our incident-response process in general?" → **Diátaxis explanation** + a runbook for each alert class. Not a postmortem.
- "What customer-visible changes did we ship?" → **changelog** (`changelog-canon.md`), with a `Security` entry if the incident produced one.
