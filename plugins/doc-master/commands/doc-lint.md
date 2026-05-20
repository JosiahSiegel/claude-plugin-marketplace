---
description: Lint a Markdown document — two-pass review (syntax must-fix, then style should-fix) per-finding with architect approval. Cites a rule and source layer for every finding. Does not bulk-rewrite.
---

# /doc-lint

Use this command to review the formatting and style of a Markdown file — README, how-to, explanation, reference page, RFC, ADR body, runbook, design doc, contributing guide, or any `.md`.

## What this command does

Hands the review to the `doc-expert` agent, which activates the `markdown-style` skill. The skill runs two passes, in order:

1. **Pass 1 — Syntax (must-fix).** Walks the file top to bottom and flags constructs that violate the canonical Markdown syntax rules (setext where ATX is expected, unfenced code blocks, missing blank lines around block elements, ordered lists using `)`, mid-word underscore emphasis, indented HTML, etc.). One finding at a time, with line numbers, the offending text quoted verbatim, the rule cited, and the corrected form proposed. Architect approves, declines, or adjusts each one.
2. **Pass 2 — Style (should-fix).** Re-walks the file and flags violations of the opinionated style overlay (multiple H1s, missing `[TOC]` on a long doc, prose lines over 80 characters, uninformative link text like "here", repeated bare subheadings, fenced code blocks without a language tag, reference link definitions far from their use, etc.). Same per-finding format. The architect can decline any style finding without justification.

After both passes, the agent applies only the approved rewrites in a single Edit pass. No audit markers, no `[reviewed]` stamps, no bulk rewrites. The diff is the audit trail.

## Your input

- The path to the file (or directory) to lint.
- Optionally: which pass to run. Default is both. Use "syntax only" if you only want must-fixes; use "style only" when the file already passes syntax and you want the opinionated overlay.
- Optionally: project-local conventions that override the defaults. Example: "we use setext for the document title" or "we use underscore emphasis." The skill defers to the project when a local convention conflicts with the overlay.

## What this command will NOT do

- Bulk-rewrite the file. Every change requires per-line approval.
- Rewrite the body of an `accepted` ADR. ADR body rewrites go through `adr-drafting` as a new superseding ADR; this command can edit ADR headers (status fences, supersession links) but not content lines.
- Rewrite generated files, third-party imports, or license boilerplate. Tell the agent which paths are off-limits.
- Re-order syntax and style findings. Syntax findings always come first, because applying a style rewrite to invalid syntax compounds the problem.
- Audit prose clarity, doc placement, or whether the doc should exist. Those are the territory of `doc-diagnostic` and `/doc-audit`.

Use `/doc-audit` for folder-level KEEP / MERGE / REWRITE / DELETE / MOVE classification. Use `/adr-critique` for content-level ADR audit (filler, hedging, missing-why). Use `/doc-lint` for Markdown form on any one file.
