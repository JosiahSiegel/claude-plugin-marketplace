# Low-Level, C/C++, Zig, Swift, and Emerging Frameworks

## C and C++

### ncurses

Use ncurses when portability through terminfo, classic widgets, panels, forms, menus, windows, pads, and mature Unix deployment matter. It abstracts many terminal capabilities but requires careful mode setup, resize handling, color-pair management, and cleanup.

Safe wrapper shape:

```c
#include <locale.h>
#include <ncurses.h>
#include <stdbool.h>

static bool curses_started = false;

void tui_start(void) {
    setlocale(LC_ALL, "");
    initscr(); curses_started = true;
    cbreak(); noecho(); keypad(stdscr, TRUE);
    nodelay(stdscr, FALSE);
    curs_set(0);
    if (has_colors()) { start_color(); use_default_colors(); }
}

void tui_stop(void) {
    if (!curses_started) return;
    curs_set(1);
    nocbreak(); echo();
    endwin();
    curses_started = false;
}

int main(void) {
    int rc = 0;
    tui_start();
    /* install signal handlers that request shutdown, not unsafe drawing */
    while (1) {
        int ch = getch();
        if (ch == 'q') break;
        if (ch == KEY_RESIZE) { /* recompute layout from getmaxyx */ }
        erase(); mvaddstr(0, 0, "Press q to quit"); refresh();
    }
    tui_stop();
    return rc;
}
```

Common pitfalls: assuming coordinates are x,y rather than y,x, leaking raw/cbreak/noecho mode after crashes, treating bytes as characters, relying on a specific curses color-pair limit, and expecting modern truecolor or mouse behavior without validating the target curses build.

### notcurses

Use notcurses when modern terminal graphics, rich cells, visual effects, images/video where supported, and high-performance rendering are product goals. Provide degradation for terminals without the needed graphics protocols and test inside multiplexers. Treat advanced visuals as enhancements, not the only way to read state.

### FTXUI

Use FTXUI for composable C++ terminal components, layout, and event handling. Keep business state outside component rendering and test resize, Unicode, mouse, and alternate-screen cleanup in the exact deployment terminals. Verify Windows console behavior and packaging expectations for your compiler/runtime.

## Low-level framework cautions

Choosing a low-level cell or ANSI library means you own product behavior that high-level frameworks normally provide:

- Terminal mode guard with idempotent cleanup.
- Frame buffer, diffing, batching, and resize invalidation.
- Unicode grapheme and width measurement.
- Focus traversal, widget state, validation, and help text.
- Mouse, paste, Esc/Alt ambiguity, and keybinding configuration.
- Color fallback, `NO_COLOR`, `TERM=dumb`, non-TTY handling.
- PTY/virtual terminal tests and Windows ConPTY tests.
- Escape injection prevention for untrusted data.

Use direct ANSI only for tiny controlled surfaces such as a simple progress region, and still gate it behind TTY detection. For product TUIs, prefer a maintained library unless the UI itself is the differentiator.

## Zig

zig-vaxis is a modern Zig terminal UI toolkit focused on robust terminal handling. It is attractive for single-binary distribution and low-level control. Validate Unicode width behavior, Windows support expectations, and terminfo/protocol behavior before choosing it for broad consumer use. Build an early compatibility spike for paste, resize, terminal cleanup, and tmux/SSH behavior.

## Swift

SwiftTUI-style frameworks fit teams building Swift-native command-line tools. Confirm Linux/macOS support, terminal mode cleanup, package distribution, and CI testing strategy. For simple rich output, a lighter CLI output library may be more appropriate than a full-screen app.

## Emerging and niche toolkit checklist

Before adopting a less common toolkit, answer:

- Is it maintained and documented?
- Does it support raw mode cleanup, resize, mouse, paste, and Unicode width correctly?
- Does it have snapshot or PTY testing examples?
- Does it work on Windows, macOS, Linux, tmux, SSH, and your target terminals?
- Can it degrade to no-color, ASCII, non-TTY, and no-mouse modes?
- Are packaging and licensing acceptable?
- Does the maintainer recommend production use, or is it experimental?
- Can your team debug raw byte captures when something breaks?

If any answer is unknown, build a spike with resize, Unicode, paste, mouse, crash cleanup, and non-TTY tests before committing.
