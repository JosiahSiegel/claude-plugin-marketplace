---
name: markdown-style
description: |
  This skill should be used to review, lint, or fix Markdown formatting in READMEs, ADRs, runbooks, how-tos, design docs, or any `.md` file.
  PROACTIVELY activate on "review this markdown", "lint this doc", "lint this README", "style-check this doc", "fix the formatting", "review my README", "is this markdown valid?", "fix the headings", "fix the list indentation", "ATX vs setext", "should I use a TOC?", "markdown style guide", or "Markdown linter."
  Provides: two-pass syntax/style review with line-referenced findings.
---

# markdown-style

The Markdown authoring and review skill. Owns two layers of rules and the procedure for applying them:

1. **Syntax canon** — what valid Markdown looks like. Derived from the Markdown Guide basic-syntax reference. Full canon: `references/syntax-canon.md`.
2. **Style overlay** — opinionated rules a reviewer enforces on top of valid syntax. Derived from Google's Markdown style guide. Full overlay: `references/style-overlay.md`.

Load this skill when the question is **"is this doc well-formed?"** — not **"does this doc belong here?"** (that is `doc-diagnostic`). Style review never decides whether a doc should exist. It assumes the doc earned its place and asks whether the prose, structure, and Markdown are clean.

## How to run a review

Run in two passes. Do not interleave them — the architect reads a syntax violation differently from a style violation, and conflating the two confuses the response.

### Pass 1 — Syntax (must-fix)

Walk the file top to bottom. For each construct that violates the syntax canon (setext heading where ATX is expected, unfenced code block, missing blank line around a block element, ordered list using `)` instead of `.`, etc.), emit one finding at a time:

```text
Line N:
  Original: <verbatim line(s)>
  Layer:    syntax
  Rule:     <one-line rule from references/syntax-canon.md>
  Rewrite:  <corrected line(s)>
  Apply?    yes / no / adjust
```

Wait for the architect's reply before flagging the next finding. No bulk edits. Syntax findings always come before style findings.

### Pass 2 — Style (should-fix)

Re-walk the file. For each violation of the style overlay (heading > H2 used as the document title, no `[TOC]` directive on a long doc, prose line > 80 characters outside an exception, uninformative link text like "here", reference link defined far from its use, generic repeated subheading like "Summary" under multiple parents, etc.), emit the same finding format with `Layer: style`.

The style pass is suggestion, not enforcement. The architect can decline any finding without justification — the rule is opinionated, not canonical. Reasonable disagreement is acceptable; flag it and move on.

### Apply approved findings

After both passes are complete, apply only the approved rewrites in a single Edit pass. No audit markers in the file. No `[reviewed]` stamps. The diff is the audit trail.

## The two layers — quick reference

Detailed rules live in `references/`. The summaries below cover the violations that account for most findings.

### Syntax (must-fix) — quick reference

