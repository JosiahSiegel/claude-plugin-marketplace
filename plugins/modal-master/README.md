# Modal Master Plugin

Modal Master is a meta-bundle plugin. Installing it auto-installs the focused Modal.com sub-plugins listed below. The router plugin intentionally owns no agents, commands, or domain skills; use the sub-plugins directly when you want narrower trigger surfaces, or install this bundle for the full suite.

## Included sub-plugins

| Sub-plugin | Covers |
|------------|--------|
| `modal-compute` | Apps/functions/classes, GPU selection, autoscaling, batching, parallel processing, image builds, deployment, debugging, cost optimization |
| `modal-storage` | Volumes, Dict, Queue, CloudBucketMount, object storage mounts, shared state, persistence and consistency patterns |
| `modal-web-scheduling` | FastAPI, ASGI/WSGI, webhooks, custom domains, WebSockets, cron schedules, periodic jobs, scheduled ETL |
| `modal-sandboxes` | Isolated code execution, named sandboxes, PTY sessions, snapshots, egress policy, resource limits, sandbox security |

## Installation

```bash
claude plugin add modal-master
```

Claude Code installs and enables the dependency sub-plugins automatically on supported versions.

## Prefer direct installation for focused work

```bash
claude plugin add modal-compute
claude plugin add modal-storage
claude plugin add modal-web-scheduling
claude plugin add modal-sandboxes
```

## License

MIT
