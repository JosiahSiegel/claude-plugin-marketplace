# Diagnostic Playbook

Use these workflows when a user reports freezing, hanging, blank screens, no input, corrupted output, or platform-specific terminal behavior. Prefer file logs or PTY captures over printing to stdout/stderr while the TUI is active.

## Setup: collect environment facts

Ask for or log:

```sh
printf 'TERM=%s\nCOLORTERM=%s\nTMUX=%s\nSTY=%s\nZELLIJ=%s\nSSH_TTY=%s\n' "$TERM" "$COLORTERM" "$TMUX" "$STY" "$ZELLIJ" "$SSH_TTY"
stty -a
stty size
tput colors
```

Node-specific:

```js
log({ stdinTTY: process.stdin.isTTY, stdoutTTY: process.stdout.isTTY, stderrTTY: process.stderr.isTTY, term: process.env.TERM });
```

PowerShell/Windows:

```powershell
$PSVersionTable
$env:TERM
$env:WT_SESSION
$env:ConEmuANSI
[Console]::InputEncoding
[Console]::OutputEncoding
```

## 1. "My TUI freezes on startup" decision tree

1. **Does the process still run?**
   - Unix: `ps -o pid,stat,pcpu,pmem,command -p <pid>`
   - Windows: `Get-Process -Id <pid> | Format-List Id,CPU,Responding,Path`
   - If not running and terminal is broken, jump to stuck-after-exit.

2. **Did it enter alternate screen before drawing?**
   - Capture raw output with a PTY recorder or add a file log before/after terminal entry, first render, and flush.
   - Look for `?1049h` with no visible frame after it.
   - Fix: render and flush a loading frame before async checks.

3. **Is stdin paused or not flowing?**
   - Node: grep for `process.stdin.pause()`, `setRawMode`, `resume`, `ref`, `unref`, `readline`.
   - If `pause()` occurs before raw mode and no later `resume()`, fix startup ordering.

4. **Is startup blocking before first draw?**
   - Search for sync calls: `readFileSync`, `execSync`, `spawnSync`, large JSON parsing, blocking network/database calls.
   - Add timestamps to a file: `start`, `enter terminal`, `first render`, `after status check`.
   - Fix: draw first, then run work asynchronously.

5. **Is the event loop spinning?**
   - High CPU: suspect render/update loop. Count render calls per second.
   - Low CPU: suspect awaiting input, paused stdin, deadlock, or blocked child process.

6. **Minimum expected fix.**
   - Install cleanup guard.
   - Enter terminal modes.
   - Resume stdin if using raw input.
   - Render and flush first frame.
   - Start async work.

## 2. "My TUI freezes after an action" decision tree

1. **Identify the action boundary.** Log to a file before handler, after handler, before async command, after command, before render, after flush.

2. **Does CPU spike?**
   - Yes: render loop or expensive computation. Count renders and inspect state mutation during render.
   - No: blocked I/O, child command, channel/promise wait, or input ownership bug.

3. **Did the action spawn a child process?**
   - Check whether child stdio is inherited.
   - If the child is interactive, suspend the TUI or run it outside alternate screen.
   - If noninteractive, pipe output into the model.

4. **Did the action change input mode?**
   - Check raw/cooked transitions, readline creation, prompt libraries, and focus changes.
   - Ensure the same component restores input ownership.

5. **Did the action resize, open a modal, or change layout?**
   - Check for out-of-bounds coordinates and stale cached dimensions.
   - Recompute layout from current size.

6. **Add a timeout.** Any async operation triggered from UI should have timeout/cancel behavior and surface an error frame.

## 3. "My terminal is stuck after my TUI exits" decision tree

1. **Recover first.**

```sh
stty sane
reset
printf '\033[0m\033[?25h\033[r\033[?1049l\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?2004l\033[?1004l'
```

2. **Classify the stuck mode.**
   - No echo / weird Enter: raw/cbreak/noecho leak.
   - Blank screen/no scrollback: alternate screen leak.
   - Cursor missing: cursor hide leak.
   - Clicks weird: mouse reporting leak.
   - Paste markers: bracketed paste leak.
   - Escape sequences on focus: focus reporting leak.
   - Prompt color wrong: SGR reset leak.

3. **Inspect cleanup coverage.**
   - Normal quit.
   - Ctrl-C/SIGINT.
   - SIGTERM.
   - Exception/panic/rejected promise.
   - Early return after failed initialization.
   - Test failure.

4. **Fix with idempotent reverse-order cleanup.** Cleanup should be safe to call multiple times and should not throw.

5. **Prove it.** Add tests that intentionally crash after enabling each terminal mode and assert cleanup bytes or final terminal state.

