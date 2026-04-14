---
name: stripe-webhook-idempotency
description: Server-side Stripe webhook idempotency patterns. PROACTIVELY activate for: (1) Stripe webhook handler design, (2) Transactional dedup via stripe_processed_events, (3) credit_transactions.idempotency_key UNIQUE partial indexes, (4) Idempotency-Key header priority (header > body > server UUID), (5) Idempotency key format/charset/length validation at the handler edge, (6) FOR UPDATE row locking when a UPDATE depends on a prior SELECT, (7) Webhook signature verification (stripe.webhooks.constructEventAsync, tolerance, raw-body reading), (8) Retry-safe endpoints with randomUUID fallback, (9) Durable checkpoint row ordering (checkpoint FIRST, mutation SECOND). Provides: complete webhook handler skeleton, Idempotency-Key validator, dedup SQL, FOR UPDATE pattern, signature verification example.
---

## Quick Reference

| Concept | Source of truth | Default |
|--|--|--|
| Signature verification | `stripe.webhooks.constructEventAsync(rawBody, sig, secret, tolerance)` | tolerance = 300s |
| Event dedup (short-term) | `stripe_processed_events` (30d retention) | primary key: `event_id` |
| Balance-change dedup (durable) | `credit_transactions.idempotency_key` UNIQUE partial index | retention = forever |
| Idempotency key priority | `Idempotency-Key` header > body.`idempotency_key` > `crypto.randomUUID()` | validate `len<=128, [A-Za-z0-9_-]` |
| Checkpoint ordering | Checkpoint INSERT -> user UPDATE | never reverse |
| Row lock | `.for("update")` on the snapshot row | required when UPDATE depends on prior SELECT |

## When to Use This Skill

Use for every Stripe webhook handler and every client-retry-safe mutation endpoint (any POST route that creates a billable entity, e.g., `/api/v1/orders`, `/api/v1/jobs`, or your project's equivalent).

**Related skills:**
- For refund/dispute state: `stripe-billing-master:stripe-refund-dispute-lifecycle`
- For the audit-row invariant: `stripe-billing-master:stripe-credit-audit-trail`
- For post-signature invoice-line / refund pagination in the handler body: `stripe-billing-master:stripe-list-pagination-previous-attributes`

## Core Rules

### G1: Durable checkpoint BEFORE state mutation

```ts
await db.transaction(async (tx) => {
  // 1. Durable checkpoint FIRST
  const [inserted] = await tx.insert(creditTransactions).values({ /* ... idempotencyKey: "dispute_hold:<id>" */ })
    .onConflictDoNothing({ target: creditTransactions.idempotencyKey })
    .returning({ id: creditTransactions.id });
  // 2. Dedup
  if (!inserted) return;
  // 3. Mutate
  await tx.update(users).set({ /* ... */ }).where(/* ... */);
});
```

### Idempotency-Key header priority + validation

```ts
const MAX_LEN = 128;
const VALID = /^[A-Za-z0-9_-]+$/;

export function validateIdempotencyKey(key: string | null): { valid: true; key: string | null } | { valid: false; error: string } {
  if (!key || key.trim() === "") return { valid: true, key: null }; // caller falls back to randomUUID
  if (key.length > MAX_LEN) return { valid: false, error: "Idempotency-Key too long" };
  if (!VALID.test(key)) return { valid: false, error: "Idempotency-Key invalid charset" };
  return { valid: true, key };
}

// In the handler:
const headerKey = req.headers.get("Idempotency-Key");
const bodyKey = body.idempotency_key;
const raw = headerKey ?? bodyKey ?? null;
const v = validateIdempotencyKey(raw);
if (!v.valid) return apiError(400, "VALIDATION_ERROR", v.error);
const key = v.key ?? crypto.randomUUID();
```

### Signature verification

Use `constructEventAsync` — synchronous `constructEvent` blocks the worker on large payloads.
```ts
const event = await stripe.webhooks.constructEventAsync(
  rawBody,        // raw bytes; Next.js: await req.text() BEFORE any json()
  sigHeader,
  env.STRIPE_WEBHOOK_SECRET,
  300,            // 5min tolerance
);
```

### Complete webhook handler skeleton

```ts
export async function POST(req: Request) {
  const rawBody = await req.text();
  const signature = req.headers.get("stripe-signature");
  if (!signature) return apiError(400, "VALIDATION_ERROR", "Missing stripe-signature");

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      rawBody,
      signature,
      env.STRIPE_WEBHOOK_SECRET,
      300, // 5min tolerance
    );
  } catch (err) {
    logEvent("stripe_webhook_bad_signature", { err: String(err) });
    return apiError(400, "INVALID_SIGNATURE", "Signature verification failed");
  }

  // Transactional dedup: G1 + G9 pattern
  const dedup = await db.insert(stripeProcessedEvents)
    .values({ eventId: event.id, type: event.type })
    .onConflictDoNothing({ target: stripeProcessedEvents.eventId })
    .returning({ id: stripeProcessedEvents.id });
  if (dedup.length === 0) return apiSuccess({ deduped: true });

  await dispatchEvent(event); // handlers apply G1-G9 per rules above
  return apiSuccess({ ok: true });
}
```

### FOR UPDATE on prior-read snapshot

```ts
const [user] = await tx.select(/* ... */).from(users).where(eq(users.id, userId)).for("update");
// snapshot is safe from concurrent invoice/dispute writes
const prev = user.stripeSubscriptionStatus;
await tx.insert(creditTransactions).values({ /* ... */ metadata: { previousStatus: prev } });
await tx.update(users).set({ stripeSubscriptionStatus: "past_due" });
```
