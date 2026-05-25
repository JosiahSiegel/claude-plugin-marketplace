---
name: tui-testing-debugging
description: |
  This skill should be used when the user asks to test, debug, snapshot, validate, reproduce, or automate terminal UIs, curses apps, raw ANSI output, PTY-driven interactions, virtual terminal emulators, ConPTY behavior, resize tests, keyboard/mouse/paste tests, or flaky terminal snapshots. PROACTIVELY activate for: TUI testing, snapshot tests, golden files, pty integration tests, pseudo-terminal automation, ConPTY, Pexpect, node-pty, vt emulators, Textual Pilot, Ratatui snapshots, Bubble Tea tests, terminal debug logs, and CI failures. Provides: layered test strategy, deterministic snapshot rules, PTY/ConPTY patterns, debugging playbooks, and flake prevention.
---

# TUI Testing and Debugging with Snapshots, PTYs, Virtual Terminals, and ConPTY

Use this skill when a TUI needs reliable tests or when an interactive terminal bug must be reproduced outside a human terminal session.

## Four-layer test strategy

1. **Pure state tests.** Test reducers, update functions, focus transitions, validation, sorting, filtering, and command scheduling without a terminal.
2. **Component/render snapshots.** Render widgets at fixed width, height, theme, color level, locale, and time. Compare stable text or cell grids.
3. **Virtual terminal tests.** Feed ANSI output into a terminal emulator and assert final cells, cursor, styles, scrollback, and cleanup.
4. **PTY integration tests.** Spawn the real program, send keys/paste/resize, and assert visible behavior and exit status.

## Snapshot stabilization

Freeze or normalize:

- Terminal size.
- Theme and color support.
- Time, random IDs, network data, spinners, cursor blink.
- Unicode mode and ambiguous-width assumptions.
- File paths when tests run cross-platform.
- Progress rates and async scheduling.

Prefer semantic assertions for behavior and snapshots for stable visual contracts.

## Debugging workflow

1. Reproduce with the smallest terminal size and input sequence.
2. Capture raw input and output bytes when protocol behavior is suspected.
3. Separate stdout, stderr, logs, and alternate-screen output.
4. Disable animations and color to isolate layout from style.
5. Test outside and inside tmux/screen/SSH if relevant.
6. On Windows, test through ConPTY when Windows support is claimed.

## CI rules

- Do not assume CI has a real TTY.
- Use PTY wrappers where integration tests require terminal behavior.
- Mark terminal-emulator-specific tests explicitly.
- Keep snapshots deterministic and reviewable.
- Capture logs and final terminal frames as artifacts on failure.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Snapshot flake | time, spinner, random data, terminal width | freeze inputs and normalize output |
| Works manually, fails in CI | no TTY or different TERM | create PTY or use non-TUI mode |
| Windows tests fail only | Unix PTY assumptions | test via ConPTY and account for line endings |
| Raw bytes differ but screen same | testing sequences not final cells | assert virtual terminal state |
| Debug logs corrupt UI | logs write to controlled screen | route logs to file or panel |

## Reference files

- `references/test-strategy.md` - Test layers, tools, and assertions by ecosystem.
- `references/debugging-playbook.md` - Byte capture, terminal reset, CI, Windows, and flake triage.
