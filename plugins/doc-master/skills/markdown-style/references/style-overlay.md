# Markdown style overlay

The "what is good" layer. Distilled from Google's developer documentation Markdown style guide (https://google.github.io/styleguide/docguide/style.html, Apache 2.0). For the "what is valid" layer, see `syntax-canon.md`.

Findings in this file are **should-fix**, not must-fix. The architect can decline any finding without justification — these rules are opinionated. Where the project has a local convention that conflicts with a rule here, defer to the project.

The skill cites style findings by short name (e.g., `style/headings/atx-only`) so the architect can locate them here.

## Authoring philosophy

### `style/philosophy/minimum-viable`

"Minimum viable documentation" — a small, fresh, accurate set of docs beats a sprawling stale one. Delete cruft frequently. This dovetails with `doc-diagnostic`'s anti-padding rule.

### `style/philosophy/better-than-best`

Reviewers should LGTM quickly when the change is reasonable, suggest concrete alternatives instead of blocking, and only block when the change makes the docs worse. Authors should not bikeshed.

## Headings

### `style/headings/atx-only`

Use ATX style (`#`, `##`, ...). Do not use setext (`===` / `---` underlines). Setext is "annoying to maintain" and cannot express H3 or below.

### `style/headings/single-h1`

Exactly one H1 per document, used as the title. Subsequent headings start at H2. The H1 should match (or nearly match) the filename — both are read as the document's identifier.

### `style/headings/unique-names`

Avoid bare repeated subheadings like "Summary" or "Example" under multiple parents. Prefix with the parent topic — "Foo summary", "Bar summary" — so the auto-generated anchor is intuitive.

### `style/headings/sentence-case-and-product-names`

Follow the project's title-case convention (the original Google guide refers out to a broader prose style guide for this). Always preserve product / tool / binary name capitalization — write `Markdown`, not `markdown`; `GitHub`, not `github`.

### `style/headings/blank-lines-around`

Always put a blank line before and after the heading. This is technically a syntax rule too, but the style overlay enforces it strictly — some processors recover, but the source must be portable.

## Document skeleton

### `style/skeleton/recommended`

The recommended document skeleton:

```markdown
# Document Title

<optional one-line author or owner indication>

<1–3 sentence introduction, written for a newcomer who knows the system exists but not this doc.>

[TOC]

## Topic

…

## Another topic

…

## See also

- [Related doc](/path/to/related.md)
```

The skeleton is not mandatory, but every deviation should have a reason.

### `style/skeleton/title-matches-filename`

The H1 title should match (or nearly match) the filename. `request-routing.md` -> `# Request routing`, not `# How the Routing System Works`.

### `style/skeleton/intro-1-to-3-sentences`

The intro is 1–3 sentences and answers "what is this doc, who is it for, what will I get from it." Longer intros become unread preamble.

### `style/skeleton/see-also-section`

A final `## See also` section is the canonical location for links the reader might want next. Reference-style links inside `See also` keep it scannable.

## Table of contents

### `style/toc/use-when-long`

Use the `[TOC]` directive for any document that does not fit on one laptop screen. Short docs do not need a TOC — it adds noise.

### `style/toc/placement`

Place `[TOC]` between the introduction and the first `## H2`. Position matters for screen readers and keyboard navigation, since `[TOC]` injects the table of contents at that point in the DOM.

## Line length

### `style/line-length/80`

Wrap prose lines at 80 characters. Rationale: Code Search does not soft-wrap, and 80 mirrors the surrounding code conventions.

### `style/line-length/exceptions`

The 80-character rule does not apply to:

- Links (one URL per line is fine even if it overflows).
- Table rows (cell content cannot wrap; the line will be as long as the widest cell).
- Headings (a heading is one logical line).
- Code blocks (preserve the original code).

The prose **around** a long link still wraps — only the line with the link is allowed to overflow.

## Whitespace and line breaks

### `style/whitespace/no-trailing`

No trailing whitespace on any line. This overrides the syntax-valid two-trailing-spaces-for-`<br>` trick because trailing whitespace is invisible, removed by IDE cleanup, and rejected by presubmit checks. Use a paragraph break (blank line) instead.

### `style/line-breaks/sparingly`

