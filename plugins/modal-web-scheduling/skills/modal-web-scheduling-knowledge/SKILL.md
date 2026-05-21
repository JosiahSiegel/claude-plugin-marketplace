---
name: modal-web-scheduling-knowledge
description: |
  This skill should be used when the user asks to expose Modal.com functions as APIs or schedule Modal jobs. PROACTIVELY activate for: FastAPI endpoints, @modal.fastapi_endpoint, @modal.asgi_app, @modal.wsgi_app, webhooks, WebSockets, custom domains, endpoint timeouts, modal.Cron, modal.Period, scheduled ETL, cron timezones, deploy-vs-run schedule behavior, and endpoint debugging.
  Provides: endpoint decorator selection guide, scheduling patterns, timezone/cron rules, and debugging recipes for endpoints and schedules.
---

# Modal Web and Scheduling Knowledge

Use this skill for Modal web endpoints and scheduled jobs. For GPU compute, autoscaling, or storage primitives, use the focused Modal compute or storage skills.

## Endpoint routing

- Use `@modal.fastapi_endpoint()` for simple function-backed HTTP APIs.
- Use `@modal.asgi_app()` for full FastAPI/Starlette apps, WebSockets, middleware, and routing.
- Use `@modal.wsgi_app()` for WSGI frameworks.
- Add `@modal.concurrent` for high-throughput endpoints that can safely handle concurrent inputs per container.
- Test locally with `modal serve`, then deploy with `modal deploy`.

## Scheduling routing

- Use `modal.Cron(...)` for calendar schedules and explicit timezones.
- Use `modal.Period(...)` for interval-based execution.
- Schedules run from deployed apps; `modal run` is only for manual testing.
- Add retries, timeouts, and idempotency for scheduled ETL or recurring jobs.

## Debug checklist

1. Confirm the app is deployed when testing schedules.
2. Check endpoint logs with bounded log streaming.
3. Validate secrets and environment names before deployment.
4. Exercise a minimal request or manual schedule trigger before scaling traffic.
