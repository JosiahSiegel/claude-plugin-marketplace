# TUI Widget Pattern Reference

## MVU event/message taxonomy

A useful message set separates user input, system events, and effect replies:

```text
InputMsg:
  Key(key, modifiers)
  Mouse(kind, row, col, button)
  Paste(text)
SystemMsg:
  Resize(width, height)
  Tick(now)
  FocusIn | FocusOut
DomainMsg:
  SearchChanged(text)
  RowActivated(id)
  FormSubmitted(values)
EffectMsg:
  LoadStarted(request_id)
  LoadSucceeded(request_id, data)
  LoadFailed(request_id, error)
  CommandProgress(request_id, percent, line)
```

Async command pattern:

```text
update(model, SearchChanged(q)):
  model.query = q
  model.loading = true
  request_id = new_id()
  model.active_search = request_id
  return model, debounce(150ms, Search(request_id, q))

update(model, LoadSucceeded(id, data)):
  if id != model.active_search: return model, none  # stale result
  model.loading = false
  model.rows = data
  model.table.selected = clamp(model.table.selected, data.len)
  return model, none
```

Effects should report messages. They should not mutate widget state directly and should not write to the terminal.

## Text input and text area

State shape:

```text
TextInputState:
  value: grapheme buffer
  cursor_grapheme: int
  selection: optional range
  horizontal_offset_cells: int
  placeholder: text
  validation: ok | warning | error(message)
  is_secret: bool
  composing: optional IME/preedit text if supported
```

- Cursor movement, deletion, selection, and word navigation must respect grapheme clusters and cell widths.
- Support paste as literal text, length limits, validation, masking for secrets, and clear error messages.
- Multiline text areas need scroll offset, line wrapping, Home/End semantics, and visible cursor positioning.

## Tables

State shape:

```text
TableState:
  rows: [RowId]
  selected: int
  scroll_y: int
  scroll_x: int
  sort: [{column, direction}]
  filter: text
  columns: [{id, min, preferred, max, priority, align, truncate}]
  loading: bool
  error: optional text
```

Patterns:

- Selection and scroll are UI state; row data belongs to the domain model or cache.
- Column sizing should be deterministic: reserve fixed columns, distribute remaining width, hide low-priority columns below thresholds.
- Render only visible rows plus optional overscan.
- Include no-color indicators for selection (`>`), sort (`sort: name asc`), and errors (`ERROR:` text).
- Preserve selected row by stable ID across refreshes when possible.

## Trees

State shape:

```text
TreeState:
  root_ids: [NodeId]
  expanded: Set<NodeId>
  selected: NodeId
  visible_flattened: [NodeId]  # derived/cache
  scroll_y: int
  filter: optional text
```

Patterns:

- Flatten the visible tree after expansion/filter changes; render the flattened slice.
- Keep expansion by stable node ID, not row index.
- ASCII fallback: `+`, `-`, `|`, `` `-- `` instead of box drawing.
- Search should reveal path context or provide a separate results mode.

## Command palettes

State shape:

```text
CommandPaletteState:
  open: bool
  query: text
  selected: int
  results: [{id, title, aliases, description, disabled_reason, dangerous}]
  mode: commands | files | symbols
```

Patterns:

- Search titles, aliases, descriptions, and keybindings.
- Disabled commands remain visible with a reason when discoverability matters.
- Destructive commands require confirmation outside the palette.
- Keep palette actions keyboard-first: Up/Down, Ctrl-N/Ctrl-P, Enter, Esc, Ctrl-U clear.
- Do not hide commands only because the mouse is unavailable.

## Forms

State shape:

```text
FormState:
  fields: [{id, label, value, touched, dirty, validation, help, secret}]
  focus_index: int
  submit_state: idle | submitting | failed(message) | succeeded
  original_values: map
```

Patterns:

- Validate on blur and submit; show field-local messages as soon as useful.
- Keep labels stable and inputs aligned.
- Mask secrets but support explicit reveal/copy rules where appropriate.
- Preserve dirty/touched state so async validation does not erase user edits.
- Provide `--config`, flags, stdin, or environment alternatives for automation.

## Lists, tables, and trees

- Keep selection, scroll offset, filter, sort, and expanded nodes in state.
- Virtualize large data sets and render only visible rows.
- Provide keyboard navigation: arrows, PageUp/PageDown, Home/End, search/filter, and activation.
- Tables need stable column sizing, truncation rules, horizontal scrolling or responsive column hiding, and no-color indicators for sort/selection.
- Trees need expand/collapse keys, depth indentation, and ASCII fallback for branch glyphs.

## Charts, progress, and spinners

- Charts in terminals are approximate; include textual values and units.
- Braille, block, and sparkline charts need ASCII fallback.
- Progress bars need percentage, counts, rate, ETA when meaningful, and a log-friendly non-animated mode.
- Spinners must be suppressible for reduced motion, CI, and logs.

## Dialogs, modals, and notifications

- Modal dialogs should trap focus, expose clear accept/cancel keys, and restore prior focus on close.
- Destructive dialogs should name the object and action, not rely on red text.
- Toasts/notifications should not hide persistent errors; provide a stable status area or log panel.

## Tabs, split panes, and viewports

- Tabs need keyboard switching and visible active state without color dependency.
- Split panes need minimum sizes and predictable collapse behavior on narrow terminals.
- Viewports need scroll offset, total size, visible range, and clear behavior after resize.
- Scrollbars are indicators, not the only navigation mechanism.

## Menus, command palettes, and file pickers

- Menus should support arrows, mnemonics where appropriate, search/filter for long lists, and Esc/cancel behavior.
- Command palettes should search labels, aliases, and descriptions; show disabled reasons; and keep destructive commands confirmable.
- File pickers need permission error handling, symlink clarity, hidden file toggles, and path input fallback.

## Anti-patterns

- Hidden actions only available by mouse.
- Meaning encoded only through color or icons.
- Overusing modal popups for routine status.
- Rendering every row of a huge table.
- Widgets that own global terminal state independently.
- Forms that report validation only after final submit when inline feedback is possible.
