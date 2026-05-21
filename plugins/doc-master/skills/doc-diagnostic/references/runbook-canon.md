# Runbook canon — operational steps for paged incidents

The canonical reference for runbooks. Load this when the user says "we need a runbook for X," "what do we do when the queue backs up?", or "document our incident response for the database alert."

A **runbook is for an on-call engineer being paged at 03:00 under stress.** It assumes nothing: not that the reader knows the system, not that the reader is awake, not that the reader has time to read prose. Every step is copy-pasteable. Every step has an expected output. The reader's job is to *follow*, not to *learn*.

This is fundamentally different from a Diátaxis **how-to guide**, even though both are task-oriented:

| Dimension     | Runbook                                                  | How-to guide                                             |
|---------------|----------------------------------------------------------|----------------------------------------------------------|
| Reader state  | Paged, under stress, possibly half-asleep.               | Competent user, planned work, system healthy.            |
| Assumptions   | None. Reader may have never seen this system.            | Reader knows the system, has goals, can debug.           |
| Tone          | Imperative, copy-paste, single-path.                     | Imperative, explanatory, with branches.                  |
| Time pressure | Minutes — every step counts.                             | None — reader can pause and read.                        |
| Branching     | Avoided — pick the one safe path, flag exits.            | Allowed — multiple valid approaches.                     |
| Verification  | Mandatory after each step.                               | At the end of the procedure.                             |
| Reuse         | One runbook per alert / paging condition.                | One how-to per goal.                                     |

**One runbook per alert.** If a single alert can mean three different things, you have three runbooks (or one runbook with a clearly labeled triage step that branches to three sub-runbooks).

Upstream source: [PagerDuty Incident Response](https://response.pagerduty.com) — open, copyable operational playbook the rest of the industry has converged on. The PagerDuty material is published under permissive terms; cite it as "PagerDuty Incident Response open templates," not as a product endorsement.

## Required sections

A doc-master runbook has these sections, in this order:

1. **Title** — exactly the alert name / paging condition as it appears in the monitoring system. If the alert is `db-replica-lag-high`, the runbook title is `db-replica-lag-high`. No marketing prose, no rewording. The on-call engineer pastes the alert name into a search box and the right runbook comes up first.

2. **Trigger** — what fires this runbook:
   - The exact alert ID (e.g., `PD-INC-1042`, `prom-rule-name`).
   - The dashboard URL the alert links to.
   - The customer-report channel if one exists.

3. **Preconditions** — what must be true before running the steps:
   - Required access (which IAM role, which secret, which bastion).
   - Required tools installed locally.
   - Anything that would silently fail otherwise.

4. **Steps** — numbered, each step is a single action:
   - **Copy-pasteable** — every command runs as written.
   - **Expected output** — what success looks like, character-by-character if possible.
   - **What to do if the expected output is absent** — point to the next step or to the Escalation section.
   - One step per cognitive unit. Do not bundle.

5. **Verification** — how to confirm the incident is resolved:
   - The dashboard signal that should return to green.
   - The customer-facing check.
   - The wait time, if there is one ("metrics propagate in 60–90 seconds").

6. **Rollback** — what to do if the steps make it worse:
   - The exact revert command for each forward step.
   - Whom to call if rollback fails.

7. **Escalation** — who to wake up, and when:
   - Named alias (not a person — bus factor).
   - The threshold ("after 15 minutes with no improvement").
   - The next-tier alias.

8. **Known false positives** — patterns the on-call should recognize as "not a real incident":
   - Specific symptoms that look like the alert but are not.
   - Why they look similar.
   - How to confirm it's a false positive (the test, not the heuristic).

9. **Last verified** — ISO 8601 date the runbook was last exercised end-to-end. If it has not been exercised in six months, treat it as stale.

## Common failure modes

| Failure                                                | Symptom                                                                                  | Remedy                                                                                |
|--------------------------------------------------------|------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Runbook is actually a how-to                            | Branches, prose explanations, "first read this design doc."                              | Strip explanation. Move to `docs/how-to/`. Write a fresh runbook with copy-paste steps.|
| One runbook for "the database is sad"                  | Single document covering five different alerts.                                          | Split into one runbook per alert. Cross-link if they share a triage step.             |
| Steps lack expected output                              | Reader runs the command, gets unexpected output, freezes.                                | Every step has a "you should see ..." block. Failure mode is a separate step.         |
| Escalation contact is a single person                   | That person is on PTO; bus factor of one.                                                | Escalate to a shared alias (rotation, team channel), never a single human.            |
| Never exercised                                         | "Last verified" is missing or > 12 months old.                                           | Quarterly tabletop or game-day exercise. Update or retire the runbook after each.     |
| Drift                                                   | Runbook says `service-foo restart`; service was renamed to `service-bar`.                | Audit alongside the service it documents. Stale runbook is worse than no runbook.     |
| Hidden in a wiki                                        | On-call cannot find it from the alert.                                                   | Link the alert directly to the runbook. Store runbooks in the repo or a flat shared folder. |

## Canonical skeleton

````md
# db-replica-lag-high

## Trigger
- Alert ID: `prom-db-replica-lag-high`
- Dashboard: <link>
- Customer channel: `#cust-incidents` (search for `replica lag`)

## Preconditions
- AWS access to the `db-prod` account.
- `psql` and `awscli` on your path.
- Bastion access -- VPN profile `prod-bastion`.

## Steps

1. Confirm the alert is current -- open the dashboard above. Replica lag > 30s for > 5 minutes?
   - Expected: red line above 30s on the `replica-lag-seconds` panel.
   - If green, this is a stale alert. Acknowledge and stop.

2. Identify the replica:
   ```sh
   aws rds describe-db-instances --db-instance-identifier db-replica-prod
   ```
   - Expected: status `available`.
   - If `failed` or `incompatible-parameters`, skip to Escalation.

3. ... (one step per cognitive unit, copy-paste, expected output)

## Verification
- Dashboard `replica-lag-seconds` returns under 5s and stays for 10 minutes.
- Customer report channel quiet for 15 minutes.

## Rollback
- (Per forward step, the exact revert command and the verification it returns to green.)

## Escalation
- After 15 minutes with no improvement: page `db-oncall-tier2` via PagerDuty.
- After 30 minutes: page `eng-leadership-oncall`.

## Known false positives
- A scheduled `pg_dump` at 02:00 UTC causes ~45s of replica lag for ~3 minutes. If the alert fires at exactly that window and clears within five minutes, acknowledge as expected.

## Last verified
- 2026-04-12 (tabletop exercise)
````

## Routing -- when this is not the answer

- "How do I deploy to staging?" → Diátaxis **how-to guide**, not a runbook. The user is not being paged.
- "Why does the system handle backpressure this way?" → Diátaxis **explanation**.
- "What was the call we made on circuit-breaker thresholds?" → **ADR** — the *decision*. The runbook executes; the ADR records *why* the threshold is what it is.
- "What happened during the 2026-05-12 outage?" → **postmortem**, not a runbook. See `postmortem-canon.md`.
- "What are all our alert IDs and severities?" → Diátaxis **reference** (an alert catalog), with each entry linking to its runbook.
