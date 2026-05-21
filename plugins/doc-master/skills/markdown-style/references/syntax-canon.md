# Markdown syntax canon

The "what is valid" layer. Distilled from the Markdown Guide basic-syntax reference (https://www.markdownguide.org/basic-syntax/, CC BY-SA 4.0). For the "what is good" layer, see `style-overlay.md`.

A finding in this file is a **must-fix** — the construct is either invalid or so inconsistently rendered across processors that it counts as a bug. The skill cites the rule by its short name (e.g., `syntax/headings/atx-space-after`) so the architect can locate it here.

## Headings

### `syntax/headings/atx`

ATX style uses 1–6 `#` characters at the start of a line.

```markdown
# H1
## H2
### H3
###### H6
```

The number of `#` characters equals the heading level.

### `syntax/headings/atx-space-after`

A space must follow the `#`. `#Heading` is not a heading on most processors. `# Heading` is.

### `syntax/headings/blank-lines-around`

Put a blank line before and after every heading. Some processors recover from missing blank lines; others render the heading inline. Always include them.

### `syntax/headings/setext`

Setext style underlines text:

```markdown
Heading level 1
===============

Heading level 2
---------------
```

`===` becomes H1; `---` becomes H2. Setext only supports levels 1–2 — it cannot express H3 and below. Valid, but the style overlay prefers ATX.

## Paragraphs

### `syntax/paragraphs/blank-line-separator`

Paragraphs are separated by a blank line. Two consecutive non-blank lines are part of the same paragraph.

### `syntax/paragraphs/no-indent`

Do not indent paragraphs with tabs or spaces. Indentation has block-level meaning (code, list continuation) and triggers "unexpected formatting problems."

## Line breaks

### `syntax/line-breaks/two-trailing-spaces`

End a line with two or more trailing spaces, then return, to produce a `<br>`. This is the original Markdown syntax and is widely supported but is "controversial" because trailing whitespace is invisible.

### `syntax/line-breaks/br-tag`

The `<br>` HTML tag is universally supported and more visible than trailing whitespace.

### `syntax/line-breaks/backslash`

A trailing `\` at line end works in CommonMark but is not universally supported. Prefer paragraph breaks where possible.

## Emphasis

### `syntax/emphasis/bold`

`**bold**` or `__bold__` becomes `<strong>bold</strong>`.

### `syntax/emphasis/italic`

`*italic*` or `_italic_` becomes `<em>italic</em>`.

### `syntax/emphasis/bold-italic`

`***both***` (or `***both***`, `**_both_**`, `*__both__*`) becomes bold and italic.

### `syntax/emphasis/mid-word-asterisks`

For emphasis in the middle of a word (e.g., `Love**is**bold`), use asterisks only. Underscores are not handled consistently mid-word across processors.

## Blockquotes

### `syntax/blockquote/prefix`

Prefix the line with `>`:

```markdown
> A blockquote.
```

### `syntax/blockquote/multi-paragraph`

For multi-paragraph quotes, put `>` on the blank line between paragraphs:

```markdown
> First paragraph.
>
> Second paragraph.
```

### `syntax/blockquote/nesting`

Nest with `>>`:

```markdown
> Outer.
>
>> Inner.
```

### `syntax/blockquote/contents`

Blockquotes can contain headings, lists, and emphasis. Put blank lines before and after the blockquote.

## Lists

### `syntax/lists/ordered-period`

Ordered list items use a number followed by a period:

```markdown
1. First
2. Second
3. Third
```

`1)` is not portable. Use `.`.

### `syntax/lists/ordered-start-at-1`

The first item must be `1.` The remaining items can repeat `1.` (lazy numbering) or count up (`2.`, `3.`, ...). The starting number determines the rendered start.

### `syntax/lists/unordered-marker`

Use `-`, `*`, or `+`. Pick one per list. Mixing markers within a single list is invalid.

### `syntax/lists/nested-indent-4`

To attach a paragraph, blockquote, image, or nested list to an item, indent the continuation 4 spaces (one tab):

```markdown
- Item
  - This nested item is two spaces; some processors accept it but it is not portable.
