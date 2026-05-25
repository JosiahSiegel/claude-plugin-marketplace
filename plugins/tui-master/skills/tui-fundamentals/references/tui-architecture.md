# TUI Architecture Reference

## Recommended layers

1. **Domain model:** application data and business rules, independent of terminal concerns.
2. **UI model:** selected row, focused control, modal state, viewport offsets, pending edits, theme, terminal size.
3. **Event decoder:** turns raw terminal/framework events into semantic app actions.
4. **Update/reducer:** transforms UI model and schedules side effects.
5. **Renderer/view:** converts state into widgets or a cell buffer.
6. **Terminal manager:** owns raw mode, alternate screen, protocol enablement, cleanup, panic/exception hooks, and signal handling.

## Event loop pattern

- Read input, timers, worker messages, and resize notifications through one channel/queue when possible.
- Coalesce repeated resize, mouse move, and high-frequency data updates.
- Throttle dashboards to the perceptual rate users need, not the data arrival rate.
- Never block the UI loop on network, disk, process, or API work.

## Logging pattern

Full-screen TUIs should not write logs to stdout/stderr while the screen is active. Use one of these patterns:

- Write logs to a file and expose the path in debug help.
- Render logs inside a dedicated scrollback panel.
- Buffer logs while alternate screen is active, flush after exit.
- Provide `--debug-log path` and `--no-tui` modes.

## Distribution contract

Document supported operating systems and terminal emulators, required terminal features and fallbacks, non-interactive usage, exit codes, keybindings, display recovery steps, and environment variables honored for color, accessibility, telemetry, config, and terminal detection.
