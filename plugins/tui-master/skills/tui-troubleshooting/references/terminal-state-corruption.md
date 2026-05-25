# Terminal State Corruption

Terminal state corruption is any failure where the process may still run, but the terminal display or interaction contract is damaged: garbled escape sequences, wrong colors, hidden cursor, incorrect cursor position, stuck scroll region, partial frames, mouse/paste/focus modes leaking, or debug output interleaving with the alternate screen.

## Baseline recovery sequence

For Unix-like terminals:

```sh
stty sane
reset
printf '\033[0m\033[?25h\033[r\033[?1049l\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?2004l\033[?1004l'
```

The sequence resets SGR attributes, shows the cursor, resets scroll region, leaves alternate screen, disables mouse reporting, disables bracketed paste, and disables focus reporting.

## Incomplete escape sequences from interrupted writes

**Symptom.** Literal fragments like `^[`, `[38;2`, `?1049h`, or color codes appear on screen. The cursor may jump unexpectedly after the next write.

**Root cause.** The process writes an escape sequence in pieces and is interrupted, crashes, or another writer interleaves bytes between the pieces. Terminals parse byte streams, not logical write calls.

**Diagnostics.** Capture raw output bytes with a PTY recorder or script-like tool. Look for partial CSI/OSC/DCS sequences or interleaving between sequence bytes.

**Fix pattern.** Compose complete frames and control sequences into a buffer and flush once.

```ts
const frame = [];
frame.push('\x1b[?25l');
frame.push(renderCells(cells));
frame.push('\x1b[?25h');
process.stdout.write(frame.join(''));
```

**Prevention.** Use a renderer/backend that batches writes. Avoid writing escape sequences from signal handlers or multiple modules.

## Interleaved output from multiple threads or tasks

**Symptom.** Status logs appear inside bordered panels, frames contain half of two different renders, or escape sequences print literally.

**Root cause.** Multiple threads, goroutines, async tasks, subprocesses, or logging frameworks write to stdout/stderr while the TUI owns the screen.

**Diagnostics.** Redirect logs to a file and see if the corruption disappears. Search for `console.log`, `print`, `println!`, `fmt.Println`, `log`, `stderr`, child process inherited stdio, and progress libraries.

**Fix pattern.** The UI renderer should be the only writer to the controlled terminal. Route diagnostics to a file or in-app log panel.

```js
const log = fs.createWriteStream(path.join(os.tmpdir(), 'app-tui.log'), {flags: 'a'});
function debug(message) { log.write(`${new Date().toISOString()} ${message}\n`); }
```

**Prevention.** During TUI mode, configure logging sinks before entering alternate screen. Spawn child processes with `stdio: 'pipe'` or suspend/restore the TUI around interactive children.

## Scroll region not reset

**Symptom.** Shell output after exit scrolls only within part of the terminal, or the prompt appears trapped in a pane-like region.

**Root cause.** The app used DECSTBM (`CSI top ; bottom r`) to set a scroll region and did not reset it with `CSI r`.

**Diagnostics.** Inspect raw output for `r` scroll-region sequences. After exit, run commands with many lines and see whether only a subsection scrolls.

**Fix pattern.** Include `\x1b[r` in cleanup and before full-screen layout changes that assume the whole screen.

**Prevention.** Prefer framework viewport widgets that own scroll regions and reset them. Add cleanup assertions in virtual terminal tests.

## Cursor position not restored

**Symptom.** The prompt appears in the middle of the screen, later output overwrites UI remnants, or cursor is hidden after exit.

**Root cause.** Cursor hide/show, save/restore, alternate-screen, or manual cursor movement sequences are unbalanced.

**Diagnostics.** Look for `?25l` without `?25h`, save without restore, or crash paths after cursor hide.

**Fix pattern.** Cleanup must always show the cursor and place it at a safe position, usually after leaving alternate screen.

```sh
printf '\033[?25h\033[0m\n'
```

**Prevention.** Hide cursor only during drawing, or manage it via a terminal session guard.

## Color attributes not reset

**Symptom.** The shell prompt or later command output remains red, dim, bold, inverse, underlined, or has a background color.

