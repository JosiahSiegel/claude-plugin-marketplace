# Freeze and Hang Diagnosis

A "frozen terminal" is often not a single bug. It can mean the process is alive but not rendering, input is disabled, stdin is paused, the terminal is in raw mode after exit, or alternate screen cleanup failed. Start by separating **process hang**, **render hang**, **input hang**, and **terminal-state leak**.

## Fast triage

- Does Ctrl-C terminate the process? If yes, inspect cleanup and signal handling. If no, suspect event-loop blockage, native deadlock, or child process wait.
- Does typing appear? If no, echo may be off due to raw mode or the app is still running in alternate screen.
- Does CPU spike? If yes, suspect infinite render/update loop. If no, suspect blocked I/O, awaiting input, paused stdin, or async deadlock.
- Is the screen blank immediately? Suspect alternate screen entered before first flushed render.
- Is the shell broken after exit? Suspect raw mode, cursor, mouse, bracketed paste, focus, color, or alternate-screen cleanup leak.

## Raw mode without restore

**Symptom.** After a crash or Ctrl-C, typed characters do not echo, Enter does not behave normally, Ctrl-C may print `^C` oddly, and the user thinks the terminal froze.

**Root cause.** Raw mode disables canonical input processing and echo. If the program exits before `setRawMode(false)`, `disable_raw_mode()`, `noraw()`, `endwin()`, or equivalent cleanup, the shell inherits a hostile terminal state.

**Diagnostics.** Run `stty -a` in another shell attached to the same terminal if possible, or recover with `stty sane`. Inspect all early returns, exceptions, promise rejections, panics, and signal paths after raw mode is enabled.

**Fix pattern.** Install cleanup before enabling raw mode and make it idempotent.

```js
let cleaned = false;
function cleanup() {
  if (cleaned) return;
  cleaned = true;
  if (process.stdin.isTTY) process.stdin.setRawMode(false);
  process.stdout.write('\x1b[?25h\x1b[?1049l\x1b[0m');
}
process.once('exit', cleanup);
process.once('SIGINT', () => { cleanup(); process.exit(130); });
process.once('uncaughtException', err => { cleanup(); console.error(err); process.exit(1); });
process.once('unhandledRejection', err => { cleanup(); console.error(err); process.exit(1); });
```

**Prevention.** Use framework lifecycle guards, `try/finally`, Rust RAII guards, Go `defer`, Python `curses.wrapper`, or a single terminal-session object that restores modes in reverse order.

## Stdin paused/resumed mismatch

**Symptom.** The screen may draw once or remain blank, but no keypresses arrive. The process is alive and waiting. This is common in Node apps launched by `npm run tui`.

**Root cause.** `process.stdin.pause()` removes the stream from flowing mode. Enabling raw mode does not necessarily resume `data` events. If code pauses stdin before raw mode, then waits for key events without `resume()` or a `readable` loop, input never reaches the handler.

**Diagnostics.** Search for `stdin.pause()`, `setRawMode`, `on('data')`, `readline`, `unref`, and `resume`. Add temporary file logging around startup: "before raw", "after raw", "after resume", "data event". Do not log to the TUI screen.

**Fix pattern.** Configure stdin in one place and resume before waiting.

```js
if (!process.stdin.isTTY) throw new Error('TUI requires a TTY');
process.stdin.setEncoding('utf8');
process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.ref();
process.stdin.on('data', key => dispatchKey(key));
renderInitialFrame();
```

**Prevention.** Avoid mixing `readline`, raw `data` listeners, and framework input managers. If a status check temporarily stops input, explicitly restore the prior stream state.

## Blocking I/O on the main thread

**Symptom.** The app appears frozen on startup or after an action; no spinner advances; resize and input are ignored. CPU may be low if blocked on disk/network, or high if doing sync computation.

**Root cause.** Synchronous file reads, child process waits, DNS/network calls, JSON parsing, compression, database calls, or CPU-heavy layout block the UI thread before the render loop can flush.

**Diagnostics.** Add timestamped file logs before and after suspicious calls. In Node, inspect `readFileSync`, `execFileSync`, `spawnSync`, sync globbing, and large JSON parsing. In Python, inspect blocking calls inside Textual/curses callbacks. In Go/Rust, inspect locks and synchronous commands on the UI goroutine/thread.

