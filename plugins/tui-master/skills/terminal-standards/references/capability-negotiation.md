# Capability Negotiation Reference

## Detection sources

Use multiple weak signals rather than one magic variable:

- TTY checks for stdin/stdout/stderr.
- `TERM`, `COLORTERM`, `TERM_PROGRAM`, `WT_SESSION`, `TMUX`, `STY`, `SSH_TTY`.
- Framework/library color and terminal feature detection.
- terminfo where available.
- Bounded terminal queries where safe.
- Explicit user flags and config, which should win over auto-detection.

## User override precedence

1. Explicit CLI flags such as `--color=always|auto|never`, `--plain`, `--tui`, `--no-tui`, `--ascii`.
2. Environment variables such as `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, `FORCE_COLOR`, `TERM=dumb`.
3. TTY and terminal detection.
4. Conservative defaults.

## Multiplexer considerations

Inside tmux or screen, feature claims may describe the multiplexer rather than the outer terminal. Some sequences are translated, blocked, or require passthrough. Test alternate screen, mouse, bracketed paste, clipboard, focus events, and truecolor under the multiplexer versions you claim to support.

## Windows considerations

Modern Windows Terminal and ConPTY support broad VT behavior. Classic console hosts may require enabling virtual terminal processing. Avoid assuming Unix PTY semantics on Windows; ConPTY has different buffering and process-hosting behavior that matters for tests and embedding child TUIs.
