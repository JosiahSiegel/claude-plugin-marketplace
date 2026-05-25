# Rust, Python, and Go Framework Recipes

## Rust Ratatui + Crossterm

Use Ratatui when immediate-mode widgets, precise layout, and Rust performance are beneficial. Common architecture: application state, event source, update function, draw function, terminal guard. Keep rendering deterministic and snapshot buffers for tests. Crossterm is the usual backend choice for Windows/macOS/Linux coverage.

### Guard and event loop skeleton

```rust
use std::{io, time::{Duration, Instant}};
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};

struct TerminalGuard;
impl TerminalGuard {
    fn enter() -> io::Result<Self> {
        enable_raw_mode()?;
        execute!(io::stdout(), EnterAlternateScreen, crossterm::cursor::Hide)?;
        Ok(Self)
    }
}
impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = execute!(io::stdout(), crossterm::cursor::Show, LeaveAlternateScreen);
        let _ = disable_raw_mode();
    }
}

fn run(mut app: App) -> io::Result<()> {
    let _guard = TerminalGuard::enter()?;
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| ui(f, &app))?;
        let timeout = Duration::from_millis(100).saturating_sub(last_tick.elapsed());
        if event::poll(timeout)? {
            match event::read()? {
                Event::Key(k) if k.code == KeyCode::Char('q') => break,
                Event::Key(k) => app.update(Msg::Key(k)),
                Event::Resize(w, h) => app.update(Msg::Resize(w, h)),
                Event::Mouse(m) => app.update(Msg::Mouse(m)),
                Event::Paste(s) => app.update(Msg::Paste(s)),
                _ => {}
            }
        }
        if last_tick.elapsed() >= Duration::from_millis(100) {
            app.update(Msg::Tick);
            last_tick = Instant::now();
        }
    }
    Ok(())
}
```

Notes:

- Add `color_eyre`/panic hook cleanup if panics are expected during development.
- Keep `ui(frame, &app)` pure. Background threads send messages over channels; they do not draw.
- Snapshot custom widgets with fixed `Rect`, fixed theme, and stable data.
- Common pitfalls: failing to restore terminal modes after panic, drawing from background threads, over-redrawing on every tick, and measuring Unicode incorrectly in custom widgets.

## Python Textual, Rich, prompt_toolkit, curses

### Textual worker and test pattern

Textual is for widget-rich apps with reactive state, CSS-like styling, workers, and built-in testing affordances. Avoid blocking workers on the UI thread.

```python
from textual.app import App, ComposeResult
from textual.widgets import Button, Static
from textual.worker import Worker, get_current_worker

class FetchApp(App):
    def compose(self) -> ComposeResult:
        yield Button("Load", id="load")
        yield Static("Idle", id="status")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.run_worker(self.fetch_data(), name="fetch", exclusive=True)

    async def fetch_data(self) -> None:
        worker = get_current_worker()
        self.query_one("#status", Static).update("Loading...")
        result = await expensive_async_call()
        if not worker.is_cancelled:
            self.query_one("#status", Static).update(result)

async def test_load_updates_status():
    app = FetchApp()
    async with app.run_test(size=(80, 24)) as pilot:
        await pilot.click("#load")
        await pilot.pause()
        assert "Loading" in pilot.app.query_one("#status", Static).renderable
```

Test with fixed size and deterministic workers; mock network and clocks. Use `run_test`/Pilot for interactions and pure unit tests for non-UI state.

### Rich

Rich is best for rich scrollback output, tables, trees, markdown, tracebacks, progress, and logging. Prefer it over a full-screen TUI when output can remain command-oriented. Use `Console(record=True, width=80, color_system=None)` for stable tests and avoid live displays when piping to non-TTY output.

### prompt_toolkit shell/prompt pattern

Use prompt_toolkit for shells, REPLs, completers, history, multiline editing, and sophisticated keybindings.

