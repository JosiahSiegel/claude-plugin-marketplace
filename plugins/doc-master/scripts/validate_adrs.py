#!/usr/bin/env python3
"""
validate_adrs.py - Quick ADR validator for doc-master.

Checks Architecture Decision Records (ADRs) under a target repository for:
  (a) conformance to the doc-master canon (filename, numbering, frontmatter
      required keys, lowercase status lifecycle, ISO date, deciders, graph
      edges),
  (b) compatibility with gray-matter-style frontmatter parsers (YAML
      frontmatter; relationship edges read from `supersedes`, `amends`,
      and `relates-to` keys only; IDs normalized via `/(\\d+)/` and
      zero-padded to four characters), and
  (c) compatibility with body-scanning MADR parsers -- the frontmatter
      relationships must be mirrored in a body `## More Information` ->
      `### Relationships` section using doc-master link prefixes
      (`Supersedes`, `Superseded by`, `Amends`, `Amended by`,
      `Related to`). The legacy MADR 2.x `## Links` heading is also
      accepted. ADRs with frontmatter relationships but no body mirror
      are reported as `missing-body-relationships` errors; ADRs with a
      body Relationships section but empty frontmatter relationships
      are reported as `missing-frontmatter-relationships` warnings.

Cross-platform. Standard library only. Runs on `python3`, `py -3`, or
`python` interchangeably.

Supported YAML frontmatter subset (intentionally minimal, no PyYAML):
  - Document delimited by `---` lines at start of file.
  - Scalar keys:            key: value
  - Quoted scalars:         key: "value"      key: 'value'
  - Block lists:            key:
                              - item
                              - item
  - Inline lists:           key: [a, b, "c"]
  - Block list of mappings: key:
                              - id: "0008"
                                reason: one-line reason
  - Empty lists:            key: []
  - Comments after `#` outside quoted strings.
  - Indentation by spaces (tabs are flagged as unsupported).

Any construct outside this subset (anchors, multi-line scalars, flow maps,
nested block maps under scalar keys, etc.) is reported as a WARN with a
clear "unsupported YAML construct" message; the script does not crash.

CLI:
  py -3 validate_adrs.py [--root <path>] [--format text|json] [--strict]

Exit codes:
  0 - no errors (warnings allowed unless --strict)
  1 - one or more errors found, or warnings in --strict mode

For ADR Explorer parser semantics, see the doc-master skills under
`plugins/doc-master/skills/doc-diagnostic/` and
`plugins/doc-master/skills/adr-drafting/references/template-fields.md`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_STATUSES = {"proposed", "accepted", "superseded", "deprecated"}
REQUIRED_KEYS = ("title", "status", "date", "deciders")
GRAPH_KEYS = ("supersedes", "amends", "relates-to")
GENERIC_DECIDERS = {"the team", "team", "tbd", "n/a", "na", "unknown", "everyone"}

ROOT_CANDIDATES = (
    "docs/adr",
    "docs/decisions",
    "docs/architecture/decisions",
    "architecture/decisions",
)

FILENAME_RE = re.compile(r"^(\d{4})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
ID_NORMALIZE_RE = re.compile(r"(\d+)")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
RELATED_BODY_RE = re.compile(r"^\s*(?:related\s+adrs?|see\s+also)\s*:", re.IGNORECASE)

# Body Relationships mirror -- doc-master MADR (currently 4.0.0) convention.
# Heading match is case-insensitive and accepts either `## More Information`
# (with `### Relationships` sub-section) or a top-level `## Relationships`
# section. The legacy MADR 2.x `## Links` heading is also accepted because
# body-scanning parsers in that family use it as the relationship anchor.
RELATIONSHIPS_HEADING_RE = re.compile(
    r"^\s{0,3}#{2,3}\s+(relationships|links|more\s+information)\s*$",
    re.IGNORECASE,
)
# Link-prefix vocabulary inside the Relationships section.
RELATIONSHIPS_LINK_PREFIX_RE = re.compile(
    r"^\s*(?:[-*]\s+)?(supersedes|superseded\s+by|amends|amended\s+by|"
    r"related\s+to|refined\s+by)\s+\[",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------

class Finding:
    __slots__ = ("level", "code", "message", "file", "line")

    def __init__(self, level: str, code: str, message: str,
                 file: str | None = None, line: int | None = None) -> None:
        self.level = level  # "error" | "warn"
        self.code = code
        self.message = message
        self.file = file
        self.line = line

    def to_dict(self) -> dict[str, Any]:
        d: dict[str, Any] = {"level": self.level, "code": self.code,
                             "message": self.message}
        if self.file is not None:
            d["file"] = self.file
        if self.line is not None:
            d["line"] = self.line
        return d


# ---------------------------------------------------------------------------
# Minimal YAML frontmatter parser
# ---------------------------------------------------------------------------

def _strip_comment(s: str) -> str:
    """Strip trailing `# ...` comment outside quoted strings."""
    out = []
    in_single = in_double = False
    for ch in s:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            break
        out.append(ch)
    return "".join(out).rstrip()


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s


def _split_inline_list(s: str) -> list[str]:
    """Split `[a, b, "c, d"]` respecting quotes. Assumes s begins with `[`."""
    s = s.strip()
    if not (s.startswith("[") and s.endswith("]")):
        raise ValueError("inline list missing brackets")
    inner = s[1:-1].strip()
    if not inner:
        return []
    items: list[str] = []
    buf: list[str] = []
    in_single = in_double = False
    for ch in inner:
        if ch == "'" and not in_double:
            in_single = not in_single
            buf.append(ch)
        elif ch == '"' and not in_single:
            in_double = not in_double
            buf.append(ch)
        elif ch == "," and not in_single and not in_double:
            items.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        items.append(tail)
    return [_unquote(it) for it in items]


def extract_frontmatter(text: str) -> tuple[str | None, int]:
    """Return (frontmatter_text, body_start_line_1based) or (None, 0).

    Frontmatter is delimited by `---` at line 1 and a subsequent `---`.
    Lines use \n separation; CRLF tolerated.
    """
    # Normalize line endings for scanning only; we keep original for output.
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, 0
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return None, 0
    fm = "\n".join(lines[1:end])
    return fm, end + 2  # body starts after closing `---`


def parse_frontmatter(fm_text: str) -> tuple[dict[str, Any], list[Finding]]:
    """Parse the supported YAML subset. Returns (data, warnings).

    Unsupported constructs surface as warnings; parsing continues best-effort.
    """
    warnings: list[Finding] = []
    data: dict[str, Any] = {}
    # Tokenize into logical lines with indentation.
    raw_lines = fm_text.split("\n")
    # Strip comments and detect tabs.
    cleaned: list[tuple[int, int, str]] = []  # (lineno_1based, indent, content)
    for idx, raw in enumerate(raw_lines, start=2):  # +2 because of opening `---`
        if "\t" in raw:
            warnings.append(Finding(
                "warn", "yaml-unsupported",
                "tab character in frontmatter; only spaces are supported",
                line=idx,
            ))
            raw = raw.replace("\t", "    ")
        stripped_comment = _strip_comment(raw)
        if not stripped_comment.strip():
            continue
        indent = len(stripped_comment) - len(stripped_comment.lstrip(" "))
        cleaned.append((idx, indent, stripped_comment.rstrip()))

    i = 0
    n = len(cleaned)
    while i < n:
        lineno, indent, content = cleaned[i]
        if indent != 0:
            warnings.append(Finding(
                "warn", "yaml-unsupported",
                f"unexpected indentation at top level: {content!r}",
                line=lineno,
            ))
            i += 1
            continue
        if ":" not in content:
            warnings.append(Finding(
                "warn", "yaml-unsupported",
                f"line is not `key: value`: {content!r}",
                line=lineno,
            ))
            i += 1
            continue
        key, _, rest = content.partition(":")
        key = key.strip()
        rest = rest.strip()
        if rest == "":
            # Block list or block map follows.
            items: list[Any] = []
            j = i + 1
            saw_dash = False
            saw_map = False
            while j < n and cleaned[j][1] > indent:
                _ln, child_indent, child_content = cleaned[j]
                if child_content.lstrip().startswith("-"):
                    saw_dash = True
                    # Block list item.
                    item_content = child_content.lstrip()[1:].strip()
                    if item_content == "":
                        # Bare `-` followed by mapping lines on subsequent indented lines.
                        sub: dict[str, Any] = {}
                        k = j + 1
                        while k < n and cleaned[k][1] > child_indent:
                            sub_ln, _sub_indent, sub_content = cleaned[k]
                            if ":" in sub_content:
                                sk, _, sv = sub_content.partition(":")
                                sub[sk.strip()] = _unquote(sv.strip())
                            else:
                                warnings.append(Finding(
                                    "warn", "yaml-unsupported",
                                    f"unsupported list item construct: {sub_content!r}",
                                    line=sub_ln,
                                ))
                            k += 1
                        items.append(sub)
                        j = k
                        continue
                    if ":" in item_content and not (item_content.startswith("'")
                                                    or item_content.startswith('"')):
                        # Inline `- id: "0008"` followed by sibling indented `reason: ...`.
                        sub = {}
                        sk, _, sv = item_content.partition(":")
                        sub[sk.strip()] = _unquote(sv.strip())
                        k = j + 1
                        # Sibling keys are indented deeper than the `-`.
                        dash_col = child_indent
                        while k < n and cleaned[k][1] > dash_col:
                            sub_ln, sub_indent, sub_content = cleaned[k]
                            if sub_content.lstrip().startswith("-"):
                                break
                            if ":" in sub_content:
                                ssk, _, ssv = sub_content.partition(":")
                                sub[ssk.strip()] = _unquote(ssv.strip())
                            else:
                                warnings.append(Finding(
                                    "warn", "yaml-unsupported",
                                    f"unsupported list item construct: {sub_content!r}",
                                    line=sub_ln,
                                ))
                            k += 1
                        items.append(sub)
                        saw_map = True
                        j = k
                        continue
                    # Bare scalar item.
                    items.append(_unquote(item_content))
                    j += 1
                else:
                    warnings.append(Finding(
                        "warn", "yaml-unsupported",
                        f"expected block list `-` under `{key}`, got: {child_content!r}",
                        line=_ln,
                    ))
                    j += 1
            if not saw_dash:
                if j == i + 1:
                    # No children at all -> treat as empty value (null).
                    data[key] = None
                else:
                    # Children were present but none were list items -> not supported.
                    warnings.append(Finding(
                        "warn", "yaml-unsupported",
                        f"nested mapping under `{key}` is not supported by the minimal parser",
                        line=lineno,
                    ))
                    data[key] = None
            else:
                data[key] = items
            i = j
            continue
        # Scalar or inline list.
        if rest.startswith("["):
            try:
                data[key] = _split_inline_list(rest)
            except ValueError as e:
                warnings.append(Finding(
                    "warn", "yaml-unsupported",
                    f"unparseable inline list for `{key}`: {e}",
                    line=lineno,
                ))
                data[key] = None
        else:
            data[key] = _unquote(rest)
        i += 1
    return data, warnings


# ---------------------------------------------------------------------------
# ADR discovery
# ---------------------------------------------------------------------------

def autodetect_root(base: Path) -> Path | None:
    for candidate in ROOT_CANDIDATES:
        p = base / candidate
        if p.is_dir():
            return p
    return None


def find_adr_files(root: Path) -> list[Path]:
    """Return ADR markdown files under `root`. Excludes README.md and index.md."""
    files: list[Path] = []
    for p in sorted(root.rglob("*.md")):
        name = p.name.lower()
        if name in ("readme.md", "index.md"):
            continue
        # Heuristic: ADR files start with digits.
        if not re.match(r"^\d", p.name):
            # Still include but flag via filename check; skip obvious non-ADRs.
            continue
        files.append(p)
    return files


def fallback_scan(base: Path) -> list[Path]:
    """Scan **/adr/*.md when no canonical root exists."""
    out: list[Path] = []
    for p in base.rglob("*.md"):
        # Match a path component literally named `adr` (case-insensitive).
        parts = [part.lower() for part in p.parts]
        if "adr" in parts and re.match(r"^\d", p.name):
            out.append(p)
    return sorted(out)


# ---------------------------------------------------------------------------
# Per-file validation
# ---------------------------------------------------------------------------

def normalize_id(value: Any) -> str | None:
    """Extract digits and zero-pad to 4. Mirrors ADR Explorer `/(\\d+)/` rule."""
    if value is None:
        return None
    if isinstance(value, (list, dict)):
        return None
    s = str(value)
    m = ID_NORMALIZE_RE.search(s)
    if not m:
        return None
    digits = m.group(1)
    return digits.zfill(4)


def validate_file(path: Path, root: Path) -> tuple[dict[str, Any], list[Finding]]:
    """Return (parsed_record, findings) for a single ADR file."""
    try:
        rel = path.relative_to(root).as_posix()
    except ValueError:
        rel = path.name
    findings: list[Finding] = []
    record: dict[str, Any] = {
        "path": str(path),
        "rel": rel,
        "id": None,
        "frontmatter": None,
        "references": {"supersedes": [], "amends": [], "relates-to": []},
    }

    # Filename check.
    m = FILENAME_RE.match(path.name)
    if not m:
        findings.append(Finding(
            "error", "filename-format",
            f"filename does not match NNNN-kebab-imperative-title.md: {path.name!r}",
            file=rel,
        ))
    else:
        record["id"] = m.group(1)

    # Read content.
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        findings.append(Finding(
            "error", "encoding",
            "file is not valid UTF-8", file=rel,
        ))
        return record, findings

    fm_text, body_start = extract_frontmatter(text)
    if fm_text is None:
        findings.append(Finding(
            "error", "no-frontmatter",
            "missing YAML frontmatter delimited by `---` lines (required for "
            "ADR Explorer-style parsers using gray-matter)",
            file=rel,
        ))
        return record, findings

    data, yaml_warns = parse_frontmatter(fm_text)
    for w in yaml_warns:
        w.file = rel
        findings.append(w)
    record["frontmatter"] = data

    # Required keys.
    for key in REQUIRED_KEYS:
        if key not in data or data[key] in (None, "", []):
            findings.append(Finding(
                "error", "missing-key",
                f"required frontmatter key missing or empty: `{key}`",
                file=rel,
            ))

    # Status.
    status = data.get("status")
    if status is not None:
        if not isinstance(status, str):
            findings.append(Finding(
                "error", "status-type",
                f"`status` must be a string, got {type(status).__name__}",
                file=rel,
            ))
        elif status not in VALID_STATUSES:
            findings.append(Finding(
                "warn", "status-value",
                f"`status: {status}` is not one of "
                f"{sorted(VALID_STATUSES)}; ADR Explorer-style tools may "
                f"ignore unknown values",
                file=rel,
            ))

    # Date.
    date = data.get("date")
    if isinstance(date, str) and not DATE_RE.match(date):
        findings.append(Finding(
            "error", "date-format",
            f"`date: {date}` is not ISO 8601 (YYYY-MM-DD)",
            file=rel,
        ))

    # Deciders.
    deciders = data.get("deciders")
    if deciders is not None:
        if not isinstance(deciders, list):
            findings.append(Finding(
                "error", "deciders-type",
                "`deciders` must be a YAML list",
                file=rel,
            ))
        elif len(deciders) == 0:
            findings.append(Finding(
                "error", "deciders-empty",
                "`deciders` list is empty",
                file=rel,
            ))
        else:
            non_generic = [d for d in deciders if isinstance(d, str)
                           and d.strip().lower() not in GENERIC_DECIDERS]
            if not non_generic:
                findings.append(Finding(
                    "error", "deciders-generic",
                    "`deciders` contains only generic values "
                    "(e.g., 'the team', 'tbd'); name a human",
                    file=rel,
                ))

    # Graph-bearing keys.
    for gk in ("supersedes", "amends"):
        v = data.get(gk)
        if v is None:
            continue
        if not isinstance(v, list):
            findings.append(Finding(
                "error", "graph-key-type",
                f"`{gk}` must be a YAML list (use `[]` if empty)",
                file=rel,
            ))
            continue
        for entry in v:
            if isinstance(entry, dict):
                findings.append(Finding(
                    "warn", "graph-key-shape",
                    f"`{gk}` entries should be bare IDs, not mappings",
                    file=rel,
                ))
                continue
            nid = normalize_id(entry)
            if nid is None:
                findings.append(Finding(
                    "warn", "id-unparseable",
                    f"`{gk}` entry {entry!r} has no extractable digits",
                    file=rel,
                ))
            else:
                record["references"][gk].append(nid)

    rel_to = data.get("relates-to")
    if rel_to is not None:
        if not isinstance(rel_to, list):
            findings.append(Finding(
                "error", "graph-key-type",
                "`relates-to` must be a YAML list",
                file=rel,
            ))
        else:
            for entry in rel_to:
                if isinstance(entry, dict):
                    eid = entry.get("id")
                    nid = normalize_id(eid)
                    if nid is None:
                        findings.append(Finding(
                            "warn", "id-unparseable",
                            f"`relates-to` entry {entry!r} has no extractable id",
                            file=rel,
                        ))
                    else:
                        record["references"]["relates-to"].append(nid)
                    if not entry.get("reason"):
                        findings.append(Finding(
                            "warn", "relates-to-no-reason",
                            f"`relates-to` entry for id {eid!r} is missing "
                            f"`reason` (recommended for traceability)",
                            file=rel,
                        ))
                else:
                    nid = normalize_id(entry)
                    if nid is None:
                        findings.append(Finding(
                            "warn", "id-unparseable",
                            f"`relates-to` entry {entry!r} has no extractable digits",
                            file=rel,
                        ))
                    else:
                        record["references"]["relates-to"].append(nid)
                        findings.append(Finding(
                            "warn", "relates-to-no-reason",
                            f"`relates-to` entry {entry!r} is a bare id; "
                            f"add `reason` for traceability",
                            file=rel,
                        ))

    # Body hint: prose `Related ADRs:` lines.
    body_lines = text.splitlines()[body_start - 1:] if body_start else []
    for offset, line in enumerate(body_lines):
        if RELATED_BODY_RE.match(line):
            findings.append(Finding(
                "warn", "body-related-prose",
                f"line uses prose `Related ADRs:`/`See also:` form; "
                f"gray-matter-style parsers ignore the body — move ADR "
                f"links into the `relates-to` frontmatter list (and mirror "
                f"them in the body `### Relationships` section) to make them "
                f"graph-visible",
                file=rel,
                line=body_start + offset,
            ))
            break  # one hint per file is enough

    # Frontmatter / body Relationships mirror.
    has_fm_relationships = any(
        len(record["references"][gk]) > 0 for gk in GRAPH_KEYS
    )
    relationships_heading_line: int | None = None
    relationships_link_lines: list[int] = []
    in_relationships = False
    for offset, line in enumerate(body_lines):
        if RELATIONSHIPS_HEADING_RE.match(line):
            relationships_heading_line = body_start + offset
            in_relationships = True
            continue
        if in_relationships:
            stripped = line.lstrip()
            # Stop at the next heading of equal or higher level. Use the
            # detected heading depth: any `## ...` ends an `### ...` section,
            # and any subsequent `## ...` / `### ...` that does not match the
            # relationships pattern ends scanning.
            if stripped.startswith("#") and not RELATIONSHIPS_HEADING_RE.match(line):
                in_relationships = False
                continue
            if RELATIONSHIPS_LINK_PREFIX_RE.match(line):
                relationships_link_lines.append(body_start + offset)

    has_body_relationships = (
        relationships_heading_line is not None and len(relationships_link_lines) > 0
    )

    if has_fm_relationships and not has_body_relationships:
        findings.append(Finding(
            "error", "missing-body-relationships",
            "frontmatter populates `supersedes` / `amends` / `relates-to` "
            "but body has no `## More Information` -> `### Relationships` "
            "(or `## Relationships`) section with link-prefix prose "
            "(`Supersedes`, `Superseded by`, `Amends`, `Amended by`, "
            "`Related to`); body-scanning parsers (ADR Manager and similar) "
            "will not see the relationships -- mirror them into the body",
            file=rel,
        ))
    elif has_body_relationships and not has_fm_relationships:
        findings.append(Finding(
            "warn", "missing-frontmatter-relationships",
            "body has a Relationships section with link-prefix prose but "
            "frontmatter `supersedes` / `amends` / `relates-to` are empty "
            "or absent; gray-matter-style parsers (ADR Explorer and "
            "similar) will not see the relationships -- promote each body "
            "link into the matching frontmatter list",
            file=rel,
            line=relationships_heading_line,
        ))

    return record, findings


# ---------------------------------------------------------------------------
# Corpus-level validation
# ---------------------------------------------------------------------------

def validate_corpus(records: list[dict[str, Any]]) -> list[Finding]:
    """Cross-file checks: dupes, gaps, dangling refs, self-refs, cycles."""
    findings: list[Finding] = []

    # Build id -> [records] map (skip records without parseable id).
    by_id: dict[str, list[dict[str, Any]]] = {}
    ids: list[int] = []
    for rec in records:
        if rec["id"] is None:
            continue
        by_id.setdefault(rec["id"], []).append(rec)
        try:
            ids.append(int(rec["id"]))
        except ValueError:
            pass

    # Duplicates.
    for nid, recs in by_id.items():
        if len(recs) > 1:
            paths = ", ".join(r["rel"] for r in recs)
            findings.append(Finding(
                "error", "duplicate-id",
                f"id {nid} is reused across multiple files: {paths}",
            ))

    # Gaps.
    if ids:
        ids_sorted = sorted(set(ids))
        lo, hi = ids_sorted[0], ids_sorted[-1]
        present = set(ids_sorted)
        missing = [n for n in range(lo, hi + 1) if n not in present]
        if missing:
            preview = ", ".join(f"{n:04d}" for n in missing[:10])
            if len(missing) > 10:
                preview += f", ... (+{len(missing) - 10} more)"
            findings.append(Finding(
                "warn", "id-gap",
                f"non-contiguous ADR ids between {lo:04d} and {hi:04d}; "
                f"missing: {preview}",
            ))

    # Dangling and self references; build edges for cycle detection.
    edges_supersedes: dict[str, set[str]] = {}
    for rec in records:
        rid = rec["id"]
        for gk in GRAPH_KEYS:
            for target in rec["references"][gk]:
                if rid is not None and target == rid:
                    findings.append(Finding(
                        "error", "self-reference",
                        f"`{gk}` references the file's own id ({target})",
                        file=rec["rel"],
                    ))
                    continue
                if target not in by_id:
                    findings.append(Finding(
                        "error", "dangling-reference",
                        f"`{gk}` references id {target}, but no ADR file "
                        f"with that id exists in the corpus",
                        file=rec["rel"],
                    ))
                if gk == "supersedes" and rid is not None:
                    edges_supersedes.setdefault(rid, set()).add(target)

    # Cycle detection over `supersedes` edges.
    cycles = _find_cycles(edges_supersedes)
    for cyc in cycles:
        findings.append(Finding(
            "error", "supersedes-cycle",
            "circular `supersedes` chain: " + " -> ".join(cyc + [cyc[0]]),
        ))

    return findings


def _find_cycles(edges: dict[str, set[str]]) -> list[list[str]]:
    """DFS cycle finder. Returns list of cycles (each a list of node ids)."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {n: WHITE for n in edges}
    parent: dict[str, str | None] = {}
    cycles: list[list[str]] = []
    seen_cycles: set[tuple[str, ...]] = set()

    def dfs(u: str) -> None:
        color[u] = GRAY
        for v in edges.get(u, ()):
            if v not in color:
                color[v] = WHITE
                parent[v] = u
            if color[v] == WHITE:
                parent[v] = u
                dfs(v)
            elif color[v] == GRAY:
                # Reconstruct cycle from v back to v.
                cyc = [v]
                cur = u
                while cur is not None and cur != v:
                    cyc.append(cur)
                    cur = parent.get(cur)
                cyc.reverse()
                key = tuple(sorted(cyc))
                if key not in seen_cycles:
                    seen_cycles.add(key)
                    cycles.append(cyc)
        color[u] = BLACK

    for node in list(edges.keys()):
        if color.get(node, WHITE) == WHITE:
            parent[node] = None
            dfs(node)
    return cycles


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def render_text(records: list[dict[str, Any]],
                findings: list[Finding],
                root: Path,
                strict: bool) -> str:
    lines: list[str] = []
    lines.append(f"ADR validation - root: {root}")
    lines.append(f"Found {len(records)} ADR file(s).")
    lines.append("")

    by_file: dict[str, list[Finding]] = {}
    corpus_findings: list[Finding] = []
    for f in findings:
        if f.file is None:
            corpus_findings.append(f)
        else:
            by_file.setdefault(f.file, []).append(f)

    if records:
        for rec in records:
            rel = rec["rel"]
            file_findings = by_file.get(rel, [])
            if not file_findings:
                lines.append(f"[OK]    {rel}")
                continue
            lines.append(f"        {rel}")
            for f in file_findings:
                tag = "[ERROR]" if f.level == "error" else "[WARN] "
                loc = f" (line {f.line})" if f.line else ""
                lines.append(f"  {tag} {f.code}: {f.message}{loc}")
        lines.append("")

    if corpus_findings:
        lines.append("Corpus-level findings:")
        for f in corpus_findings:
            tag = "[ERROR]" if f.level == "error" else "[WARN] "
            lines.append(f"  {tag} {f.code}: {f.message}")
        lines.append("")

    err = sum(1 for f in findings if f.level == "error")
    warn = sum(1 for f in findings if f.level == "warn")
    effective_errors = err + (warn if strict else 0)
    lines.append(f"Summary: {len(records)} file(s), {err} error(s), {warn} warning(s)"
                 + (" [strict: warnings count as errors]" if strict else ""))
    lines.append(f"Exit: {0 if effective_errors == 0 else 1}")
    return "\n".join(lines) + "\n"


def render_json(records: list[dict[str, Any]],
                findings: list[Finding],
                root: Path,
                strict: bool) -> str:
    err = sum(1 for f in findings if f.level == "error")
    warn = sum(1 for f in findings if f.level == "warn")
    effective_errors = err + (warn if strict else 0)
    payload = {
        "schema": "doc-master.validate_adrs.v1",
        "root": str(root),
        "files": [
            {
                "path": rec["rel"],
                "id": rec["id"],
                "frontmatter_present": rec["frontmatter"] is not None,
                "references": rec["references"],
            }
            for rec in records
        ],
        "findings": [f.to_dict() for f in findings],
        "summary": {
            "file_count": len(records),
            "errors": err,
            "warnings": warn,
            "strict": strict,
            "exit_code": 0 if effective_errors == 0 else 1,
        },
    }
    return json.dumps(payload, indent=2) + "\n"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="validate_adrs.py",
        description=(
            "Validate Architecture Decision Records against the doc-master "
            "canon and ADR Explorer-style parser semantics."
        ),
    )
    parser.add_argument("--root", default=None,
                        help="ADR root directory (default: autodetect).")
    parser.add_argument("--format", choices=("text", "json"), default="text",
                        help="Output format (default: text).")
    parser.add_argument("--strict", action="store_true",
                        help="Treat warnings as errors for exit code.")
    parser.add_argument("--base", default=".",
                        help="Repository base for autodetection "
                             "(default: current working directory).")
    args = parser.parse_args(argv)

    base = Path(args.base).resolve()
    fallback = False
    if args.root:
        root = Path(args.root).resolve()
        if not root.is_dir():
            print(f"[ERROR] root not found: {root}", file=sys.stderr)
            return 1
        files = find_adr_files(root)
    else:
        detected = autodetect_root(base)
        if detected is not None:
            root = detected
            files = find_adr_files(root)
        else:
            fallback = True
            root = base
            files = fallback_scan(base)

    if fallback and not files:
        msg = (f"[WARN] no ADR directory found under {base} "
               f"(checked: {', '.join(ROOT_CANDIDATES)} and **/adr/*.md). "
               f"Nothing to validate.")
        if args.format == "json":
            payload = {
                "schema": "doc-master.validate_adrs.v1",
                "root": str(root),
                "files": [],
                "findings": [{"level": "warn", "code": "no-adr-root",
                              "message": msg}],
                "summary": {"file_count": 0, "errors": 0, "warnings": 1,
                            "strict": args.strict,
                            "exit_code": 1 if args.strict else 0},
            }
            print(json.dumps(payload, indent=2))
        else:
            print(msg)
        return 1 if args.strict else 0

    records: list[dict[str, Any]] = []
    all_findings: list[Finding] = []
    for f in files:
        rec, fnds = validate_file(f, root)
        records.append(rec)
        all_findings.extend(fnds)

    all_findings.extend(validate_corpus(records))

    if args.format == "json":
        sys.stdout.write(render_json(records, all_findings, root, args.strict))
    else:
        sys.stdout.write(render_text(records, all_findings, root, args.strict))

    err = sum(1 for f in all_findings if f.level == "error")
    warn = sum(1 for f in all_findings if f.level == "warn")
    effective_errors = err + (warn if args.strict else 0)
    return 0 if effective_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
