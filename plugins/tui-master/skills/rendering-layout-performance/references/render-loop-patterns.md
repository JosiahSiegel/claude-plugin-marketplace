# Render Loop Patterns

## Event-driven loop

The most efficient TUI renders when state changes. Inputs include key events, mouse events, paste events, resize notifications, timers, worker messages, and data updates. Merge them into an update path that decides whether a redraw is needed.

```text
while running:
  msg = next(input, resize, timer, worker)
  model, effects, dirty = update(model, msg)
  schedule(effects)
  if dirty or msg is Resize:
    frame = view(model, terminal_size)
    diff_and_flush(previous_frame, frame)
    previous_frame = frame
```

## Tick-driven loop

Use ticks for animation, spinners, clocks, polling dashboards, and transient status. Cap the tick rate. Many TUIs feel responsive at 10 to 30 FPS for animation and much lower for dashboards. Prefer no tick when idle.

## Rendering architectures

Immediate-mode TUIs redraw a complete logical view from state each frame and rely on diffing/batching to make terminal writes efficient. Retained-mode TUIs keep a widget tree with lifecycle, invalidation, and focus state. Both can work well; immediate mode favors deterministic rendering and simple state flow, while retained mode favors rich widgets and local component state.

## Dirty-region and diff rendering

Frameworks often maintain a previous frame and emit only changed cells. If you build this yourself:

- Model each cell as grapheme/text, style, and width metadata.
- Compare previous and next grids.
- Group adjacent changed cells by row and compatible style.
- Move cursor, write runs, reset styles deliberately, and flush once.
- Track double-width characters carefully; clearing one half corrupts layout.
- Invalidate neighboring cells when wide glyphs, combining marks, or style spans change.

Tiny cell-buffer diff pseudo-code:

```text
diff(prev, next):
  writes = []
  for y in 0..height:
    x = 0
    while x < width:
      if prev[y][x] == next[y][x]:
        x += 1; continue
      start = x
      style = next[y][x].style
      text = ""
      while x < width and prev[y][x] != next[y][x] and next[y][x].style == style:
        text += next[y][x].grapheme_or_space
        if next[y][x].width == 2: mark_following_cell_consumed()
        x += max(1, next[y][x].width)
      writes.append(move(y,start) + sgr(style) + text)
  return concat(writes) + sgr(reset) + flush
```

Damage tracking can operate at full-grid, row, rectangular-region, or run level. Simpler full-frame diffing is usually fast enough; finer damage tracking helps dashboards and remote links only when it does not add correctness bugs.

## Layout recipes

### Sidebar/detail

Use for navigation plus contextual detail. Collapse sidebar first on narrow screens.

```text
80x24
┌──────────────┬──────────────────────────────────────────────────────────────┐
│ Projects     │ Project api-service                                         │
│ > api        │ Status: passing                                             │
│   web        │                                                              │
│   worker     │ Recent jobs                                                 │
│              │  10:31 build       ok                                       │
│              │  10:28 test        ok                                       │
├──────────────┴──────────────────────────────────────────────────────────────┤
│ q quit  / search  Enter open  ? help                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

Rules: keep selection state in sidebar, detail scroll state separate, and expose the selected item textually (`>` or label) without relying only on color.

### Table/detail

Use for data explorers where the table is primary and detail changes with selection.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ Filter: error_                                      12 results              │
├────┬──────────────┬──────────┬──────────────────────────────────────────────┤
│ >  │ api-17       │ failed   │ timeout waiting for db                       │
│    │ api-18       │ running  │ migrations                                   │
├────┴──────────────┴──────────┴──────────────────────────────────────────────┤
│ Detail api-17: retries=3 duration=62s owner=platform                        │
│ Actions: Enter open  r retry  c copy id                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

Rules: right-align numbers, truncate prose predictably, preserve horizontal scroll/column hiding policy, and render only visible rows.

### Wizard

Use for linear setup where progress and validation matter.

```text
┌─ Setup database ────────────────────────────────────────────────────────────┐
│ Step 2 of 4: Connection                                                     │
│                                                                             │
│ Host        [db.internal________________]                                   │
│ Port        [5432____]                                                      │
│ SSL         (x) require  ( ) disable                                        │
│                                                                             │
│ Error: Port must be a number from 1 to 65535                                │
│                                                                             │
│ Back: Esc/B   Next: Enter   Cancel: Ctrl+C                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

Rules: keep validation close to fields, support back/cancel, and provide non-interactive flags/config for automation.

### Dashboard

Use for monitoring, but throttle updates and include units.

```text
┌ CPU 42% ──────┐ ┌ Memory 7.2/16 GiB ┐ ┌ Errors 3 last 5m ┐
│ ▁▂▃▅▆▅▃▂      │ │ ███████░░░░░░░░░  │ │ api 2  web 1    │
└───────────────┘ └───────────────────┘ └─────────────────┘
┌ Logs ───────────────────────────────────────────────────────────────────────┐
│ 10:31 api timeout                                                           │
│ 10:30 web recovered                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

Rules: charts are summaries, not the only data. Add textual values, reduce motion over SSH/CI, and coalesce frequent metric updates.

### Tiny-terminal fallback

Render a useful fallback instead of broken panes.

```text
32x8
App needs 60x15 for full UI.
Current: 32x8

Use:
  app --plain status
  app --json status

q quit
```

Rules: define minimum sizes per view, never panic on zero/very small dimensions, and keep quit/help visible.

## Layout and viewport management

Use constraint, flex, grid, or split layouts so panes respond to terminal dimensions. Define minimum sizes for each region and a tiny-terminal fallback. Scroll regions and viewports need explicit state: content length, visible range, offset, cursor/selection, horizontal scroll, and resize behavior. Terminal hardware scroll regions can be efficient but complicate diffing; prefer framework abstractions unless building a pager or log viewer.

## Virtualization

Large lists and tables should render only visible rows plus small overscan. Keep selection and scroll offset in state. Avoid materializing huge styled strings every frame.

## Profiling and performance budgets

Measure frame time, bytes written per frame, flush count, input-to-render latency, allocation rate, and idle CPU. In managed runtimes, watch GC pressure from rebuilding large styled strings or widget trees every tick. Optimize only after identifying whether the bottleneck is layout, text measurement, diffing, terminal I/O, or data processing.

## Remote terminal performance

SSH, containers, serial links, and multiplexers amplify tiny-write costs. Reduce cursor movement, avoid full-screen clears, compress updates into contiguous writes, and throttle high-frequency metrics. GPU-accelerated local terminals do not remove the cost of bytes crossing a network or parser work inside a multiplexer.