**Fix pattern.** Draw first, then move work off the UI path.

```js
enterTerminal();
render({status: 'Checking project...'});
await flushOutput();
void checkProjectAsync().then(result => {
  update({result});
  scheduleRender();
});
```

**Prevention.** Treat first paint as a service-level objective. Put long work in workers, tasks, goroutines, commands, or async jobs that publish messages back to the UI.

## Deadlock in the event loop

**Symptom.** The UI waits forever after a particular action. CPU is usually idle. Logs show operation A waiting for operation B while B waits for A, or a render callback that never fires.

**Root cause.** Two async operations wait on each other, a promise is never resolved, a channel is never closed, or a lock is held while scheduling a callback that needs the same lock.

**Diagnostics.** Add timeouts around awaited operations. Dump pending promises/tasks where your runtime supports it. In Go, inspect goroutine dumps. In Rust, use tracing spans around async channels and locks.

**Fix pattern.** Avoid awaiting UI messages from inside a handler that owns the UI loop. Use one-way messages and timeout/cancellation.

```go
select {
case msg := <-resultCh:
    return model.WithResult(msg), nil
case <-time.After(10 * time.Second):
    return model.WithError("operation timed out"), nil
}
```

**Prevention.** Keep update/reducer functions nonblocking. Never hold locks while sending UI messages or invoking render callbacks.

## Infinite render loop

**Symptom.** CPU spikes, fans spin, terminal may appear blank or flicker, and input is delayed. The process is alive but not making progress.

**Root cause.** Rendering mutates state, state mutation schedules render, and render mutates state again. Timers may schedule new ticks without coalescing.

**Diagnostics.** Count frames per second and state updates. Log render reasons to a file. If render counts climb without input or data changes, find state writes during view/layout/render.

**Fix pattern.** Make render pure and coalesce redraws.

```ts
let renderScheduled = false;
function scheduleRender() {
  if (renderScheduled) return;
  renderScheduled = true;
  setImmediate(() => {
    renderScheduled = false;
    draw(view(model));
  });
}
```

**Prevention.** Separate model, update, and view. Use immutable view input or lint rules/tests that forbid state mutation during render.

## Missing first render

**Symptom.** The terminal switches to a blank alternate screen and seems frozen until an async operation completes, or forever if that operation hangs.

**Root cause.** The app enters raw mode and alternate screen, then starts a status check or awaits input before writing and flushing an initial frame.

**Diagnostics.** Capture raw output. If you see `CSI ? 1049 h` and maybe cursor-hide sequences but no clear/draw/frame bytes afterward, first render is missing. Add file logs around `enter`, `render`, and `flush`.

**Fix pattern.** Render a loading frame synchronously immediately after terminal setup.

```js
enterAlternateScreen();
enableRawMode();
process.stdin.resume();
render({screen: 'startup', message: 'Loading...'});
process.stdout.write(''); // ensure writes queued
await new Promise(resolve => process.stdout.write('', resolve));
startAsyncChecks();
```

**Prevention.** Add a PTY test that asserts visible content appears within a short timeout after startup.

## Alternate screen without cleanup

**Symptom.** After the app exits, the shell scrollback is gone or the terminal remains blank until `reset` or a new tab.

**Root cause.** The app sent `CSI ? 1049 h` but did not send `CSI ? 1049 l` on every exit path.

**Diagnostics.** Capture output and look for enter without matching leave. Reproduce by forcing an exception immediately after terminal entry.

**Fix pattern.** Put alternate-screen leave in the same idempotent cleanup guard as raw-mode restore.

```rust
struct TerminalGuard;
impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = crossterm::terminal::disable_raw_mode();
        let _ = crossterm::execute!(std::io::stdout(), crossterm::terminal::LeaveAlternateScreen, crossterm::cursor::Show);
    }
}
```

**Prevention.** Test panic/exception paths. Never scatter enter/leave calls across unrelated modules.

## Mouse mode stuck on

**Symptom.** Mouse clicks insert escape sequences, select text poorly, or are swallowed by the terminal after the app exits.

