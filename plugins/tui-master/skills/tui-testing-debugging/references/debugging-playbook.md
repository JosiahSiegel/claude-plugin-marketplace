# TUI Debugging Playbook

## Capture useful evidence

- Terminal emulator and version.
- OS and shell.
- `TERM`, `COLORTERM`, `TERM_PROGRAM`, `WT_SESSION`, `TMUX`, `STY`, `SSH_TTY`.
- Terminal size and font if Unicode alignment is involved.
- Raw input sequence and output bytes for protocol issues.
- Final visible frame and logs.
- Whether stdout/stderr were TTYs, pipes, or redirected files.

## Reset corrupted terminals

Common recovery steps include leaving the app, running `reset`, running `stty sane` on Unix-like systems, reopening the tab, or using the app's documented `--no-tui` mode. Tests should verify cleanup so users rarely need these.

## Byte-level debugging

When escape sequences are suspected, inspect raw bytes separately from rendered output. Capture hex dumps of input and output streams, annotate ESC/CSI/OSC/DCS boundaries, and compare against a virtual terminal's final cell grid. A virtual terminal assertion may show the screen is correct even when byte sequences vary. Conversely, byte captures can reveal missing cleanup sequences, unbalanced SGR, unsafe OSC output, or pasted data being parsed as commands.

Hex dump annotation example:

```text
00000000  1b 5b 3f 31 30 34 39 68  1b 5b 3f 32 35 6c 1b 5b  |.[?1049h.[?25l.[|
          ESC [ ? 1 0 4 9 h        ESC [ ? 2 5 l  ESC [
          enter alt screen          hide cursor
00000010  33 31 6d 45 72 72 6f 72  1b 5b 30 6d              |31mError.[0m|
          SGR red "Error"           SGR reset
```

Annotate boundaries first, then interpret parameters. For input bugs, preserve timing and partial reads because parsers often fail when an escape sequence is split across reads.

## Byte capture and replay harness shape

A minimal capture should include bytes and context:

```json
{
  "width": 80,
  "height": 24,
  "env": {"TERM": "xterm-256color", "TMUX": ""},
  "events": [
    {"t_ms": 0, "kind": "spawn"},
    {"t_ms": 30, "kind": "stdin", "bytes_hex": "1b5b3230307e70617374651b5b3230317e"},
    {"t_ms": 60, "kind": "resize", "width": 100, "height": 30},
    {"t_ms": 90, "kind": "stdout", "bytes_hex": "1b5b3f32356c..."}
  ]
}
```

Replay modes:

1. Feed input events into the update loop with a fake clock to isolate state bugs.
2. Spawn the binary under a PTY and replay stdin/resize timing to reproduce integration bugs.
3. Feed captured stdout into a virtual terminal to assert final cells and terminal modes.

Keep sensitive data out of recordings. Redact tokens before saving, and render escape bytes visibly when sharing logs.

## Recording and replay

For hard bugs, record terminal dimensions, environment variables, input events, paste payloads, resize events, timing, and output bytes. Build a replay harness that feeds the same event stream into state/update logic or a PTY. Keep sensitive data out of recordings and sanitize escape sequences before sharing logs.

## Common failure signatures

| Symptom | Likely cause | First check |
|--|--|--|
| Shell stays invisible cursor | Missing `CSI ? 25 h` on exit | Cleanup guard and panic path. |
| User shell remains raw | Raw/cbreak mode not restored | `stty -a`; finally/defer/Drop order. |
| Pasted text executes commands | Bracketed paste disabled or ignored | Input parser and paste mode enable/disable. |
| Garbled title/clipboard | Untrusted OSC emitted | Sanitization and OSC 52/8 gates. |
| Misaligned table after emoji | Width by code point/byte | Grapheme + cell-width library. |
| Works locally, slow over SSH | Too many small writes/full clears | Batch writes, diff frames, throttle ticks. |
| Resize crashes or overlaps | Cached absolute layout | Recompute layout from new dimensions. |

## Windows and ConPTY

Windows terminal behavior depends on host, ConPTY, virtual terminal processing, code page/UTF-8 handling, and the child process model. If a project claims Windows support, test the actual executable through Windows terminal paths, not only Unix PTY simulations.

ConPTY debugging checklist:

- Confirm output VT processing is enabled when using low-level console APIs.
- Confirm UTF-8 mode or framework Unicode conversion behavior.
- Test Ctrl-C, process termination, and child cleanup.
- Compare Windows Terminal and classic conhost if both are supported.
- Capture stdout/stderr bytes around resize and shutdown; ConPTY can coalesce or transform output differently from Unix PTYs.
