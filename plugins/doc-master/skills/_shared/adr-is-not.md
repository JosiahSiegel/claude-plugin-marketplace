# An ADR IS NOT — shared checklist

This file is the canonical "what an ADR must not be," referenced by every ADR-related skill in `doc-master` (`adr-discovery`, `adr-drafting`, `adr-backfill`, `adr-critique`, and the `doc-expert` agent). Enforce these rules during drafting, self-critique, and audit.

Hard sentence/length limits sit at the bottom and are enforced by `adr-critique`.

---

## 1. Not a tutorial

ADRs do not teach. Do not explain what REST, message queues, Kafka, OAuth, eventual consistency, or any other technology is. Assume the reader knows the domain. If the reader does not, write a Diátaxis tutorial or explanation in `docs/explanation/` and link to it.

| Wrong (tutorial voice) | Right (decision voice) |
|---|---|
| "Kafka is a distributed event streaming platform that allows…" | "We use Kafka for the user-event topic." |
| "REST APIs use HTTP verbs to expose resources…" | "The public API is REST over HTTPS." |

## 2. Not an implementation guide

No code snippets except **fitness functions** (automated checks that the decision still holds). Migration steps, deployment recipes, and example payloads belong in `docs/how-to/` or a runbook.

| Allowed | Not allowed |
|---|---|
| `archunit.classes().that().resideInAPackage("..web..").should().notDependOnClassesThat().resideInAPackage("..db..")` — a fitness function | A full migration script |
| A one-line compliance check | A code walkthrough |

## 3. Not a marketing doc

Banned words: **leverage, robust, scalable, enterprise-grade, seamless, cutting-edge, world-class, best-in-class, future-proof, synergy, paradigm, holistic, turnkey**. These signal that the author is selling, not deciding.

| Wrong | Right |
|---|---|
| "Leverage Kafka's robust, scalable, enterprise-grade event streaming." | "Kafka handles 50k events/sec at p99 < 20ms on our hardware. We need 30k/sec." |
| "A seamless, future-proof architecture." | "Today's load is 30k/sec. Re-evaluate at 100k/sec." |

## 4. Not a hedge

Forbidden phrases: "*might want to consider*", "*could potentially*", "*may be worth evaluating*", "*it might be good to*", "*we should probably*". A decision is a commitment, not an option.

| Wrong | Right |
|---|---|
| "We might want to consider potentially evaluating Kafka." | "We use Kafka." |
| "It could be a good idea to think about caching." | "We cache user sessions in Redis for 24h." |

## 5. Not a generic best-practice citation

"Industry standard" is not a reason. "Best practice for microservices" is not a reason. Cite a **specific business concern** that maps to a **specific architectural characteristic**. If the only justification is "everyone does this," delete the line.

| Wrong | Right |
|---|---|
| "This is the industry standard." | "Our compliance team requires data residency in EU; this DB supports per-region replicas." |
| "Best practice for microservices." | "Service A's deploy cadence (daily) and service B's (quarterly) are incompatible in a monolith." |

## 6. Not an LLM probability summary

Citing "how most teams do it" or "what the model has seen" is an abdication, not a justification. If the model is the source of authority, the decision has no owner. Owners decide; the agent drafts.

| Wrong | Right |
|---|---|
| "Most teams use Postgres for this." | "We use Postgres because the join workload requires multi-table queries at p95 < 200ms." |
| "Standard practice in 2026 is to…" | "Our SRE on-call team has 5 years of Postgres experience and zero with the alternatives." |

## 7. Not a future-proofing essay

Decisions are made for **known forces today**. "What if we scale 1000x?" is a re-evaluation trigger, not a decision driver. List unknown scenarios in the **Re-evaluation triggers** section instead of architecting for them.

| Wrong | Right |
|---|---|
| "This will scale to a billion users." | "Re-evaluate when daily active users exceed 5M." |
| "Architected for tomorrow's needs." | "Architected for today's 100k DAU; will revisit at 1M." |

## 8. Not corporate passive voice

| Wrong | Right |
|---|---|
| "It was decided that Postgres would be used." | "We use Postgres." |
| "A migration is to be performed." | "We migrate the user table on 2026-06-15." |

Active voice. Named subject. Present tense for current decisions.

## 9. Not a design doc

Implementation details (class diagrams, sequence diagrams, API payload schemas, deployment manifests) belong in a design doc, an explanation, or a reference. The ADR holds **the decision and its rationale**, nothing else.

If a reader can implement the system from your ADR alone, you wrote too much. If they can understand *why* the system is shaped this way, you wrote enough.

## 10. Not long

Hard limits enforced by `adr-critique`:

- **Context: ≤ 3 sentences.** If you need more, the decision is bundled — split it.
- **Decision: ≤ 3 sentences.** Active voice. Present tense.
- **Consequences: bullets.** Good and Bad. Prose paragraphs in this section are a smell.

If an ADR is longer than ~300 words excluding metadata, something is being padded.

---

## Quick self-check before save

Run these in order. Stop at the first failure.

1. Did I explain what any tech *is*? → tutorial, move it
2. Did I include code beyond a fitness function? → implementation guide, move it
3. Are any banned marketing words present? → strip them
4. Does any sentence hedge (might / could / may)? → commit or remove
5. Does any line justify with "industry standard" / "best practice"? → name the specific business force
6. Did I cite "most teams" or "the model"? → name the human and the local force
7. Did I architect for unknown future load? → move to Re-evaluation triggers
8. Is any sentence passive-voice corporate? → rewrite active
9. Does the ADR contain implementation detail? → move to a how-to / design doc
10. Context > 3 sentences? Decision > 3 sentences? Consequences as prose? → cut

If all ten pass, save.
