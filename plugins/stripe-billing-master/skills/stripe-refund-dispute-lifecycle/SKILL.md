---
name: stripe-refund-dispute-lifecycle
description: Complete Stripe refund and dispute lifecycle handling. PROACTIVELY activate for: (1) charge.refunded handler design, (2) charge.dispute.created / charge.dispute.closed handlers, (3) Refund delta computation from event.data.previous_attributes.amount_refunded, (4) Dispute-hold past_due status management, (5) shouldRestoreStatus predicate with satisfies Record<Stripe.Dispute.Status, boolean>, (6) Credit-pack vs subscription refund differentiation, (7) Checkout Session lookup for refund proportion math, (8) Allowlist default-deny for external enums, (9) stripe.checkout.sessions.list({payment_intent}) pattern, (10) Dispute outcome branch logic (won / lost / warning_closed / prevented). Provides: full handler patterns for all three events, predicate examples, credit-pack vs subscription math, exhaustive switch patterns.
---

## Quick Reference

| Event | Action | Key rule |
|--|--|--|
| `charge.refunded` | Revoke credits proportional to refund delta | G2 — `previous_attributes.amount_refunded` |
| `charge.dispute.created` | Set user `past_due` + store checkpoint | G1 + G9 |
| `charge.dispute.closed` | `won` / `warning_closed` / `prevented` -> restore; `lost` -> no-op (charge.refunded handles); else -> no-op | G5 + G7 |

| Refund source priority | When to use |
|--|--|
| `event.data.previous_attributes.amount_refunded` (G2) | Primary — always prefer |
| `charge.refunds.data` (sorted by created desc) | Fallback when `previous_attributes` absent |
| `stripe.refunds.list({charge, limit:1})` | Last resort when embedded missing |
| `charge.amount_refunded` alone | NEVER (cumulative, not per-event) |

## When to Use This Skill

Use when implementing any handler that revokes credits or mutates a paid-status column in response to Stripe refund or dispute events.

**Related skills:**
- For `getRefundDelta` (the G2 delta helper): `stripe-billing-master:stripe-list-pagination-previous-attributes`
- For the canonical refund helper and audit-row invariant: `stripe-billing-master:stripe-credit-audit-trail`
- For the G1 checkpoint pattern every dispute handler wraps: `stripe-billing-master:stripe-webhook-idempotency`

## Core Rules

### G2: refund delta

Use `getRefundDelta()` from `stripe-billing-master:stripe-list-pagination-previous-attributes` — that skill owns the delta-computation helper. Key guarantee: the helper returns `null` when no source is available, and the handler MUST skip revocation rather than guess.

### G7: exhaustive `shouldRestoreStatus`

```ts
const shouldRestoreMap = {
  won: true,
  warning_closed: true,
  prevented: true,
  lost: false,
  needs_response: false,
  under_review: false,
  warning_needs_response: false,
  warning_under_review: false,
  charge_refunded: false,
} satisfies Record<Stripe.Dispute.Status, boolean>;

export const shouldRestoreStatus = (s: Stripe.Dispute.Status): boolean => shouldRestoreMap[s];
```

When Stripe adds a new status in a future SDK version, this object is a compile error until you add the key — forcing a conscious G5 allowlist decision.

### Credit-pack vs subscription refund

```ts
async function resolveCreditsToRevoke(charge: Stripe.Charge, refundAmount: number) {
  const sessions = await stripe.checkout.sessions.list({
    payment_intent: charge.payment_intent as string,
    limit: 1,
    expand: ["data.line_items"],
  });
  const session = sessions.data[0];
  if (session?.mode !== "subscription") {
    const pack = CREDIT_PACKS.find(p => session?.line_items?.data?.[0]?.price?.id === p.priceId);
    if (pack && session.amount_total && session.amount_total > 0) {
      // Proportional revocation: if they refunded 50% of the pack, revoke 50% of the credits
      return Math.round(pack.credits * (refundAmount / session.amount_total));
    }
  }
  // Subscription: 1 credit = 1 cent at cash-equivalent
  return refundAmount;
}
```

Notes on the credit-pack math: proportional revocation matters because packs are bulk-priced (e.g., 1000 credits for $9 instead of $10) — a flat `refundAmount -> credits` conversion over-revokes. Always look up the originating Checkout Session to distinguish `mode: "subscription"` (cash-equivalent) from `mode: "payment"` with a known pack price ID (proportional).
