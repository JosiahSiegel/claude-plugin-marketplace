# ADR failure modes and concrete remedies

The eleven canonical ADR failure modes. Load this reference during folder-level audits (`/doc-audit`) and during `adr-critique` to put a name to what's wrong with a given ADR.

Each row pairs a symptom with the remedy. Most failure modes have an obvious fix; the cardinal rule (`SKILL.md` "Immutability and supersession") still applies — never silently edit an Accepted ADR.

| Failure mode                                                | Symptom                                                                                  | Remedy                                                                                                |
|-------------------------------------------------------------|------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| **Drift** — ADR says X, code does Y.                        | Status is "Accepted" but the system no longer matches.                                   | Either supersede with a new ADR that captures reality, or fix the code. Never silently edit the ADR. |
| **ADR for a non-decision**                                  | The "decision" is a coding convention, a settled industry default, or a reversible UX tweak. | Move to `CONTRIBUTING.md`, code comment, or PR description. Mark the ADR Rejected with a note. |
| **ADR-PRD duplication**                                     | The ADR retells what the product requirements doc already says.                          | The ADR's job is *the decision and its rationale*. Strip duplication; link to the PRD.               |
| **ADRs nobody reads**                                       | Decisions buried in a wiki; never linked from code.                                      | Move ADRs into the repo; link from the relevant module's top-level comment or README.                 |
| **Missing context**                                         | ADR states the decision but not the forces that made it necessary.                       | Add a Context section answering "why now? why us? what constraint?" Without it, future-you cannot judge whether the decision still holds. |
| **Missing re-evaluation triggers**                          | No concrete condition for revisiting.                                                    | Add a "Re-evaluation triggers" section with measurable thresholds.                                    |
| **Hidden alternatives**                                     | "We chose X." (No mention of Y, Z.)                                                      | Add Alternatives considered. If no alternative was considered, say so — that's also information.     |
| **Bundled decisions**                                       | One ADR covers "database, ORM, migration tool, hosting."                                 | Split into separate ADRs. Cross-link them.                                                            |
| **Premature ADR for an in-flight proposal**                 | "Status: Proposed" sits there for six months.                                            | Move to an RFC. ADRs are for *made* decisions.                                                        |
| **Stale numbering / out-of-order acceptance**               | ADRs accepted out of numeric order, gaps in the sequence.                                | That's fine — numbers reflect creation order, not acceptance order. Don't renumber.                   |
| **Template thrash**                                         | Three different templates across the same project.                                       | Pick one and document the pick in `docs/adr/README.md`. Migrate opportunistically; don't bulk-rewrite. |
| **Decision-by-AI without buy-in**                           | An agent generated an ADR; humans never confirmed.                                       | The Owners/Deciders field must name humans. The agent drafts; humans decide.                          |

## How to use this table during an audit

For each ADR in scope:

1. Read header (Status, Owners, Supersedes / Superseded by, Date).
2. Read body (Context, Decision, Alternatives, Consequences, Re-evaluation triggers).
3. Match symptoms against the rows above. One ADR can hit multiple failure modes.
4. Record the failure-mode name alongside the audit verdict (KEEP / MERGE / REWRITE / DELETE / MOVE). Naming the failure mode is faster than re-deriving the problem from scratch.

## How to use this table during line-by-line critique

The `adr-critique` skill walks an ADR line by line. When a line trips a rule (marketing language, hedging, missing-why, future-proofing essay, passive-voice corporate text, implementation bleed), check whether the surrounding section also exhibits one of the failure modes above — they often co-occur. A "missing context" ADR is usually also full of hedging because the author had no constraint to argue from.