| Construct           | Rule                                                                            |
|---------------------|---------------------------------------------------------------------------------|
| Headings            | ATX (`#`–`######`), space after `#`, blank lines before and after.              |
| Paragraphs          | Separated by a blank line. Do not indent.                                       |
| Line breaks         | Trailing-two-spaces is "controversial" (see style overlay). Prefer a paragraph break. |
| Emphasis            | `**bold**`, `*italic*`, `***both***`. Use asterisks mid-word (underscores break). |
| Blockquotes         | `>` prefix; `>` on the blank line between paragraphs; nest with `>>`.           |
| Ordered lists       | `1.` `2.` `3.` (period, not `)`). Start at 1. Numbering can be lazy.            |
| Unordered lists     | Choose one of `-` / `*` / `+` and do not mix within a list.                     |
| Nested list content | Indent 4 spaces (1 tab). Code inside a list item indents 8 spaces (2 tabs).     |
| Inline code         | Single backticks. Double backticks if the code contains a backtick.             |
| Code blocks         | Fenced (` ``` `) with a language tag. Indented blocks are valid but discouraged. |
| Horizontal rule     | Three or more `---` / `***` / `___` alone on a line with blank lines around.    |
| Links               | `[text](url)`. Autolink with `<https://…>`. Reference links resolve elsewhere.  |
| Images              | `![alt](path "title")`. Always include alt text.                                |
| Escapes             | Prefix the following with `\`: `` \ ` * _ { } [ ] < > ( ) # + - . ! | ``.       |
| Inline HTML         | Allowed. Separate block-level HTML with blank lines. Do not indent the tags.    |

Full canon with examples and known-broken edge cases: `references/syntax-canon.md`.

### Style (should-fix) — quick reference

| Concern               | Rule                                                                                          |
|-----------------------|-----------------------------------------------------------------------------------------------|
| H1                    | Exactly one H1, used as the document title. Subsequent headings start at H2.                  |
| Heading style         | ATX only. Do not use setext underlines.                                                       |
| Heading uniqueness    | Avoid repeating bare subheadings ("Summary", "Example") under multiple parents. Prefix them.  |
| Document skeleton     | Title -> optional author -> 1–3 sentence intro -> `[TOC]` -> `## Topic` sections -> `## See also`. |
| Table of contents     | Use `[TOC]` for any doc that would not fit on one laptop screen. Place between intro and first H2. |
| Line length           | 80 characters. Exceptions: links, tables, headings, code blocks. Text around a long link still wraps. |
| Trailing whitespace   | None. Prefer a paragraph break to the two-space line-break trick.                              |
| Lists                 | Lazy numbering (`1.` repeated) for long ordered lists; full numbering for short stable ones. Prefer lists to tables when the data is one-dimensional. |
| Code fencing          | Always fenced (` ``` `), never indented. Always declare a language. Escape shell newlines with `\`. |
| Links                 | Explicit repo-absolute paths (`/path/to/page.md`) over `https://…` for in-repo links. Avoid `../` traversal. |
| Link text             | Informative. Never "here", "link", or a raw URL.                                              |
| Reference links       | Use them in tables, when the URL hurts readability, or when the same target appears multiple times. Define them just before the next heading. |
| Tables                | Only for scannable two-dimensional data. Avoid prose cells. Cells cannot wrap.                |
| Images                | Sparingly. Always include alt text.                                                            |
| Capitalization        | Preserve product / tool / binary capitalization (`Markdown`, not `markdown`).                  |
| HTML in Markdown      | Avoid. Big tables are the only common exception.                                              |

Full overlay with rationales: `references/style-overlay.md`.

## Routing — what this skill does not own

- **"Should this doc exist?"** -> `doc-diagnostic` (four-question diagnostic).
- **"Is this ADR honest?"** -> `adr-critique` (line-by-line audit against the "ADR is NOT" checklist — a *content* audit, not a *form* audit). Style and ADR critique can run on the same file; run ADR critique first because supersession may invalidate style work.
- **"Where does this doc belong?"** -> `doc-diagnostic` alternatives catalog.
- **"Is the prose understandable?"** -> out of scope. This skill enforces Markdown form, not prose clarity. Suggest a `doc-diagnostic` Audience check if the prose is unfit for its named audience.

## What this skill does NOT cover

This skill is **Markdown form only.** It covers heading style, list indentation, code-fence language tags, link syntax, line length, and the rest of the Markdown-Guide / Google-style-overlay rule sets. It does **not** cover:

- **Prose-level enforcement** — terminology consistency, inclusive-language substitutions, banned phrases, voice / tense / mood rules. The next layer up for that work is **[Vale](https://vale.sh)** (the prose-linter framework that runs configurable style packs over Markdown, AsciiDoc, reST, HTML, and more). Vale composes well with this skill: doc-master fixes the Markdown form; Vale enforces the prose terminology. doc-master does not bundle Vale or its rule packs.
- **AsciiDoc / reStructuredText / org-mode / MDX** — this skill is Markdown only. Other lightweight markup languages have their own canonical rules; reach for the matching tool (e.g., `asciidoctor --safe-mode`).
- **Spelling and grammar** — out of scope. Use a spell checker (`codespell`, `hunspell`, `LanguageTool`) in addition to this skill, not instead.

## Hard limits

- The skill flags findings — it does not bulk-rewrite. One finding at a time, per-line approval, mirrors `adr-critique`.
- Syntax findings ("must-fix") take precedence over style findings ("should-fix"). Never re-order.
- The skill does not invent new rules. Every finding must cite a rule from `references/syntax-canon.md` or `references/style-overlay.md`. If the user disputes a style finding, default to the user — the overlay is opinionated.
- The skill respects project-local conventions when they conflict with the canon (e.g., a project that has standardized on `_underscore_` emphasis). Note the conflict; defer to the project.

## Examples

<example>
<user_query>Lint this README — I think the formatting is messy.</user_query>
<response>
Loading the markdown-style skill. Two-pass review: syntax findings first (must-fix), then style findings (should-fix), one finding at a time with per-line approval.

Send the file path (or paste the content) and I will start the syntax pass.
</response>
</example>

<example>
<user_query>Is `===` under a heading line valid Markdown?</user_query>
<response>
Yes — that is setext-style H1. It is valid Markdown. But the style overlay (and most modern style guides, including Google's) prefer ATX style (`# Heading`) because setext underlines are "annoying to maintain," do not scale past H2, and obscure the heading level when scanning the file.

Recommendation: replace `===` with a single `#`. I can do that as a syntax-equivalent rewrite (no semantic change) if you point me at the file.
</response>
</example>

<example>
<user_query>What's the heading style for our docs?</user_query>
<response>
The skill's default is ATX (`#`, `##`, ..., `######`), one H1 used as the document title, subsequent headings start at H2, sentence-style capitalization, blank lines before and after. That mirrors Google's Markdown style guide.

If your project already has a different convention (e.g., all headings start at H1, or you use setext for top-level titles), tell me and I will defer to the project. The skill is opinionated but yields to project-local rules — note the conflict, move on.
</response>
</example>

## Attribution

The two layers in this skill are derived from publicly available style references:

- **Syntax canon** — distilled from the Markdown Guide basic-syntax reference (https://www.markdownguide.org/basic-syntax/), licensed CC BY-SA 4.0. See `NOTICES.md` at the plugin root.
- **Style overlay** — distilled from Google's developer documentation Markdown style guide (https://google.github.io/styleguide/docguide/style.html), part of `google/styleguide` (Apache License 2.0). See `NOTICES.md`.

The skill distills load-bearing rules from each source; it does not reproduce either document verbatim. When the user needs the original text, link out — do not paste long excerpts into this skill.
