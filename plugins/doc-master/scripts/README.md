# doc-master scripts

Utility scripts that ship with the `doc-master` plugin. Standard library
only — no third-party dependencies.

## `validate_adrs.py`

Quick validator for Architecture Decision Records (ADRs) in a target
repository. Checks two things at once:

1. **Conformance to the doc-master canon** — filename pattern, monotonic
   zero-padded numbering, YAML frontmatter, required keys, lowercase
   status lifecycle, ISO 8601 date, non-generic deciders, graph-bearing
   keys (`supersedes`, `amends`, `relates-to`) with `id` + `reason`
   shape.
2. **Compatibility with gray-matter-style frontmatter parsers** (ADR
   Explorer and similar) — the parsers in that family parse frontmatter
   via `gray-matter` and read relationship edges from frontmatter only.
   Body prose like `Related ADRs: [ADR-0001](...)` is invisible to the
   graph. ID values normalize via `/(\d+)/` and zero-pad to four
   characters, so `8`, `"08"`, `"0008"`, and `"ADR-0008"` all resolve
   to the same node. The script enforces that and flags dangling,
   duplicate, self-referential, and circular references.
3. **Compatibility with body-scanning MADR parsers** (ADR Manager and
   similar) — these parsers ignore frontmatter and walk the rendered
   Markdown for ADR-to-ADR links under known section headings. The
   script enforces doc-master's **mirror rule**: every frontmatter
   relationship must also appear in a body `## More Information` ->
   `### Relationships` section (or top-level `## Relationships`, or
   the legacy MADR 2.x `## Links`) using doc-master's link-prefix
   vocabulary — `Supersedes`, `Superseded by`, `Amends`, `Amended by`,
   `Related to`. The two sources must agree.

### Usage

```text
py -3 plugins/doc-master/scripts/validate_adrs.py [--root <path>] \
  [--format text|json] [--strict] [--base <repo-root>]
```

The script is platform-agnostic. Run it with whichever Python launcher
you have:

```text
py -3   plugins/doc-master/scripts/validate_adrs.py     # Windows launcher
python3 plugins/doc-master/scripts/validate_adrs.py     # macOS / Linux
python  plugins/doc-master/scripts/validate_adrs.py     # generic
```

Flags:

| Flag | Default | Behavior |
|------|---------|----------|
| `--root <path>` | autodetect | ADR root. Autodetects the first existing of `docs/adr`, `docs/decisions`, `docs/architecture/decisions`, `architecture/decisions`. Falls back to scanning `**/adr/*.md` from `--base`. |
| `--base <path>` | `.` | Repository base used for autodetection and fallback scan. |
| `--format text\|json` | `text` | `text` is human-friendly with `[OK]` / `[WARN]` / `[ERROR]` prefixes. `json` emits a stable schema (`doc-master.validate_adrs.v1`) suitable for CI. |
| `--strict` | off | Upgrades warnings to errors for the exit code. Output still labels them as warnings. |

### Checks per file

- **Filename** — must match `NNNN-kebab-imperative-title.md` (four-digit
  zero-padded id, lowercase hyphenated slug, `.md` extension).
- **Frontmatter delimiters** — file must start with `---` and contain a
  closing `---` (the gray-matter contract).
- **Required keys** — `title`, `status`, `date`, `deciders` present and
  non-empty.
- **`status`** — one of `proposed`, `accepted`, `superseded`,
  `deprecated` (lowercase). Anything else (`rfc`, `rejected`,
  `backfilled`, `draft`, etc.) is a warning.
- **`date`** — ISO 8601 `YYYY-MM-DD`.
- **`deciders`** — non-empty YAML list; must contain at least one entry
  that is not a generic placeholder (`"the team"`, `"team"`, `"tbd"`,
  `"n/a"`, `"unknown"`).
- **`supersedes`, `amends`** — YAML lists of bare ids (mappings are
  flagged). Each id must resolve, via the `/(\d+)/` rule, to a file
  that exists in the corpus.
- **`relates-to`** — YAML list of mappings each with `id` and `reason`,
  or bare ids (bare ids produce a warning recommending `reason`).
- **Self / dangling / circular references** — flagged at corpus level.
- **Body hint** — if the body contains a `Related ADRs:` or `See also:`
  line (outside the `### Relationships` section), a warning reminds you
  that gray-matter-style parsers ignore the body; promote those links
  into `relates-to` frontmatter and mirror them in the body
  `### Relationships` section.
- **`missing-body-relationships`** *(error)* — frontmatter populates
  `supersedes` / `amends` / `relates-to` but the body has no
  `## More Information` -> `### Relationships` (or `## Relationships`,
  or legacy `## Links`) section with the link-prefix prose. Body-
  scanning parsers cannot see the relationships.
- **`missing-frontmatter-relationships`** *(warning)* — the body has a
  Relationships section listing ADR-to-ADR links via the doc-master
  link-prefix vocabulary, but frontmatter `supersedes` / `amends` /
  `relates-to` are empty or absent. Gray-matter-style parsers cannot
  see the relationships.

### Corpus checks

- **Duplicate ids** — same four-digit id appearing in two files
  (`error`).
- **Id gaps** — non-contiguous numbering between the smallest and
  largest id (`warning`).

### Supported YAML subset

The script ships with a minimal frontmatter parser to avoid a PyYAML
dependency. Supported:

- Scalar `key: value`
- Quoted scalars (single or double quotes)
- Block lists (`- item`)
- Inline lists (`[a, b, "c"]`)
- Block list of mappings (`- id: "0008"` plus indented sibling keys
  such as `reason: ...`)
- Empty lists (`key: []`)
- Comments after `#` outside quoted strings
- Space-only indentation (tabs are flagged as a warning)

Anything outside this subset (anchors, multi-line scalars, flow maps,
nested block maps under scalar keys, etc.) surfaces as a `WARN` with a
clear "unsupported YAML construct" message. The script does not crash
on unsupported input; it best-effort parses what it can.

For decision logs that need richer YAML, run the script after a
gray-matter / PyYAML-based linter — the doc-master script is the
quick check, not the full parser.

### Exit codes

| Code | Meaning |
|------|---------|
| `0`  | No errors. Warnings are allowed unless `--strict` is set. |
| `1`  | One or more errors, **or** any warnings under `--strict`, **or** no ADR root found under `--strict`. |

### Examples

```text
# Validate the autodetected ADR root in the current repo.
py -3 plugins/doc-master/scripts/validate_adrs.py

# Point at an explicit root.
py -3 plugins/doc-master/scripts/validate_adrs.py --root docs/decisions

# Machine-readable output for CI.
py -3 plugins/doc-master/scripts/validate_adrs.py --format json

# Strict mode for a release gate.
py -3 plugins/doc-master/scripts/validate_adrs.py --strict

# Validate a sibling repository.
py -3 plugins/doc-master/scripts/validate_adrs.py --base ../other-repo
```

### See also

ADR Explorer parser semantics — how relationship edges are read from
frontmatter and how ids are normalized — are documented in the
doc-master skills:

- `plugins/doc-master/skills/doc-diagnostic/SKILL.md` — section
  "Storage and discoverability".
- `plugins/doc-master/skills/adr-drafting/references/template-fields.md`
  — section "How ADR Explorer-style parsers read these fields".