**Root cause.** The app set SGR attributes and did not send `SGR 0` (`CSI 0 m`) on frame boundaries and cleanup.

**Diagnostics.** Inspect final output bytes for missing `\x1b[0m`. Reproduce with a forced exception after rendering colored text.

**Fix pattern.** End every frame and cleanup path with reset.

```rust
queue!(stdout, crossterm::style::ResetColor, crossterm::style::SetAttribute(Attribute::Reset))?;
```

**Prevention.** Use style scopes or cell renderers that emit resets when attributes change and at frame end.

## Unicode width mismatch causing misalignment

**Symptom.** Borders break, columns drift, cursor lands inside characters, emoji overwrite neighboring cells, or CJK text shifts layout.

**Root cause.** Code measures bytes, code points, or grapheme count instead of display cell width. Terminals also differ on emoji and ambiguous East Asian width.

**Diagnostics.** Test strings with combining marks, emoji ZWJ sequences, CJK, and ambiguous-width characters. Compare expected cell grid to actual terminal output.

**Fix pattern.** Use maintained width/grapheme libraries and truncate by cell width, not string length.

```python
# Pseudocode: iterate grapheme clusters and accumulate wcwidth cells.
for cluster in graphemes(text):
    w = display_width(cluster)
    if cells + w > limit: break
    out.append(cluster)
```

**Prevention.** Snapshot with fixed Unicode policy. Provide ASCII mode for limited fonts and remote environments.

## Race conditions between resize and render

**Symptom.** Partial frames, panics from out-of-bounds coordinates, stale panels after resizing, or a blank screen until another keypress.

**Root cause.** Resize updates terminal dimensions while a render is using old dimensions, or SIGWINCH/resize events are handled outside the UI loop.

**Diagnostics.** Log terminal size at event receipt, layout calculation, and render flush. Stress-test rapid resizing in a PTY or manually.

**Fix pattern.** Treat resize as a normal UI event. Coalesce resize/render and recompute layout from current dimensions.

```go
case tea.WindowSizeMsg:
    m.width = msg.Width
    m.height = msg.Height
    return m, nil
```

**Prevention.** Do not cache absolute layout coordinates across frames unless they are invalidated by resize.

## Background process writing to the same terminal

**Symptom.** A compiler, test runner, shell command, or subprocess output appears through the UI and corrupts frames.

**Root cause.** Child process inherits stdout/stderr while the TUI remains active.

**Diagnostics.** Inspect process spawn options. Temporarily redirect child stdio and compare behavior.

**Fix pattern.** Pipe child output into the app model, or suspend the TUI before handing control to an interactive child.

```js
const child = spawn(cmd, args, {stdio: ['ignore', 'pipe', 'pipe']});
child.stdout.on('data', chunk => appendLog(chunk.toString()));
```

**Prevention.** Make child-process stdio policy explicit in the TUI architecture.

## Debug print statements corrupting alternate screen

**Symptom.** `console.log`/`print` debugging appears at random positions, breaks borders, or forces scrolling inside the alternate screen.

**Root cause.** Line-oriented debugging writes to the same terminal surface as the full-screen renderer.

**Diagnostics.** Grep for print/log statements and disable them. Confirm corruption disappears.

**Fix pattern.** Use file logging, structured in-app logs, or a debug overlay rendered by the UI.

**Prevention.** Provide a debug logger from day one and forbid direct stdout/stderr writes during TUI mode.

## Partial renders and flicker

**Symptom.** Users see frames being drawn top-to-bottom, flickering borders, or old text remains after shorter new text.

**Root cause.** The app writes fragments without clearing damaged cells, does not diff frames, forgets to pad shortened lines, or flushes many times per frame.

**Diagnostics.** Slow output with a PTY proxy or run over SSH. Capture frames and inspect whether stale cells are cleared.

**Fix pattern.** Render to an offscreen buffer, diff against the previous buffer, clear/pad changed regions, and flush once.

**Prevention.** Avoid ad hoc `move cursor + print` code for complex screens; use a cell-buffer renderer or mature framework.
