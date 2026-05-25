# Multiplexer and Remote Terminal Reference

## tmux

- tmux often advertises a tmux-specific `TERM`, so outer terminal features may need tmux configuration to pass through.
- Truecolor support can require appropriate terminal-overrides or feature flags depending on tmux version and site config.
- OSC 52 clipboard access is configurable and often intentionally restricted.
- DCS passthrough can carry some sequences to the outer terminal, but relying on it makes behavior version- and configuration-dependent.
- Mouse events are mediated by tmux; test panes, copy mode, alternate screen, wheel scrolling, and drag behavior.

## GNU screen

- screen is more conservative and may filter or transform modern sequences.
- Expect weaker support for OSC/DCS extensions, focus events, truecolor configuration, and advanced keyboard protocols.
- Provide 16/256-color and no-clipboard fallbacks.

## Zellij

- Zellij has its own pane, keybinding, and mode model. It may intercept shortcuts and mediate copy, mouse, and layout behavior.
- Test app shortcuts against Zellij defaults. Avoid assuming Ctrl/Alt chords are available.

## Passthrough policy

Use passthrough only for optional enhancement. Core workflows should not depend on terminal images, clipboard writes, focus notifications, or private keyboard protocols surviving a multiplexer chain. If a feature is attempted, detect failure or timeout and continue visibly.

## SSH and remote sessions

- Remote `TERM` describes what the remote side believes the terminal is; it may not reflect the local emulator accurately, especially through jump hosts or multiplexers.
- Resize propagation can be delayed or lost; treat `SIGWINCH`/resize events as hints and periodically tolerate stale dimensions.
- Clipboard and image protocols cross a trust boundary. Many environments block them for good reason.
- Agent forwarding is unrelated to terminal rendering but is a security-sensitive remote feature. Do not require it for UI behavior; clearly separate authentication failures from terminal capability failures.

## Latency and bandwidth tactics

- Render on state change, not busy loops.
- Batch writes and flush once per frame.
- Prefer dirty-region/cell-diff updates over full clears.
- Avoid high-frequency mouse hover effects over SSH unless throttled.
- Cap dashboard updates to the rate users can read.
- Offer `--no-animation`, `--low-bandwidth`, or reduced refresh options.

## Remote-safe UX

- Keep keyboard navigation complete; mouse may be disabled by SSH clients, multiplexers, or user preference.
- Avoid local-only assumptions such as opening local files, using local clipboard, or rendering local images from remote paths.
- Preserve useful scrollback in non-full-screen mode for logs and long-running commands.
- Provide recovery instructions that work remotely: quit keys, `reset`, `stty sane`, and `--no-tui`.
