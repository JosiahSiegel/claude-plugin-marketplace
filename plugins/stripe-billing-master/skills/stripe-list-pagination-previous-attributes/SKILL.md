---
name: stripe-list-pagination-previous-attributes
description: Stripe list-API pagination and event.data.previous_attributes semantics. PROACTIVELY activate for: (1) invoice.lines.data / charge.refunds.data / subscription.items.data embedded pagination, (2) starting_after cursor when falling through to list APIs, (3) has_more flag checking, (4) event.data.previous_attributes field semantics (which fields changed between old and new state), (5) Cumulative vs per-event Stripe fields (charge.amount_refunded is cumulative), (6) Delta computation patterns, (7) Plan resolution from invoice line items with pagination, (8) Safety fallback on pagination exhaustion (G6 — {plan:'free',credits:0}), (9) API error handling mid-scan. Provides: full pagination scan pattern, previous_attributes delta helper, plan resolver with paginated line-item scan.
---

## Quick Reference

| Field | Semantic |
|--|--|
| `event.data.previous_attributes` | ONLY the fields that changed; diff the current object against this |
| `event.data.previous_attributes.amount_refunded` | Previous cumulative refund total — subtract from `charge.amount_refunded` for per-event delta |
| `charge.amount_refunded` | CUMULATIVE across all refunds, NEVER per-event |
| `invoice.lines.has_more` | true -> embedded `data` is page 1; paginate with `starting_after` |
| `invoice.lines.data.at(-1).id` | The cursor for `starting_after` on the next page |
| `stripe.invoices.listLineItems(invoice.id, { starting_after })` | Resumes AFTER the cursor — does NOT re-scan page 1 |

## When to Use This Skill

Use whenever:
- You read an embedded `.data[]` array from a Stripe object and might need to paginate
- You compute a "what changed" delta from a webhook event
- You resolve a plan / SKU / entitlement from invoice line items or subscription items

**Related skills:**
- Where `getRefundDelta` is consumed in the refund handler: `stripe-billing-master:stripe-refund-dispute-lifecycle`
- Where `resolvedVia` gates email rendering and audit logging: `stripe-billing-master:stripe-credit-audit-trail`

## Pagination scan pattern

```ts
async function scanAllLineItems(invoice: Stripe.Invoice): Promise<Stripe.InvoiceLineItem[]> {
  const items: Stripe.InvoiceLineItem[] = [...invoice.lines.data];
  let cursor = invoice.lines.data.at(-1)?.id;
  let hasMore = invoice.lines.has_more;

  while (hasMore && cursor) {
    const page = await stripe.invoices.listLineItems(invoice.id, {
      limit: 100,
      starting_after: cursor,
    });
    items.push(...page.data);
    hasMore = page.has_more;
    cursor = page.data.at(-1)?.id;
  }
  return items;
}
```

Without `starting_after`, `stripe.invoices.listLineItems(invoice.id)` re-fetches page 1 — the same page you already have embedded in `invoice.lines.data`. The scan loops over identical content until `has_more` never flips, concluding "no match" on lines that never got scanned. Always thread the cursor.

> Edge case: if `invoice.lines.data` is empty but `invoice.lines.has_more` is `true` (rare, but Stripe can return this shape when the embedded `limit` is 0), the loop above never executes because `cursor` is `undefined`. In that case, fall through to `stripe.invoices.listLineItems(invoice.id, { limit: 100 })` with no `starting_after` to start a fresh scan.

## `previous_attributes` delta helper

```ts
type AmountRefundedChanged = { amount_refunded?: number };

export function getRefundDelta(event: Stripe.Event, charge: Stripe.Charge): number | null {
  const prev = (event.data.previous_attributes as AmountRefundedChanged | undefined)?.amount_refunded;
  if (typeof prev === "number") return charge.amount_refunded - prev;
  return null; // caller falls back to embedded / list / skip-revocation
}
```

## Plan resolver with pagination + G6 safety fallback

```ts
export async function resolvePlanFromInvoice(invoice: Stripe.Invoice): Promise<{
  plan: Plan;
  credits: number;
  resolvedVia: "priceMap" | "safetyFallback";
}> {
  try {
    const items = await scanAllLineItems(invoice); // G3 — paginate first
    for (const item of items) {
      const mapped = PRICE_TO_PLAN[item.price?.id ?? ""];
      if (mapped) return { ...mapped, resolvedVia: "priceMap" };
    }
    logEvent("credit_price_resolve_unknown", { invoiceId: invoice.id, lineCount: items.length });
    return { plan: "free", credits: 0, resolvedVia: "safetyFallback" }; // G6
  } catch (err) {
    logEvent("credit_price_resolve_error", { invoiceId: invoice.id, err: String(err) });
    return { plan: "free", credits: 0, resolvedVia: "safetyFallback" }; // G6
  }
}
```

The email renderer uses `resolvedVia` to gate plan names on `priceMap` — never renders "Welcome to Free" on the safety-fallback path (G-bonus).
