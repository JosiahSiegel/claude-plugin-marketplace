---
name: stripe-credit-audit-trail
description: credit_transactions audit trail invariants and daily reconciliation patterns. PROACTIVELY activate for: (1) Designing a credit / balance / entitlement ledger, (2) credit_transactions row shape (delta, balanceAfter, reason, referenceType, referenceId, idempotencyKey), (3) Canonical idempotency key formats (refund:/debit:/stripe_checkout:/stripe_invoice:/stripe_refund:/stripe_signup_bonus:/dispute_hold:/dispute_restore:), (4) Daily reconciliation cron design (snapshot comparison, not full-sum), (5) Alert-only policy (never auto-correct drift), (6) Canonical refund helper pattern (single source of truth across pg-raw and Drizzle call sites), (7) Past_due block + credit balance shared preflight, (8) creditsDeducted boolean return pattern for pre- vs post-deduction error differentiation, (9) Money-safe email description based on resolvedVia flag, (10) Skip-users-without-baseline-snapshot reconciliation logic. Provides: table schema, canonical helper skeleton, reconciliation SQL, email gating pattern.
---

## Quick Reference

| Field | Purpose |
|--|--|
| `userId` | Who the transaction belongs to |
| `delta` (signed int) | +granted / -revoked |
| `balanceAfter` (int snapshot) | Reconciliation baseline |
| `reason` (enum) | Categorical — one of a fixed set |
| `referenceType` + `referenceId` | Pointer to the originating entity |
| `idempotencyKey` (UNIQUE partial index) | Dedup + G1 checkpoint |
| `metadata` (jsonb) | Free-form context (previousStatus, resolvedVia, etc.) |

Pick one domain prefix that matches your billable entity (`order`, `job`, `item`, etc.) and use it consistently. The table below uses `order` as the neutral example:

| Idempotency key format | When |
|--|--|
| `debit:{orderId}` | order creation debit |
| `refund:{orderId}` | order refund |
| `debit:batch:{batchId}` | batch debit |
| `refund_unused:batch:{batchId}` | batch partial refund |
| `stripe_checkout:{sessionId}` | credit pack grant |
| `stripe_invoice:{invoiceId}` | subscription renewal |
| `stripe_refund:{eventId}` | Stripe refund event |
| `stripe_signup_bonus:{userId}` | signup bonus |
| `dispute_hold:{disputeId}` | dispute-initiated past_due hold |
| `dispute_restore:{disputeId}` | dispute closure status restore |

## When to Use This Skill

Use whenever any path mutates a balance / credit / entitlement column; whenever a reconciliation or audit cron is being designed; whenever a refund helper is being extended.

**Related skills:**
- For dispute-hold lifecycle and `shouldRestoreStatus`: `stripe-billing-master:stripe-refund-dispute-lifecycle`
- For the G1 checkpoint that precedes every balance mutation: `stripe-billing-master:stripe-webhook-idempotency`
- For the `resolvedVia` flag that gates money-safe email rendering: `stripe-billing-master:stripe-list-pagination-previous-attributes`

## Canonical refund helper pattern

> In the example below, `orders.amount_used` is a per-order ledger of credits spent on that order. Zeroing it on refund returns the spent amount (via `RETURNING`), which is then re-credited to `users.credit_balance` in the same transaction. Rename `orders` / `amount_used` to match your billable-entity schema.

One helper. Two call patterns (pg-raw for Cloudflare Workers / Node workers, Drizzle for Next.js route handlers). Byte-identical SQL kept as exported constants. In the example below, `orders` stands in for whatever your billable-entity table is named; rename consistently across the helper, the key format, and all call sites.

```ts
// example path: packages/shared/src/refund-credits.ts
export const REFUND_ORDER_SQL = {
  zeroOrder: `UPDATE orders SET amount_used = 0 WHERE id = $1 AND amount_used > 0 RETURNING amount_used`,
  creditUser: `UPDATE users SET credit_balance = credit_balance + $1 WHERE id = $2 RETURNING credit_balance`,
  insertTransaction: `INSERT INTO credit_transactions (user_id, delta, balance_after, reason, reference_type, reference_id, idempotency_key)
    VALUES ($1, $2, $3, 'order_refunded', 'order', $4, $5)
    ON CONFLICT (idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
};