## 4. "My TUI shows garbled output" decision tree

1. **Are escape sequences visible?**
   - Visible `^[`, `[31m`, `?1049h`: terminal does not support/parse the sequence, VT mode disabled, or writes are interleaved/incomplete.
   - Windows: verify VT processing or use a library that enables it.

2. **Are logs mixed into the UI?**
   - Disable all stdout/stderr logging.
   - Redirect logs to a file.
   - Spawn children with piped stdio.

3. **Are borders/columns misaligned?**
   - Test CJK, emoji, combining marks, and ambiguous-width characters.
   - Replace Unicode borders/icons with ASCII mode.
   - Use width/grapheme libraries.

4. **Does it happen during resize?**
   - Log sizes for resize event, layout, render, flush.
   - Coalesce resize events and recompute layout.

5. **Does it happen over slow SSH?**
   - Reduce frame rate and flush once per frame.
   - Use diff rendering instead of full clears.

## 5. "My TUI doesn't respond to input" decision tree

1. **Check TTY and stream ownership.**
   - Node: `process.stdin.isTTY`, `setRawMode`, `resume`, data listener installed.
   - Python: curses/prompt_toolkit/Textual owns input; avoid direct reads.
   - Go/Rust: event polling loop active and not blocked.

2. **Raw vs cooked mismatch.**
   - Raw key handler expects bytes/events: raw mode on, stdin flowing.
   - Line prompt expects Enter-delimited lines: raw mode off or framework-managed.

3. **Conflicting libraries.**
   - Do not mix readline with raw listeners unless the lifecycle is explicit.
   - Do not run a prompt library inside a full-screen framework without suspending the framework.

4. **Escape timing and Alt/Esc ambiguity.**
   - In SSH/tmux, Esc-based sequences can be delayed.
   - Tune escape timeout or use framework key protocols when available.

5. **Focus/mouse assumptions.**
   - Keyboard must work without mouse and without focus events.
   - If mouse is required for a path, that is an accessibility and compatibility bug.

## 6. "My TUI works locally but breaks over SSH/tmux" decision tree

1. **Compare environments.**

```sh
echo "$TERM"
echo "$TMUX $STY $ZELLIJ $SSH_TTY"
tput colors
stty size
infocmp | head
```

2. **Check capability assumptions.**
   - Truecolor may need tmux overrides.
   - Mouse/focus/clipboard protocols may be filtered.
   - Alternate screen can be inhibited by configuration.
   - Kitty/iTerm2 extensions rarely pass through all remotes.

3. **Check resize propagation.**
   - Resize the outer terminal and log the app's received dimensions.
   - If missing, verify SIGWINCH/event handling and multiplexer settings.

4. **Check latency behavior.**
   - Avoid rendering faster than data changes.
   - Coalesce input and redraw events.
   - Reduce animation/spinner frame rates.

5. **Fallback.** Use plain ANSI/16-color/no-mouse mode when uncertain, and provide `--no-mouse`, `--color=auto|never`, `--ascii`, or `--plain` switches.

## 7. "My TUI works on Unix but breaks on Windows" decision tree

1. **Identify the host.** Windows Terminal, VS Code terminal, classic conhost, ConEmu, Git Bash, WSL, or a ConPTY test harness.

2. **Are ANSI sequences printed literally?**
   - VT processing may not be enabled.
   - Use Crossterm, tcell, Terminal.Gui, Spectre.Console, prompt_toolkit, or another library that handles Windows console setup.

3. **Does output appear late or tests hang?**
   - ConPTY buffering differs from Unix PTYs.
   - Flush after frames.
   - Avoid assertions that depend on exact byte chunking.

4. **Do keys differ?**
   - Ctrl/Alt/function key encodings and terminal host behavior vary.
   - Test keybindings in Windows Terminal and the advertised host.

5. **Does cleanup fail?**
   - Signal semantics differ; `SIGTERM`/Ctrl-C handling may not match Unix.
   - Ensure cleanup runs on process exit, Ctrl-C, exceptions, and framework shutdown hooks.

6. **Path and encoding checks.**
   - Use UTF-8 internally.
   - Avoid assuming Unix paths in snapshot tests.
   - Normalize CRLF where output comparisons are line-oriented.

## Evidence to include in bug reports

- Exact command and terminal host.
- OS, shell, `$TERM`, multiplexer/SSH status.
- Whether stdin/stdout/stderr are TTYs.
- First-frame timing: terminal entry, first render, first flush, first async operation.
- Cleanup modes enabled and disabled.
- Raw output capture or final virtual terminal snapshot.
- Minimal key sequence or action that triggers the freeze.
