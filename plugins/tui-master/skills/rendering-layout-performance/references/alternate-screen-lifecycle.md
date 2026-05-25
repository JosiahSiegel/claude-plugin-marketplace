# Alternate Screen Lifecycle Reference

## Setup order

1. Verify stdin/stdout are TTYs or the framework has an explicit terminal handle.
2. Register cleanup before enabling modes.
3. Enable raw/cbreak mode.
4. Enter alternate screen if this is a full-screen TUI.
5. Enable mouse, bracketed paste, focus, or keyboard extensions only when needed.
6. Hide cursor only if the renderer controls cursor restoration.
7. Start the event loop.

## Teardown order

1. Stop workers or detach their output from the terminal.
2. Disable optional modes: mouse, paste, focus, extended keyboard.
3. Show/restore cursor.
4. Leave alternate screen.
5. Disable raw/cbreak mode.
6. Flush final output and restore logging.

## Crash recovery

Install language-appropriate panic, exception, signal, and cancellation handlers. Cleanup code must tolerate partially initialized state and repeated calls. If the display is corrupted, document recovery commands such as `reset`, `stty sane`, reopening the terminal tab, or disabling the TUI with `--no-tui`.

## When not to use alternate screen

Do not use alternate screen for single progress bars, command output users expect to copy, non-interactive reports, or errors that should remain in scrollback. Inline progress regions are often better for package managers, build tools, and CI-friendly logs.
