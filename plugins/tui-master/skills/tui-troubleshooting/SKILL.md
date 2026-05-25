---
name: tui-troubleshooting
description: |
  Use this skill when a terminal UI freezes, hangs, shows a blank screen, corrupts terminal state, leaves raw mode stuck, stops responding to input, garbles output, breaks colors/cursor state, fails over SSH/tmux/screen, behaves differently on Windows/ConPTY, or needs deep root-cause analysis for subtle terminal failure modes. PROACTIVELY activate for: TUI freeze, terminal hang, blank TUI, raw mode stuck, stdin paused, no input events, alternate screen stuck, mouse mode stuck, bracketed paste markers, garbled terminal output, corrupted cursor/colors, partial renders, resize races, terminal state cleanup bugs, npm run tui froze, and debugging terminal gotchas. Provides: freeze/hang diagnosis, terminal recovery, startup and cleanup lifecycle checks, platform triage, and fix patterns.
---

# TUI Troubleshooting: Freezes, Hangs, Blank Screens, and Terminal State Corruption

Use this skill when the user reports that a TUI "froze", "hung", "blanked the terminal", "stopped accepting input", "left the terminal broken", or "works in one terminal but not another". Treat these reports as terminal lifecycle failures until proven otherwise.

## First response rule

Do not give a shallow checklist. Establish the failure class, inspect startup and cleanup order, and look for a concrete lifecycle bug:

1. Does the app enter raw mode, alternate screen, mouse, focus, or bracketed paste?
2. Is every mode restored on normal exit, Ctrl-C, exception, panic, rejected promise, and early return?
3. Is stdin flowing after terminal setup?
4. Does the app render and flush at least one frame before waiting on async work or input?
5. Can logs, stderr, background tasks, or child processes write into the same terminal surface?
6. Does the bug reproduce only in tmux, SSH, Windows/ConPTY, CI, or a non-TTY pipe?

## High-probability freeze causes

Prioritize these before exotic terminal protocol issues:

- **Raw mode without restore.** Echo is disabled and line editing is gone, making the shell look frozen after a crash or early return.
- **Paused stdin never resumed.** In Node, `process.stdin.pause()` followed by raw mode without `resume()` prevents `data` events; the UI may wait forever.
- **Missing first render.** The app enters alternate screen/raw mode, starts an async status check, and never flushes an initial frame, so users see a blank screen.
- **Blocking startup work.** Synchronous file/network/process calls run before the first draw and starve the event loop or render loop.
- **Input mode mismatch.** The code waits for line-oriented input while stdin is raw, or waits for raw key events while stdin is cooked or paused.
- **Cleanup mode leak.** Alternate screen, mouse reporting, focus events, or bracketed paste remain enabled after exit.

## Minimal diagnostic posture

Ask for or inspect:

- Language/framework and terminal library.
- Startup sequence from process start through first render.
- Cleanup/guard/finally/defer/Drop/atexit/signal handlers.
- Whether stdin/stdout/stderr are TTYs.
- Whether failure occurs locally, over SSH, in tmux/screen/Zellij, on Windows, or in CI.
- Raw terminal symptoms: echo off, cursor hidden, blank alternate screen, paste wrappers, mouse clicks swallowed, garbled sequences.

## Recovery commands for users

When a terminal is stuck, tell the user how to recover before deeper debugging:

```sh
stty sane
reset
printf '\033[?1049l\033[?25h\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?2004l\033[?1004l\033[0m'
```

On Windows PowerShell, closing the tab is sometimes the fastest recovery when a child process left ConPTY in a bad state.

## Fix pattern to prefer

Every TUI should use one lifecycle owner:

1. Verify TTY or choose non-TUI mode.
2. Install cleanup guards first.
3. Enter alternate screen/raw mode and optional mouse/paste/focus modes.
4. Resume/ref stdin if raw key events are needed.
5. Render and flush an initial frame immediately.
6. Start async work after the first frame.
7. Route logs away from the controlled terminal surface.
8. Restore modes in reverse order exactly once.

## Reference files

- `references/freeze-hang-diagnosis.md` - Root causes, symptoms, diagnostics, fix sketches, and prevention patterns for startup and runtime hangs.
- `references/terminal-state-corruption.md` - Garbled display, wrong colors, cursor bugs, partial renders, interleaved writes, and resize/render races.
- `references/diagnostic-playbook.md` - Decision trees with concrete commands for freezes, stuck terminal state, no input, SSH/tmux, Windows, and garbled output.