type RefundArgs = { userId: string; orderId: string };
type RefundResult = { refunded: number; alreadyRefunded: boolean };

// pg-raw variant (Workers, Node workers, any pg.Client / pg.Pool compatible driver).
export async function refundOrderCreditsPg(
  pg: { query: (sql: string, params: unknown[]) => Promise<{ rows: any[] }> },
  { userId, orderId }: RefundArgs,
): Promise<RefundResult> {
  await pg.query("BEGIN", []);
  try {
    const zeroed = await pg.query(REFUND_ORDER_SQL.zeroOrder, [orderId]);
    const returnedAmount: number = zeroed.rows[0]?.amount_used ?? 0;
    if (returnedAmount <= 0) {
      await pg.query("COMMIT", []);
      return { refunded: 0, alreadyRefunded: true };
    }

    const credited = await pg.query(REFUND_ORDER_SQL.creditUser, [returnedAmount, userId]);
    const creditedBalance: number = credited.rows[0].credit_balance;

    await pg.query(REFUND_ORDER_SQL.insertTransaction, [
      userId,
      returnedAmount,        // delta (+returnedAmount)
      creditedBalance,       // balance_after snapshot
      orderId,               // reference_id
      `refund:${orderId}`,   // idempotency_key
    ]);

    await pg.query("COMMIT", []);
    return { refunded: returnedAmount, alreadyRefunded: false };
  } catch (err) {
    await pg.query("ROLLBACK", []);
    throw err;
  }
}

// Drizzle variant (Next.js route handlers / any Drizzle tx). Caller passes tx + sql tag.
export async function refundOrderCreditsDrizzle(
  tx: { execute: (q: unknown) => Promise<{ rows: any[] }> },
  sql: { raw: (s: string, ...p: unknown[]) => unknown },
  { userId, orderId }: RefundArgs,
): Promise<RefundResult> {
  const zeroed = await tx.execute(sql.raw(REFUND_ORDER_SQL.zeroOrder, orderId));
  const returnedAmount: number = zeroed.rows[0]?.amount_used ?? 0;
  if (returnedAmount <= 0) {
    return { refunded: 0, alreadyRefunded: true };
  }

  const credited = await tx.execute(sql.raw(REFUND_ORDER_SQL.creditUser, returnedAmount, userId));
  const creditedBalance: number = credited.rows[0].credit_balance;

  await tx.execute(
    sql.raw(
      REFUND_ORDER_SQL.insertTransaction,
      userId,
      returnedAmount,        // delta (+returnedAmount)
      creditedBalance,       // balance_after snapshot
      orderId,               // reference_id
      `refund:${orderId}`,   // idempotency_key
    ),
  );

  return { refunded: returnedAmount, alreadyRefunded: false };
}
```

Call sites: every service, queue consumer, and worker entry point that refunds on behalf of a user MUST delegate to this helper. Never add a new refund call site with inline SQL — that's how audit rows go missing on one branch and the reconciliation cron stops being authoritative.

## Reconciliation cron

```sql
-- Snapshot comparison, no full sum
WITH latest AS (
  SELECT DISTINCT ON (user_id) user_id, balance_after, created_at
  FROM credit_transactions
  ORDER BY user_id, created_at DESC
)
SELECT u.id, u.credit_balance AS actual, l.balance_after AS expected, u.credit_balance - l.balance_after AS drift
FROM users u
JOIN latest l ON l.user_id = u.id
WHERE u.credit_balance <> l.balance_after;
```

Alert-only policy — never auto-correct. Users with zero `credit_transactions` rows since the table landed have no baseline; skip them.

## `creditsDeducted` boolean pattern

Split credit-deduction and queue-submission into separate try/catch blocks. Return shape always carries `creditsDeducted: boolean` so callers can distinguish:
- DB error BEFORE deduction -> `creditsDeducted=false`, caller SKIPS refund
- DB error AFTER deduction -> `creditsDeducted=true`, caller refunds via canonical helper
- Queue submission failure -> `creditsDeducted=true`, caller refunds

Never gate refunds on the order row's `amount_used` column — it was set BEFORE the UPDATE succeeded, so reading it post-error can mint free credits for deductions that never actually committed. Rely on the explicit `creditsDeducted` flag returned from the deduction function instead.
