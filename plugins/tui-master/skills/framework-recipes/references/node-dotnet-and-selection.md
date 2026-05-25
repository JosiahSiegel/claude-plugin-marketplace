# Node, TypeScript, .NET, and Selection Gotchas

## Node and TypeScript

### Ink component, resize, and testing pattern

Ink brings React component architecture to terminals. It is a strong fit when teams already use React patterns and want component tests. Avoid expensive render-side effects and test with fixed terminal dimensions.

```tsx
import React, {useEffect, useState} from 'react';
import {Box, Text, useApp, useInput, useStdout} from 'ink';

type Props = {load: () => Promise<string[]>};

export function App({load}: Props) {
  const {exit} = useApp();
  const {stdout} = useStdout();
  const [items, setItems] = useState<string[]>([]);
  const [size, setSize] = useState({columns: stdout.columns ?? 80, rows: stdout.rows ?? 24});

  useInput((input, key) => {
    if (input === 'q' || key.ctrl && input === 'c') exit();
  });

  useEffect(() => {
    let alive = true;
    load().then(value => { if (alive) setItems(value); });
    return () => { alive = false; };
  }, [load]);

  useEffect(() => {
    const onResize = () => setSize({columns: stdout.columns ?? 80, rows: stdout.rows ?? 24});
    stdout.on?.('resize', onResize);
    return () => stdout.off?.('resize', onResize);
  }, [stdout]);

  if (size.columns < 40) return <Text>Terminal too narrow. Press q to quit.</Text>;
  return <Box flexDirection="column"><Text bold>Items</Text>{items.map(i => <Text key={i}>- {i}</Text>)}</Box>;
}
```

Test shape:

```tsx
import {render} from 'ink-testing-library';
import {App} from './app.js';

test('renders loaded items', async () => {
  const {lastFrame, stdin} = render(<App load={async () => ['alpha']} />);
  await new Promise(resolve => setTimeout(resolve, 0));
  expect(lastFrame()).toContain('alpha');
  stdin.write('q');
});
```

Guidelines:

- Use fixed stdout dimensions in tests when layout matters.
- Mock async loaders, timers, and clocks.
- Avoid writing directly to stdout/stderr from components; let Ink own rendering.
- Prefer prompt libraries for short questionnaires; use Ink when stateful screens and React composition pay for themselves.

### Blessed and prompt libraries

Blessed provides a screen and widget tree with manual lifecycle control. It can be effective for dashboards and forms, but verify maintenance, terminal compatibility, mouse behavior, resize handling, and Windows behavior. Always call screen cleanup on `q`, Ctrl-C, exceptions, and rejected async work.

Prompt libraries are the right choice for short forms and setup wizards. Do not build a full-screen app when a sequence of accessible prompts is enough. Ensure prompts accept non-interactive equivalents through flags, config, stdin, or environment variables.

## .NET

Terminal.Gui is appropriate for full-screen keyboard-first applications with views, dialogs, layout, and mouse support. Keep view model logic testable outside terminal rendering and wrap `Application.Init()` / `Application.Shutdown()` in `try/finally` or equivalent host lifetime management.

Spectre.Console is appropriate for polished CLI output: prompts, tables, trees, progress, status, markup, and command apps. It is often the accessibility and automation friendlier choice. Use `AnsiConsole.Profile.Width` or test consoles with fixed width for snapshots.

## Framework maintenance checks

Before selecting or upgrading any TUI framework, record:

| Check | What to verify |
|--|--|
| Release health | Recent releases, issue response, supported language/runtime versions. |
| Terminal cleanup | Raw mode, alternate screen, cursor, mouse, paste, focus, keyboard modes restored after errors. |
| Resize | First render dimensions, live resize events, tiny terminal behavior, wrapping correctness. |
| Unicode | Grapheme clusters, double-width cells, emoji, combining marks, ambiguous width policy. |
| Input | Ctrl-C/Esc/q, paste, Alt/Esc ambiguity, mouse wheel, focus, configurable keybindings. |
| Windows | Native console, Windows Terminal, ConPTY, code page/UTF-8, CI feasibility. |
| Testing | Snapshot utilities, fake terminal, PTY examples, deterministic clocks/timers. |
| Non-TTY | Plain output, prompt fallback, JSON mode, no-color behavior. |
| Packaging | Binary size, native dependencies, terminfo files, license, supply-chain posture. |

Build a one-screen spike that exercises resize, CJK/emoji text, paste, Ctrl-C cleanup, non-TTY output, and Windows/Unix smoke tests before committing to a less-proven framework.

## Framework selection gotchas

- A framework with beautiful screenshots may still lack robust input parsing or testing support.
- A low-level library gives control but also makes you responsible for Unicode, focus, layout, and cleanup.
- Framework maintenance, Windows support, and resize behavior matter more than demo appeal.
- Always validate the exact framework version against the target OS and terminal matrix.
- Avoid mixing ownership layers: do not let a direct ANSI progress bar write while a full-screen framework owns the terminal.
