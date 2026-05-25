---
name: rendering-layout-performance
description: |
  This skill should be used when the user asks to implement, optimize, debug, or review TUI rendering, layout, repainting, flicker, frame buffers, diff rendering, terminal resize behavior, alternate screen lifecycle, scrollback, viewports, tables, dashboards, progress displays, or performance over SSH/tmux. PROACTIVELY activate for: rendering performance, layout bugs, flicker, alternate screen cleanup, resize handling, terminal dashboards, frame pacing, virtual DOM/cell buffers, double buffering, dirty regions, scroll regions, long-running tasks, and high-frequency updates. Provides: render-loop rules, layout patterns, performance budgets, lifecycle cleanup checks, and failure triage.
---

# TUI Rendering, Layout, Performance, and Alternate Screen Lifecycle

Use this skill when a TUI draws incorrectly, flickers, wastes CPU, mishandles resize, corrupts scrollback, or needs a robust rendering architecture.

## Rendering principles

1. **Render from state.** The view should be a pure projection of current state and terminal dimensions.
2. **Batch writes.** Build a frame, diff or queue updates, then flush once. Avoid many small writes.
3. **Minimize terminal control churn.** Repeated style resets, cursor moves, and full clears are expensive and visible over remote links.
4. **Throttle high-frequency sources.** Coalesce logs, metrics, mouse motion, resize storms, and progress updates.
5. **Define frame ownership.** A full-screen renderer owns the screen while active; background output goes elsewhere.

## Layout rules

- Compute layout from `width` and `height` every frame or on every resize event.
- Establish minimum usable dimensions and render a clear small-screen message below that threshold.
- Prefer constraints, flex, grid, splits, or framework layout primitives over magic coordinates.
- Keep focus, selection, viewport offset, and cursor position in UI state.
- Test narrow, wide, tall, tiny, and odd terminal sizes.

## Alternate screen lifecycle

Use alternate screen for full-screen apps when users should return to the original scrollback after exit. Do not use it for simple output where command results should remain visible.

Cleanup must restore:

- Alternate screen.
- Raw/cbreak mode.
- Mouse tracking.
- Bracketed paste.
- Focus and extended keyboard modes.
- Cursor visibility and style.
- Terminal title or palette changes if modified.

## Performance checklist

- UI loop does not block on network, disk, child processes, or API calls.
- Long operations publish progress through messages/channels/tasks.
- Render rate is capped to useful human perception, especially for dashboards.
- Resize events are coalesced before expensive recalculation.
- Tables and lists virtualize or page large datasets.
- Logging does not write to stdout/stderr while the TUI owns the screen.
- Remote terminals and SSH latency are part of testing if supported.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Flicker | clearing entire screen or flushing repeatedly | diff/batch writes, avoid full clears |
| High CPU while idle | unconditional redraw loop | render on events or capped tick |
| Corrupted shell after crash | missing cleanup on panic/exception | central terminal guard and finally/defer/drop cleanup |
| Layout overlap | absolute coordinates or stale dimensions | recompute constraints after resize |
| Logs appear inside UI | stdout/stderr logging while alternate screen active | file sink, in-app log panel, or buffered logs |

## Reference files

- `references/render-loop-patterns.md` - Frame buffers, dirty regions, throttling, and event loops.
- `references/alternate-screen-lifecycle.md` - Setup/teardown checklist and crash recovery.
