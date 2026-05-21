---
name: modal-sandboxes-knowledge
description: |
  This skill should be used when the user asks to run isolated or untrusted code on Modal.com. PROACTIVELY activate for: modal.Sandbox, safe user code execution, coding playgrounds, named sandboxes, PTY sessions, filesystem snapshots, timeout and resource limits, egress policies, sandbox lifecycle cleanup, terminate(), and security review for code execution.
  Provides: sandbox security checklist, lifecycle and cleanup patterns, egress/resource-limit recipes, and snapshot/PTY usage examples.
---

# Modal Sandboxes Knowledge

Use this skill for Modal Sandbox design, security, and operations. For ordinary functions, GPU jobs, or deployment topics, use `modal-compute:modal-compute-knowledge`.

## Essential security checklist

1. Treat all submitted code and files as untrusted.
2. Use explicit timeout, CPU, memory, and disk constraints.
3. Prefer deny-by-default network egress; allow only required destinations.
4. Clean up every sandbox with `terminate()` or a scoped lifecycle.
5. Avoid passing long-lived credentials into sandbox environments unless strictly required.
6. Capture stdout/stderr and return codes separately for auditing and debugging.

## Common patterns

- **One-shot execution**: create a sandbox, run a command, collect output, terminate.
- **Named sandbox**: reuse a per-session sandbox for interactive workflows.
- **PTY session**: support shell-like interaction while preserving resource limits.
- **Snapshot workflow**: prebuild filesystem state, then launch from a known baseline.

## Detailed reference

See `references/sandboxes-code-execution.md` for code examples and operational notes.
