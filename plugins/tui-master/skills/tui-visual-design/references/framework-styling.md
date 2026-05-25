# Framework-Specific Styling Recipes

Fetch current official docs when exact APIs matter. Use these as design defaults and review heuristics.

## Ratatui

- Centralize `Style` values by semantic role.
- Use `Layout` constraints for rhythm instead of fixed coordinates.
- Use `Block` borders selectively; avoid nesting bordered `Block`s.
- Style focused widgets through border, title, or prefix changes, not only color.
- Use `Gauge`, `BarChart`, `Sparkline`, `Table`, and `List` with textual labels.
- Snapshot widgets at multiple widths and color modes.

## Textual

- Treat CSS variables and classes as the design system.
- Use component classes for variants: compact, danger, focused, muted.
- Prefer built-in layout containers before custom positioning.
- Keep animations short and respect reduced-motion settings.
- Use compound widgets to package consistent label, input, help, and error presentation.

## Bubble Tea and Lip Gloss

- Keep a style module with semantic Lip Gloss styles.
- Compose margins, padding, borders, and widths deliberately; test calculated widths.
- Use Bubbles components for common controls, then wrap with consistent styling.
- Remember `View()` returns strings: ANSI width, wide glyphs, and newlines affect layout.
- Downsample colors with terminal-aware libraries when possible.

## Rich

- Define a `Theme` for semantic roles and reuse it across console, tables, panels, logs, and progress.
- Use `Table` for alignment, `Panel` for emphasis, `Rule` for separation, and `Progress` for tasks.
- Avoid panel nesting in scrollback output; it becomes visually heavy.
- Use `Console` color-system detection and plain output when not attached to a TTY.

## Ink

- Use Flexbox intentionally: rows for toolbars, columns for sidebars, fixed sizes for status bars.
- Centralize color/style tokens rather than scattering Chalk calls.
- Keep render functions pure and stable; animation should come from state/timers.
- Test resize and Unicode width behavior in component tests and PTY runs.

## Terminal.Gui

- Define color schemes for normal, focused, hotkey, disabled, error, and dialog states.
- Verify focus indicators for keyboard-only users.
- Use layout primitives rather than hard-coded absolute positions where possible.
- Keep mouse affordances secondary to keyboard behavior.

## Spectre.Console

- Use markup styles as semantic roles and keep them consistent across prompts, tables, trees, rules, panels, and progress.
- Prefer `Table`, `Tree`, `BarChart`, `BreakdownChart`, `Panel`, `Rule`, `Status`, and `Progress` before custom ANSI.
- Ensure prompts and confirmations expose defaults and safe choices in text.
- Honor no-color and redirected-output behavior.

## Cross-framework polish checklist

- One spacing scale.
- One border language plus one emphasis variant.
- Semantic color roles with dark, light, 16-color, and no-color mappings.
- Focus visible without color.
- Text measured by display cells.
- Snapshots for normal, narrow, tiny, and wide terminals.
- Animation disabled in tests and reduced-motion modes.