```python
from prompt_toolkit import PromptSession
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.patch_stdout import patch_stdout

kb = KeyBindings()

@kb.add("c-c")
def _(event):
    event.app.exit(exception=KeyboardInterrupt)

session = PromptSession(
    completer=WordCompleter(["open", "close", "status", "quit"]),
    key_bindings=kb,
    enable_history_search=True,
)

async def repl():
    with patch_stdout():
        while True:
            try:
                line = await session.prompt_async("app> ")
            except (EOFError, KeyboardInterrupt):
                break
            if line.strip() in {"quit", "exit"}:
                break
            await dispatch_command(line)
```

Use `patch_stdout` when background tasks log while prompting. Provide non-interactive flags for automation and avoid full-screen mode for simple command entry.

### curses

Use curses when dependency footprint and classic terminal portability matter. Use cleanup wrappers, handle resize, and remember coordinate ordering is row,column (`y, x`). Keep domain state outside curses windows so it can be tested without a terminal.

## Go Bubble Tea, Lip Gloss, Bubbles, tview, tcell

### Bubble Tea Model/Update/View/Cmd skeleton

Bubble Tea is best for message-driven apps. Keep `Update` deterministic and move side effects into commands. Compose with Bubbles for controls and Lip Gloss for visual style.

```go
type model struct {
    width, height int
    loading bool
    items []string
    err error
}

type loadedMsg []string
type errMsg error

func initialModel() model { return model{loading: true} }

func fetchCmd() tea.Cmd {
    return func() tea.Msg {
        items, err := fetchItems()
        if err != nil { return errMsg(err) }
        return loadedMsg(items)
    }
}

func (m model) Init() tea.Cmd { return fetchCmd() }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.WindowSizeMsg:
        m.width, m.height = msg.Width, msg.Height
    case tea.KeyMsg:
        switch msg.String() {
        case "q", "ctrl+c": return m, tea.Quit
        case "r": m.loading = true; return m, fetchCmd()
        }
    case loadedMsg:
        m.loading = false; m.items = []string(msg)
    case errMsg:
        m.loading = false; m.err = msg
    }
    return m, nil
}

func (m model) View() string {
    if m.width < 40 || m.height < 10 { return "Terminal too small. Press q to quit.\n" }
    if m.loading { return "Loading...\n" }
    if m.err != nil { return "Error: " + m.err.Error() + "\n" }
    return renderList(m.items, m.width, m.height)
}
```

Use `tea.WithAltScreen()` for full-screen apps only. Consider `tea.WithMouseCellMotion()` or mouse modes only when required. Test `Update` directly and snapshot `View` with fixed width/height.

### tview and tcell

`tview` is best for quick widget-heavy apps such as forms, tables, trees, and pages. It inherits tcell portability. Keep data transformations outside widget callbacks and test resize/mouse/focus paths manually.

`tcell` is best when you need lower-level cell control without building on curses. Use its abstractions for Unicode width, mouse, paste, and truecolor where possible. Do not mix direct ANSI writes with tcell screen ownership.

### Urwid, asciimatics, termui, and gocui notes

- **Urwid**: mature Python widget toolkit with solid list/pile/columns patterns. Check Python version support, maintenance cadence, and Unicode behavior before choosing it for a new product. Strong for keyboard-first classic TUIs, less ideal for modern CSS-like styling.
- **asciimatics**: useful for terminal animation, forms, and visual effects. Be careful with CPU usage, frame rate, and accessibility; animations need reduced-motion and non-TTY fallbacks.
- **termui**: convenient Go dashboard widgets, but verify maintenance and resize behavior. Prefer Bubble Tea/tcell for apps requiring deep interaction and long-term support.
- **gocui**: small Go library for simple pane-based layouts. Validate maintenance, Unicode width, mouse, and Windows expectations; it can be enough for internal tools but may require custom widget work.

## Cross-ecosystem migration hints

- Elm-style state maps naturally between Bubble Tea and reducer-style Rust/Python designs.
- Widget-tree frameworks need lifecycle and focus management; immediate-mode frameworks need deterministic render functions.
- Rich output libraries are not substitutes for full-screen input frameworks, and full-screen frameworks are often overkill for reports.
- A framework with built-in tests and terminal cleanup is often more valuable than one with impressive screenshots.