**Root cause.** Mouse reporting was enabled (`?1000`, `?1002`, `?1003`, `?1006`) and not disabled.

**Diagnostics.** Click in the shell and look for sequences like `\x1b[<...M`. Inspect cleanup for all enabled mouse modes.

**Fix pattern.** Disable every mouse mode you enable.

```sh
printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l'
```

**Prevention.** Centralize terminal feature toggles and store which modes were enabled.

## Bracketed paste not restored

**Symptom.** Pasted text appears wrapped in odd markers such as `^[[200~` and `^[[201~`.

**Root cause.** Bracketed paste was enabled with `CSI ? 2004 h` and not disabled.

**Diagnostics.** Paste into the shell after app exit. Look for paste markers. Capture final output for missing `CSI ? 2004 l`.

**Fix pattern.** Always send `\x1b[?2004l` during cleanup.

**Prevention.** Enable bracketed paste only when an input widget benefits from it, and test exit cleanup.

## Focus event mode stuck

**Symptom.** Switching terminal tabs or focus sends visible escape sequences or triggers unexpected input.

**Root cause.** Focus reporting (`CSI ? 1004 h`) remains enabled.

**Diagnostics.** Focus/unfocus the terminal after exit and watch for `CSI I` / `CSI O` behavior.

**Fix pattern.** Send `\x1b[?1004l` on cleanup.

**Prevention.** Treat focus reporting as optional progressive enhancement, not default startup behavior.

## Waiting for input that never comes

**Symptom.** The UI says "press any key" or waits after startup, but input does nothing. Sometimes Enter works while arrow keys do not, or arrow keys work while line input does not.

**Root cause.** Code switched stdin to raw mode but waits for cooked line input, or left cooked mode while expecting raw key bytes. Framework input managers can also conflict with direct stdin readers.

**Diagnostics.** Inspect whether `readline`, curses, prompt_toolkit, Ink, Blessed, Bubble Tea, or another framework already owns input. Log raw byte events to a file.

**Fix pattern.** Pick one input abstraction. For raw mode, parse bytes/events. For line mode, do not enable raw mode.

**Prevention.** Document ownership of stdin and prohibit direct stdin access outside the input module.

## TTY detection failure

**Symptom.** The TUI hangs in CI or when input/output is piped, or refuses to run inside an environment that actually has a usable TTY.

**Root cause.** Code assumes `stdin`/`stdout` are TTYs when they are not, or uses the wrong stream for capability checks.

**Diagnostics.** Print or log `stdin.isTTY`, `stdout.isTTY`, `TERM`, `CI`, and `NO_COLOR`. Test `cmd | app`, `app > file`, and `app < file`.

**Fix pattern.** Gate TUI mode and provide plain output.

```js
const interactive = process.stdin.isTTY && process.stdout.isTTY && process.env.TERM !== 'dumb';
if (!interactive) return runPlainMode();
return runTuiMode();
```

**Prevention.** CI tests should cover non-TTY stdin and stdout separately.

## Node.js-specific failures

**Symptom.** `npm run tui` blanks the terminal, never handles keys, exits too soon, or leaves raw mode stuck.

**Root cause.** Common causes include `setRawMode(true)` without exit cleanup, `stdin.pause()` before raw mode without `resume()`, `readline` competing with raw listeners, or `stdin.unref()` allowing premature process exit.

**Diagnostics.** Search for `setRawMode`, `pause`, `resume`, `ref`, `unref`, `readline.createInterface`, `process.exit`, `SIGINT`, `uncaughtException`, and `unhandledRejection`. Add file logs rather than `console.log`.

**Fix pattern.** One owner for stdin, cleanup before raw mode, resume stdin, render before async checks, and avoid `process.exit` until cleanup has run.

```js
async function main() {
  const session = createTerminalSession();
  try {
    session.enter();       // installs cleanup, raw, alt, stdin.resume()
    session.renderLoading();
    await session.flush();
    await startApp();
  } finally {
    session.leave();
  }
}
```

**Prevention.** Add a node-pty startup test that expects a nonblank frame and accepts `q` within one second.

## Python-specific failures

