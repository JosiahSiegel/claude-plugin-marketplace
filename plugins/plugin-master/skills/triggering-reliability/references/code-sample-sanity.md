<!-- validator:allow-smart-punct -->
<!-- This reference legitimately catalogs the smart-punctuation codepoints the validator flags. -->

# Code-sample sanity pass — extended reference

This file holds the full sweeps and tables that `SKILL.md` summarises under the **Code-sample sanity pass** section. Run these before every ship. Any output is a finding to fix manually.

The sanity pass has two probes:

1. **Smart-punctuation probe** — fenced code blocks must contain only ASCII (curly quotes, em/en dashes, and Unicode ellipsis break grep, JSON, and shell quoting).
2. **Fence-language-tag probe** — every fenced code block must declare a language tag (e.g. ```` ```bash ````, ```` ```powershell ````, ```` ```yaml ````). Untagged fences disable syntax highlighting and obscure platform assumptions — a fence written for bash that renders as plain text looks identical to one written for PowerShell.

## Shell-portability rule for executable snippets

Any executable snippet inside a fenced code block in a SKILL.md or reference file MUST either:

- be **dual-form** — show both a POSIX (bash/sh) variant AND a PowerShell variant, OR
- be **explicitly platform-tagged** — open with a one-line prose marker such as `On bash/macOS/Linux:` or `On PowerShell (Windows):` immediately before the fence, AND use the matching language tag on the fence (```` ```bash ```` vs ```` ```powershell ````).

This repo's primary shell is PowerShell on Windows, so a bash-only snippet without a platform tag is a defect: a reader on Windows will copy it and watch it fail with no signal as to why.

## Smart-punctuation sweep — bash

```bash
# Pull every fenced code block and grep it for smart punctuation.
# awk extracts content between ``` fences; grep -nP flags suspicious chars.
for f in $(find . -name '*.md' -not -path './node_modules/*'); do
  awk '/^```/{flag=!flag; next} flag' "$f" \
    | grep -nP '[\x{2026}\x{201C}\x{201D}\x{2018}\x{2019}\x{2013}\x{2014}]' \
    && echo "  ^ in $f"
done
```

## Smart-punctuation sweep — PowerShell

```powershell
# PowerShell equivalent of the bash sweep above.
# Walks every .md file, tracks whether the current line is inside a fenced block,
# and flags lines that contain smart-punctuation codepoints.
$pattern = '[…“”‘’–—]'
Get-ChildItem -Recurse -Filter '*.md' -Exclude 'node_modules' | ForEach-Object {
    $file = $_.FullName
    $inFence = $false
    $lineNo = 0
    Get-Content -LiteralPath $file | ForEach-Object {
        $lineNo++
        if ($_ -match '^```') { $inFence = -not $inFence; return }
        if ($inFence -and ($_ -match $pattern)) {
            "${file}:${lineNo}: $_"
        }
    }
}
```

## Fence-language-tag probe — bash

```bash
# Flag fenced code blocks that open with ``` and no language tag.
# Matches lines that are exactly three backticks (optionally followed by whitespace) and nothing else.
grep -rnE '^```[[:space:]]*$' --include='*.md' . \
  | awk -F: '{
      # Toggle: every untagged fence is a candidate. Authors should review each hit.
      print $0
    }'
```

Note: the grep above flags BOTH opening and closing fences. Closing fences are legitimate. To narrow to opening fences only, pair fences in order — odd-indexed hits (1st, 3rd, 5th, ...) within a file are openings:

```bash
for f in $(find . -name '*.md' -not -path './node_modules/*'); do
  awk '
    /^```[[:space:]]*$/ {
      count++
      if (count % 2 == 1) { print FILENAME ":" NR ": untagged opening fence" }
      next
    }
    /^```[a-zA-Z]/ { count++; next }
  ' "$f"
done
```

## Fence-language-tag probe — PowerShell

```powershell
# Flag opening fences that have no language tag.
Get-ChildItem -Recurse -Filter '*.md' -Exclude 'node_modules' | ForEach-Object {
    $file = $_.FullName
    $count = 0
    $lineNo = 0
    Get-Content -LiteralPath $file | ForEach-Object {
        $lineNo++
        if ($_ -match '^```[a-zA-Z]') { $count++; return }
        if ($_ -match '^```\s*$') {
            $count++
            if ($count % 2 -eq 1) { "${file}:${lineNo}: untagged opening fence" }
        }
    }
}
```

## Characters to watch for

Each row is the canonical Unicode codepoint; the ASCII fix follows the arrow:

| Smart | Codepoint | ASCII fix |
|---|---|---|
| `…` (ellipsis) | U+2026 | `...` |
| `"` (left double quote) | U+201C | `"` |
| `"` (right double quote) | U+201D | `"` |
| `'` (left single quote) | U+2018 | `'` |
| `'` (right single quote) | U+2019 | `'` |
| `–` (en dash) | U+2013 | `-` |
| `—` (em dash) | U+2014 | `-` (or rephrase) |

Smart punctuation in prose outside code blocks is fine and often correct. The sweep is scoped to fenced code only because that is where it breaks downstream tooling.

## Recognised language tags

Use a real language identifier on every fence. Common tags:

| Tag | Use for |
|---|---|
| `bash`, `sh` | POSIX shell snippets |
| `powershell`, `pwsh` | PowerShell snippets |
| `python` | Python code |
| `json` | JSON config or payloads |
| `yaml` | YAML (including frontmatter examples) |
| `markdown`, `md` | Markdown samples (including SKILL.md templates) |
| `text` | Generic plain text where no language applies (last resort) |

When the content genuinely has no language (e.g. a diagram-ish tree), `text` is acceptable but rarely correct — most "no language" fences are actually shell, YAML, or markdown and should be tagged accordingly.
