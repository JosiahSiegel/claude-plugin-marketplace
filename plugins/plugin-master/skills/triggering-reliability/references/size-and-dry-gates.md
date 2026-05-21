# Size and DRY gates for SKILL.md authoring

This reference holds the two mandatory pre-commit checks that gate every content addition to a SKILL.md or reference file. Both gates live here (rather than in SKILL.md) to keep the parent skill under its word-count ceiling.

## Precondition: size check before adding content to an existing skill

Before adding ANY new paragraph, table, or section to an existing SKILL.md, run a word-count check. The 3,000-word ceiling is a hard limit, not an aspiration — a SKILL.md that lands at 3,050 words is broken, not "close enough."

On bash/macOS/Linux:

```bash
wc -w plugins/<plugin>/skills/<skill>/SKILL.md
```

On PowerShell (Windows):

```powershell
(Get-Content plugins/<plugin>/skills/<skill>/SKILL.md | Measure-Object -Word).Words
```

**Decision rule:**

| Current word count | Action before adding content |
|---|---|
| < 2,500 words | Safe to add. Proceed. |
| 2,500-2,799 words | Add cautiously. After the addition, re-count; if over 2,800, start planning the extraction. |
| 2,800-3,000 words (within 200 of the ceiling) | **Extraction to `references/` is mandatory BEFORE adding.** Identify the largest reference-style section (detailed table, exhaustive checklist, full sweep script) and move it to `references/<topic>.md`, leaving a one-line pointer in SKILL.md. Then add the new content. |
| > 3,000 words | The skill is already broken. Do not add anything — extract until SKILL.md is back under 2,000 words. |

This precondition prevents the common failure mode where each individual addition looks small but the skill silently crosses the ceiling.

## Mandatory DRY-gate before any content add

Cross-cutting paragraphs, tables, and checklists that get pasted into multiple files are the #1 source of plugin bloat. Before adding any block longer than ~3 lines to a SKILL.md or reference file, run this grep from the plugin root:

```bash
# Replace FIRST_DISTINCTIVE_LINE with the first distinctive line of the candidate block.
grep -rn "FIRST_DISTINCTIVE_LINE" skills/ agents/ commands/ README.md
```

On PowerShell (Windows):

```powershell
Get-ChildItem -Recurse -Path skills,agents,commands,README.md -Include *.md -ErrorAction SilentlyContinue `
  | Select-String -Pattern 'FIRST_DISTINCTIVE_LINE'
```

**Decision rule** (from `skill-development` skill, "two or more verbatim copies = extract" gate):

| grep finds the block in | Action |
|---|---|
| 0 other files | Safe to add. Proceed. |
| 1 other file (this will be the 2nd copy) | **STOP.** Extract to `skills/_shared/<topic>.md` (cross-skill) or `skills/<this-skill>/references/<topic>.md` (single-skill). Replace both call sites with a one-line pointer. |
| 2+ other files | Treat as a P1 bug. Extract immediately, then audit for further occurrences. |

This gate is mandatory, not advisory. Skipping it is the mechanism that lets identical canonical text drift into two or three files.

## Combined workflow

For any content add to an existing SKILL.md or reference:

1. Run the size check. If the file is in the 2,800-3,000 band, extract before adding.
2. Run the DRY-gate grep on the first distinctive line of the candidate block. If it shows up in even one other file, extract instead of pasting.
3. Only after both gates clear, add the content.
4. After the add, re-run the size check. If the file crossed 3,000 words, extract the largest reference-style section to bring it back under the ceiling before commit.