**Symptom.** curses apps leave the terminal broken after exceptions, fail to repaint, or Textual apps hang when mixed with custom asyncio loops.

**Root cause.** `curses.initscr()` without `curses.endwin()` in exception paths, `curses.raw()` without `curses.noraw()`, bypassing `curses.wrapper`, blocking work in the event loop, or not using Textual's run API correctly.

**Diagnostics.** Search for direct `initscr`, `raw`, `cbreak`, `noecho`, and custom event-loop code. Force an exception after initialization.

**Fix pattern.** Use safe wrappers and workers.

```python
import curses

def app(stdscr):
    curses.curs_set(0)
    stdscr.addstr(0, 0, "Loading...")
    stdscr.refresh()
    # start nonblocking work or poll with timeout

curses.wrapper(app)
```

**Prevention.** Keep blocking work out of Textual message handlers; use workers and `call_from_thread`/message posting as appropriate.

## Rust-specific failures

**Symptom.** Ratatui/Crossterm app leaves raw mode or alternate screen on panic, or nothing draws after terminal setup.

**Root cause.** Terminal guard is dropped too early, panic occurs before cleanup, stdout is not flushed, or backend/session ownership is split.

**Diagnostics.** Search for `enable_raw_mode`, `EnterAlternateScreen`, `LeaveAlternateScreen`, `disable_raw_mode`, `Drop`, and `panic::set_hook`. Force a panic after entry.

**Fix pattern.** Use RAII plus panic hook when needed.

```rust
let mut terminal = setup_terminal()?;
let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| run(&mut terminal)));
restore_terminal(&mut terminal)?;
if let Err(panic) = result { std::panic::resume_unwind(panic); }
```

**Prevention.** Integration-test cleanup after a controlled panic in a PTY.

## Go-specific failures

**Symptom.** Bubble Tea freezes during an external command or tcell apps do not restore the screen after panic.

**Root cause.** Blocking commands run in the update loop, `tea.ExecCommand` waits while the UI expects messages, goroutines deadlock on channels, or `screen.Fini()` is not deferred/recovered.

**Diagnostics.** Capture goroutine dumps. Inspect Bubble Tea commands and channel sends. Force panic after `screen.Init()`.

**Fix pattern.** Use commands/goroutines that return messages, and defer cleanup.

```go
screen, err := tcell.NewScreen()
if err != nil { return err }
if err := screen.Init(); err != nil { return err }
defer screen.Fini()
defer func() { if r := recover(); r != nil { screen.Fini(); panic(r) } }()
```

**Prevention.** Keep Bubble Tea `Update` fast and return commands for long work.

## SSH, tmux, and screen

**Symptom.** Works locally but hangs, misreads keys, ignores mouse, or fails to resize over SSH/tmux/screen/Zellij.

**Root cause.** Different `TERM`, terminfo, mouse support, focus support, truecolor behavior, alternate-screen policy, escape timing, or resize propagation.

**Diagnostics.** Log `$TERM`, `$TMUX`, `$STY`, `$ZELLIJ`, `$SSH_TTY`, `tput colors`, `stty size`, and resize events. Test outside the multiplexer and inside it.

**Fix pattern.** Feature-detect and gracefully degrade. Treat mouse/focus/truecolor as optional. Handle SIGWINCH/resize events.

**Prevention.** Include tmux and SSH scenarios in compatibility tests for any production TUI.

## Windows-specific failures

**Symptom.** ANSI sequences print literally, input differs, output appears delayed, or tests pass on Unix but hang under Windows Terminal/ConPTY.

**Root cause.** Virtual terminal processing is disabled in classic console hosts, ConPTY buffers output differently, Ctrl-C handling differs, or Unix PTY assumptions leak into Windows code.

**Diagnostics.** Identify host: Windows Terminal, VS Code terminal, classic conhost, Git Bash, WSL, or ConPTY test harness. Check whether the library enables VT mode. Test through the claimed support path.

**Fix pattern.** Use cross-platform libraries that enable Windows VT and abstract ConPTY where possible. Flush after frame writes and avoid relying on Unix-only signal/PTY behavior.

**Prevention.** Run Windows integration tests if Windows support is advertised, not just Unix PTY tests.
