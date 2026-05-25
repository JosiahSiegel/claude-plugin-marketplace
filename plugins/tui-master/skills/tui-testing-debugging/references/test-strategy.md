# TUI Test Strategy Reference

## What to assert

- State tests: model transitions, commands scheduled, errors, focus, validation.
- Render snapshots: visible text, layout regions, styles when meaningful, accessibility labels if framework exposes them.
- Virtual terminal tests: final grid, cursor, attributes, scrollback, alternate screen cleanup.
- PTY tests: end-to-end key sequences, paste, resize, exit status, stdout/stderr separation.

## Fixed-size snapshot contract

A useful snapshot is a contract, not a screenshot. Freeze every input that can change rendering:

```yaml
snapshot: table-detail-empty
terminal:
  width: 80
  height: 24
  color: 16
  unicode: ascii
  background: dark
locale: C.UTF-8
clock: 2026-01-02T03:04:05Z
random_seed: 1234
framework: ratatui 0.x / textual x.y / bubbletea x.y
input_state:
  focus: search
  selected_row: 0
  scroll_offset: 0
redactions:
  - timestamps
  - temp paths
assertions:
  - no raw ESC bytes in visible cells
  - selected row has textual marker as well as style
```

Snapshot visible cells and meaningful styles separately where possible. Avoid snapshots that depend on cursor blink, spinners, live network data, localized time formats, terminal theme RGB values, or font-specific glyphs. Keep Unicode and ASCII snapshots separate when glyph choices differ.

## PTY pseudo-flow

End-to-end PTY tests should drive the real binary:

```text
spawn app with env TERM=xterm-256color, COLUMNS=80, LINES=24
wait until visible text contains "Search"
send keys: "abc", Enter
expect visible text contains "3 results"
resize pty to 100x30
expect visible text contains "100x30-specific layout" or stable detail pane
send bracketed paste: ESC[200~payload ESC[201~
expect payload appears literally, not as commands
send Ctrl-C
expect exit code 130 or documented interrupt code
assert terminal cleanup: cursor visible, alt screen left, raw mode restored
capture artifacts on failure: raw bytes, final grid, stderr, env, dimensions
```

Use polling with timeouts rather than fixed sleeps. Assert stdout and stderr separately; debug logs should not corrupt the screen.

## Virtual terminal assertion shape

A virtual terminal test feeds bytes into an emulator model and asserts the final state:

```json
{
  "given": {"width": 40, "height": 8},
  "feed": "raw output bytes from renderer",
  "expect": {
    "cursor": {"row": 7, "col": 0, "visible": true},
    "alt_screen": false,
    "cells": [
      {"row": 0, "col": 0, "text": "Status", "fg": "bold"},
      {"row": 2, "col": 0, "text": "No results"}
    ],
    "scrollback_contains": [],
    "forbidden_modes": ["mouse", "bracketed_paste"]
  }
}
```

Prefer final-cell assertions over exact byte assertions unless validating a protocol encoder. Byte-for-byte output can vary while rendering is correct; final-cell assertions catch user-visible regressions.

## Ecosystem examples

- Rust Ratatui: use fixed-size buffers and snapshot rendered widgets; integration-test event loops through PTY tools.
- Python Textual: use Pilot-style app tests for interactions; combine with unit tests for reactive state.
- Python curses/prompt_toolkit: isolate state logic; use Pexpect or PTY wrappers for integration.
- Go Bubble Tea: test `Update` and `View` separately; use PTY tests for full program behavior.
- Node Ink: use component testing utilities; use node-pty for real terminal flows.
- .NET Terminal.Gui/Spectre.Console: isolate view models and render output; use terminal/console abstraction tests.

## Golden file hygiene

Golden files should be small, stable, and intentional. Store metadata: width, height, color mode, Unicode/ASCII mode, locale, and framework version assumptions. Provide a clear review flow for intentional visual changes.

Golden metadata template:

```yaml
name: dashboard-80x24-dark-256color
command: app dashboard --fixture fixtures/dashboard.json
width: 80
height: 24
stdin: []
env:
  TERM: xterm-256color
  NO_COLOR: null
  COLORTERM: truecolor
platforms_verified:
  - linux-pty
  - windows-conpty
updated_by: intentional visual change description
review_notes: "Column order changed; error state unchanged."
```

## Property and fuzz testing

Property-based tests are useful for reducers, focus traversal, viewport math, Unicode truncation, wrapping, table column sizing, and parser boundaries. Fuzz terminal input parsers with partial escape sequences, malformed CSI/OSC/DCS, huge paste payloads, invalid UTF-8 where applicable, and resize storms.

## CI matrix and ConPTY notes

A credible cross-platform TUI CI plan includes non-TTY tests, Unix PTY tests, Windows ConPTY tests when Windows is supported, fixed-size snapshot tests, and at least one smoke test inside a multiplexer if tmux/screen support is claimed. Store failure artifacts: raw bytes, final virtual screen, logs, dimensions, and environment variables.

Windows notes:

- Run at least one job on Windows, not only Wine or Unix PTY emulation.
- Prefer Windows Terminal/ConPTY paths for modern behavior and a classic conhost smoke test if you claim older console support.
- Verify UTF-8/code page setup, Ctrl-C behavior, resize delivery, process teardown, and virtual terminal processing.
- ConPTY is not byte-identical to Unix PTYs; avoid tests that assume Unix signal or line-discipline details.
- Keep Windows snapshots separate if line endings, fonts, or console mode behavior differ.