- Item
    - This nested item is 4 spaces; portable.
```

### `syntax/lists/nested-code-indent-8`

To attach a code block to a list item, indent the code 8 spaces (two tabs).

### `syntax/lists/escape-leading-number`

To start an unordered item with `<number>.`, escape the period: `- 1968\. A great year!` Otherwise some processors treat the line as an ordered-list item.

## Code

### `syntax/code/inline-backticks`

Inline code uses single backticks: `` `nano` ``.

### `syntax/code/inline-double-backticks`

If the inline code contains a backtick, wrap it in double backticks: ``` `` `use `code` here` `` ```.

### `syntax/code/indented-block`

A code block can be indicated by indenting every line at least 4 spaces (one tab). This is the original Markdown syntax — valid, but the style overlay strongly prefers fenced blocks.

### `syntax/code/fenced-block`

Fenced blocks use three backticks (or three tildes) on their own line, optionally followed by a language tag:

````markdown
```python
def foo():
    pass
```
````

Fenced blocks are an extended-syntax feature — supported by every modern processor and the style overlay's recommended default.

## Horizontal rules

### `syntax/horizontal-rule`

Three or more `---`, `***`, or `___` alone on a line:

```markdown
---
```

Put blank lines before and after. Otherwise `---` directly after a non-blank line is parsed as a setext H2 underline.

## Links

### `syntax/links/inline`

`[link text](https://example.com)`.

### `syntax/links/inline-title`

`[link text](https://example.com "tooltip title")`. The title shows on hover.

### `syntax/links/autolinks`

`<https://example.com>` or `<user@example.com>`. The angle brackets are required for autolinks.

### `syntax/links/emphasis-and-code`

Links can be emphasized: `**[EFF](https://eff.org)**`. They can wrap inline code: `` [`code`](#anchor) ``.

### `syntax/links/reference-style`

Define the link target elsewhere in the document:

```markdown
This is a [hobbit-hole][1].

[1]: https://en.wikipedia.org/wiki/Hobbit "Hobbit hole"
```

The reference label is case-insensitive. The definition can use any of `[label]: url`, `[label]: url "title"`, `[label]: <url> "title"`.

### `syntax/links/url-encoding`

URLs with spaces or parentheses break inline link syntax. URL-encode: space -> `%20`, `(` -> `%28`, `)` -> `%29`. If that is impractical, fall back to a raw `<a href="…">` HTML tag.

## Images

### `syntax/images/inline`

`![alt text](path/to/image.jpg)` — alt text is required. Optional title: `![alt](path "title")`.

### `syntax/images/linked`

Wrap the image markdown in a link to make the image itself clickable:

```markdown
[![alt](image.jpg "title")](https://example.com)
```

## Escaping

### `syntax/escape`

Prefix the following with `\` to render them literally rather than as Markdown:

```text
\  `  *  _  {  }  [  ]  <  >  (  )  #  +  -  .  !  |
```

Example: `\*not italic\*` renders as `*not italic*`.

## Inline HTML

### `syntax/html/inline-allowed`

You can embed HTML in Markdown: `<em>word</em>`, `<sub>subscript</sub>`, etc. Useful when Markdown cannot express the construct (e.g., colspan in a table).

### `syntax/html/block-level-blank-lines`

Block-level HTML (`<div>`, `<table>`, `<pre>`, `<p>`) must be separated from surrounding Markdown by blank lines.

### `syntax/html/block-level-no-indent`

Block-level HTML tags must not be indented. Indented HTML is parsed as a code block.

### `syntax/html/markdown-inside-block-html`

Markdown syntax does **not** work inside block-level HTML. The contents of a `<div>` are rendered as HTML, not Markdown.

## Known compatibility footguns

The Markdown Guide lists these as "processors don't agree":

- Underscores mid-word for emphasis — use asterisks.
- Mixed list delimiters within one list — pick one and stick with it.
- Missing space after `#` in a heading — always include the space.
- `)` as an ordered-list delimiter — use `.`.
- Missing blank lines around block elements — always include them.

The skill flags violations of these as syntax findings even when the processor in use happens to handle them, because the source is then non-portable.
