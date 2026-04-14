# stripe-billing-master

Expert Stripe billing system for money-safe webhook handlers, refund/dispute lifecycle, credit audit trails, and idempotency on server-side event processing.

## What this plugin covers

- Stripe webhook handler patterns (signature verification, dedup, replay safety)
- Refund and dispute lifecycle (`charge.refunded`, `charge.dispute.created`, `charge.dispute.closed`)
- Credit / balance ledger invariants (`credit_transactions` audit trail, idempotency-key formats, daily reconciliation cron)
- List-API pagination (`starting_after`, `has_more`) and `event.data.previous_attributes` semantics
- Exhaustiveness patterns for Stripe enums (`satisfies Record<Union, T>`)
- Allowlist default-deny for external strings (dispute statuses, price IDs)

## What this plugin does NOT cover

- Stripe test cards (use official `stripe:test-cards`)
- Stripe error code explanation (use official `stripe:explain-error`)
- API selection best practices — Checkout vs PaymentIntents vs Invoicing (use official `stripe:stripe-best-practices`)
- Checkout / Payment Elements / Stripe.js client-side integration
- Stripe Connect / Treasury

This plugin is complementary to the official `stripe` plugin — it covers the server-side event-processing side of Stripe integration.

## When to invoke

In your caller project's master expert agent, install a HARD delegation rule:

> Any change touching `**/api/webhooks/stripe/**`, `**/lib/stripe*.ts`, `**/lib/refund-credits.ts`, `**/migrations/*credit*.sql`, or credit/balance mutation code MUST first delegate to `stripe-billing-expert` before the main agent writes the first line.

## Installation

Standard marketplace install:

```
/plugin marketplace add josiahsiegel/claude-code-marketplace
/plugin install stripe-billing-master
```

## Agent: stripe-billing-expert

Auto-activates on topics listed in the agent frontmatter. Loads the four skills below on demand.

## Skills

- `stripe-billing-master:stripe-webhook-idempotency` — webhook signature verification, event dedup, Idempotency-Key header priority, checkpoint ordering, FOR UPDATE row locking
- `stripe-billing-master:stripe-refund-dispute-lifecycle` — `charge.refunded`, `charge.dispute.created`, `charge.dispute.closed`, `shouldRestoreStatus`, credit-pack vs subscription refund math
- `stripe-billing-master:stripe-credit-audit-trail` — `credit_transactions` invariants, canonical idempotency-key formats, reconciliation cron design, `creditsDeducted` boolean pattern
- `stripe-billing-master:stripe-list-pagination-previous-attributes` — `starting_after` cursor, `has_more` flag, `previous_attributes` delta semantics, plan resolver with G6 safety fallback

## Rationale

Server-side Stripe billing code concentrates money-loss risk in a small surface: webhook handlers, refund/dispute state machines, and the credit/balance ledger they mutate. The nine rules in `agents/stripe-billing-expert.md` (G1-G9, plus G-bonus for email gating) are the failure modes that repeatedly surface in review when this surface is written without a specialist consult — each maps to one of three shapes of money-loss bug (free credits, silent drift, state-machine races). Loading this agent at design time is the intended workflow.

## License

MIT.
