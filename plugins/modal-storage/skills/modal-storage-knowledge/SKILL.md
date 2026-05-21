---
name: modal-storage-knowledge
description: |
  This skill should be used when the user asks to work with Modal.com persistence or shared state. PROACTIVELY activate for: Modal Volumes, vol.commit, Dict, Queue, CloudBucketMount, S3 or GCS mounts, secret-backed storage credentials, model cache persistence, dataset staging, shared queues, distributed state, volume consistency, and storage troubleshooting.
  Provides: storage primitive selection matrix, commit/consistency patterns, mount configuration recipes, and troubleshooting checklists.
---

# Modal Storage Knowledge

Use this skill for Modal persistence and shared-state primitives. For compute, GPU, autoscaling, or deployment topics, use `modal-compute:modal-compute-knowledge`.

## Quick routing

- **Volumes**: durable filesystem state mounted into functions/classes; call `vol.commit()` after writes that must persist.
- **Dict**: distributed key-value state for small shared metadata, caches, and coordination.
- **Queue**: producer/consumer task handoff and distributed job queues.
- **CloudBucketMount**: direct access to S3/GCS-compatible object storage through Modal mounts.
- **Secrets**: use named secrets for storage credentials; never hardcode keys.

## Essential workflow

1. Identify whether the workload needs filesystem semantics, key-value state, queueing, or object-store access.
2. Mount the storage primitive explicitly on every function/class that needs it.
3. For Volumes, commit after writes and reload/read carefully across concurrent workers.
4. Keep credentials in Modal Secrets and scope them to the functions that require access.
5. Validate with a small read/write/delete test before scaling parallel jobs.

## Detailed reference

See `references/storage-volumes-cloud.md` for examples, gotchas, and deeper storage guidance.
