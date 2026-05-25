# Borders, Icons, Glyphs, Prompts, and Dialogs

## Border families

Common border choices:

- ASCII: `+---+`, safest for logs, old terminals, and plain mode.
- Single-line: light, default for most panels.
- Rounded: friendly for modals and modern dashboards, but not universal.
- Double-line: strong heading or primary container; overuse feels heavy.
- Thick/block: high emphasis, selected states, or retro aesthetics.

Choose one default and one emphasis variant. Mixing many border styles makes a UI look inconsistent.

## Container patterns

- Full border: major region, focused panel, modal dialog.
- Left border: active navigation item, quote, nested detail.
- Bottom border/rule: section separation, table header.
- No border: dense lists, simple forms, inline prompts.
- Tab container: when peer views share the same space; keep active tab obvious without color alone.

Avoid nested full borders deeper than one level. Inside panels, use headings, blank lines, indentation, or separators instead.

## Padding and margin

A border with no padding feels cramped. One horizontal cell of padding is the default. Use vertical padding for forms, dialogs, and empty states; remove it for dense tables. Preserve at least one-cell gutters between adjacent panes.

## Shadow and depth illusions

Depth can be simulated with dark right/bottom cells, half blocks, or offset panels. Use only in controlled full-screen apps, and provide no-shadow fallback. Shadows consume cells and can reduce readability on light themes.

## Icons and glyphs

Use glyphs as redundant scan aids, not the only signal.

- Success: check mark plus `Success` or completed state text.
- Failure: cross or `Error` label with message.
- Warning: warning marker plus consequence.
- Loading: spinner plus action text.
- Navigation: chevrons/arrows plus indentation or labels.

Nerd Font/private-use icons are attractive for file browsers and git dashboards, but must be optional. Provide Unicode and ASCII icon sets, and never align critical tables around emoji without width tests.

## Prompt styling

Prompts should make the next action unmistakable:

- Keep the question short and direct.
- Display defaults inline, such as `[Y/n]` or `(default: main)`.
- Place help below or beside the prompt, not far away.
- Reserve accent color for the active input or selected option.
- Show validation directly under the field that failed.
- Preserve typed input exactly; do not surprise users with decorative transformations.

## Menus and selectors

- Keep selected item position stable when possible.
- Use a prefix marker, inverse style, or border to show focus in no-color mode.
- For long menus, show count, filter text, and scroll position.
- Grid selectors work for short homogeneous options; lists are better for descriptions.

## Forms and dialogs

- Align labels in one column; keep inputs in another.
- Put field-level errors next to or below the field.
- Put form-level errors near the submit action or top status region.
- Confirm destructive actions with explicit labels and safe defaults.
- Modal dialogs should trap focus, list keyboard exits, and restore previous focus on close.

## Toasts and notifications

Toasts are appropriate for transient non-critical feedback. Critical errors, failed saves, and security warnings need persistent placement. In full-screen apps, maintain a notification log or status panel so messages are not lost during redraws.
