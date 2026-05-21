# CODE_OF_CONDUCT canon — Contributor Covenant

doc-master's default Code of Conduct is the **Contributor Covenant**. The canonical home is [contributor-covenant.org](https://www.contributor-covenant.org/).

## Version recommendation

- **Default: Contributor Covenant 3.0** ([contributor-covenant.org/version/3/0/code_of_conduct/](https://www.contributor-covenant.org/version/3/0/code_of_conduct/)).
- **Older still-valid fallback: Contributor Covenant 2.1** ([contributor-covenant.org/version/2/1/code_of_conduct/](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)).

The Covenant is the most widely adopted open-source Code of Conduct, and the version published at the canonical URL is the one to reference. doc-master defaults to 3.0; 2.1 remains acceptable when the project has not yet adopted 3.0 or has commitments tied to the 2.1 text.

## What changed in 3.0 (worth knowing)

Two structural changes matter when adopting or upgrading:

1. **Four-rung Enforcement Ladder.** 3.0 names four explicit consequence levels, in escalating severity:
   - **Warning** — a private clarification of the boundary.
   - **Time-limited cooldown** — a temporary, bounded suspension from interaction.
   - **Temporary Suspension** — a longer, project-wide suspension.
   - **Permanent Ban** — removal from the project community.
   The ladder gives moderators a calibrated set of responses rather than the binary "ban or do nothing."
2. **Explicit Encouraged vs Restricted behaviors.** 3.0 separates the **encouraged** behaviors (empathy, kindness, accepting constructive feedback) from the **restricted** behaviors (harassment, doxxing, sustained disruption) into distinct sections. This is clearer than the 2.x mixed list and makes the document scannable.

The pledge, the scope, the attribution, and the enforcement-process scaffolding are otherwise consistent with 2.x.

## Adoption checklist

When adding `CODE_OF_CONDUCT.md` to a repo:

1. **Use the verbatim text** of the chosen version. Do not paraphrase. Do not edit out clauses you find awkward. The whole point of adopting a community-shared Code is that it is the same text across projects.
2. **Place the file at the repo root** (`CODE_OF_CONDUCT.md`). GitHub also accepts `.github/CODE_OF_CONDUCT.md`.
3. **Fill in the contact line.** The Covenant template has a placeholder for "report concerns to ..." — this is the only line you customize. It is a **shared alias**, not a single maintainer's personal inbox. See "Hard rules" below.
4. **Link from `README.md`** and **link from `CONTRIBUTING.md`**.
5. **Document the moderation process** internally — who reads the alias, how reports are triaged, what the response SLA is, who decides on enforcement actions. The Covenant defines the *ladder*; the project defines the *who* and *how*.
6. **Date and version.** A line in your README or in the Code of Conduct itself naming the version (e.g., "This project adopts Contributor Covenant 3.0, adopted 2026-05-21.") makes upgrades auditable.

## Hard rules

- **Contact line is a shared alias, never a single maintainer's personal email.**
  - Good: `conduct@example.org`, `community@…`, a private moderation channel, a coordinated GitHub team.
  - Bad: `alice@personal.example` (bus factor of one; a malicious actor can target one human).
  - doc-master refuses to write a contact line resolving to a single individual. This is non-negotiable — community-health depends on the reporting channel surviving any one departure or compromise.
- **Do not edit the substantive text.** Customize only the contact line.
- **Do not promise enforcement timelines the project cannot meet.** "We respond within 24 hours" sets an expectation. Either commit and budget for it, or omit.

## Canonical skeleton

```md
# Contributor Covenant Code of Conduct

(Use the verbatim text from https://www.contributor-covenant.org/version/3/0/code_of_conduct/.)

...

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the community leaders responsible for enforcement at **conduct@example.org**.

All complaints will be reviewed and investigated promptly and fairly.

## Enforcement Ladder

(Verbatim from the 3.0 source: Warning → Time-limited cooldown → Temporary Suspension → Permanent Ban.)

## Attribution

This Code of Conduct is adapted from the Contributor Covenant, version 3.0, available at https://www.contributor-covenant.org/version/3/0/code_of_conduct/.
```

## Common failure modes

| Failure                                          | Symptom                                                                              | Remedy                                                                          |
|--------------------------------------------------|--------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| Single-maintainer contact email                  | Reports go to one inbox; that person is on PTO / compromised / no longer with the project. | Shared alias, always. Document who reads it internally.                         |
| No moderation process behind the alias           | Mail goes to the alias and sits.                                                     | Internal SOP: who reads, SLA, escalation. Out of scope for the public doc.      |
| Paraphrased / edited Covenant text                | Adopted "Covenant" doesn't match the canonical text; legal weight diminished.        | Use verbatim. Customize only the contact line.                                  |
| No link from README / CONTRIBUTING                | Newcomers don't know it exists.                                                      | One line in each, linking to `CODE_OF_CONDUCT.md`.                              |
| Version not stated                                | Cannot tell which version you adopted; cannot tell when to upgrade.                  | Name the version on the file and in the adoption commit.                        |
| Project commits to a SLA it cannot meet           | Reporters feel ignored; project's credibility erodes.                                | Omit the SLA or pick one the team can actually staff.                           |

## Routing — when this is not the answer

- Behavioral norms specific to *contribution mechanics* (not community behavior) → `CONTRIBUTING.md`.
- Security disclosure policy → `SECURITY.md`. (These are different — Code of Conduct covers conduct; SECURITY covers vulnerability reporting.)
- Internal moderation playbook → not in the public repo. Keep that in an ops-private location.
- Trademark / branding enforcement → `TRADEMARKS.md` if the project has one.