Use a trailing `\` for hard breaks sparingly. Prefer paragraph breaks for separation; prefer block-level constructs (lists, blockquotes) for structure.

## Lists

### `style/lists/lazy-numbering-long`

For long or nested ordered lists, use lazy numbering — repeat `1.` on every item. Rationale: editing is easier (no renumbering after an insert), and rendered output is identical.

### `style/lists/full-numbering-short`

For short, stable, top-level ordered lists, fully numbered (`1.`, `2.`, `3.`) is fine and more readable in the raw source.

### `style/lists/indent-4`

Nested items and wrapped item text use 4-space indentation. Two spaces after the item number / three spaces after a bullet, so all content aligns at column 4. Wrapped text inside a nested item needs 8-space indent.

### `style/lists/single-space-only-for-trivial`

Single-space (`* Foo`) is acceptable only when the list is short, flat, and every item is single-line. For anything else, prefer the 2-spaces-after-number form so continuations align cleanly.

### `style/lists/prefer-list-to-table`

Prefer a list to a table when the data is one-dimensional. Tables are for two-dimensional data with parallel attributes.

## Code

### `style/code/fenced-only`

Always use fenced code blocks (` ``` `). Do not use 4-space-indented blocks. Rationale: indented blocks cannot specify a language, have ambiguous boundaries, and are harder to find in Code Search.

### `style/code/declare-language`

Always declare a language on the fence:

````markdown
```python
…
```
````

Use `text` (or `none`) when there is genuinely no language.

### `style/code/inline-backticks-for-escapes`

Use inline backticks for short code, field names, file types (` `README.md` `), and to escape strings that should not be auto-linked or parsed — fake paths, example URLs containing `$VAR`, placeholder identifiers.

### `style/code/escape-shell-newlines`

In shell snippets that wrap, escape the newline with `\` so users can copy-paste the whole command:

```bash
docker run --rm \
  --name example \
  -p 8080:8080 \
  example:latest
```

### `style/code/inside-lists`

Fenced code blocks inside lists must indent to align with the list item's text — 4 spaces from the bullet, 4 more spaces for any extra nesting level.

## Links

### `style/links/repo-absolute`

For links within the same repo, prefer explicit absolute paths: `[…](/path/to/page.md)`. Do not use the full `https://…` URL for in-repo links — it breaks when the repo moves.

### `style/links/avoid-relative-traversal`

`../` relative paths are fragile. Same-directory relative (`./neighbor.md`) is fine; anything that traverses up is not.

### `style/links/informative-text`

The link text must be informative. Never use "here", "link", "this", or the raw URL as the label. Write the sentence naturally, then wrap the most meaningful phrase.

- Bad: For more information, click [here](url).
- Good: See the [request-routing reference](url) for the full middleware order.

### `style/links/reference-style-when`

Use reference-style links when:

- The inline URL would hurt the readability of the surrounding sentence.
- The same destination is referenced multiple times — reference-style eliminates duplication.
- The link sits inside a table cell, because cells cannot wrap a long URL.

Do not use reference-style when the URL is short and inline would read just as cleanly.

### `style/links/reference-placement`

Reference link definitions go just before the next heading, at the end of the section where the link is first used. Treat them like footnotes scoped to a section.

Exception: a link used across multiple sections goes at the end of the document, so moving a section does not leave a dangling reference.

## Images

### `style/images/sparingly`

Use images sparingly. Prose tends to age better than screenshots.

### `style/images/when-justified`

Use an image when showing is genuinely easier than describing — UI navigation, architectural diagrams, chart output. Otherwise prefer prose.

### `style/images/alt-text-required`

Always include alt text. The alt text is the only content available to a non-sighted reader.

## Tables

### `style/tables/scannable-two-dimensional`

Use tables only for scannable, tabular data with two-dimensional structure and many parallel items with distinct attributes.

### `style/tables/avoid-when`

Avoid tables that exhibit:

- Poor distribution — many empty cells, or one column that does not vary.
- Unbalanced row-to-column ratio — too tall and narrow, or too wide and short.
- Rambling prose in cells — Markdown cannot wrap cell text across lines.

### `style/tables/short-cells`

Tables may exceed the 80-character line-length rule. Keep cells short. Use reference-style links inside cells to keep widths reasonable.

## HTML

### `style/html/avoid`

Strongly prefer Markdown to HTML. The one acknowledged exception is large tables that need features Markdown tables cannot express (colspan, rowspan, nested block content). Note that some renderers (the original guide cites Gitiles) do not render HTML at all.

## Capitalization

### `style/capitalization/preserve-names`

Preserve product / tool / binary capitalization in headings and prose alike: `Markdown`, `GitHub`, `Kubernetes`, `npm` (yes, lowercase), `iOS`, `kubectl`.

## Items the style overlay does not specify

The source guide is deliberately silent on:

- **Emphasis convention** — `**bold**` vs `__bold__`, `*italic*` vs `_italic_`. The syntax canon already covers compatibility; the style overlay does not pick a winner. Follow project convention.
- **File naming** — only that the H1 should match or nearly match the filename. No imposed `kebab-case` vs `snake_case` rule.
- **Hard document length thresholds** — only the qualitative "above the fold on a laptop" criterion for whether `[TOC]` is justified.

When the architect asks "what should I do about X" and X is on this list, the skill responds: "the style guide is silent — follow the project's existing convention, or pick one and apply it consistently."
