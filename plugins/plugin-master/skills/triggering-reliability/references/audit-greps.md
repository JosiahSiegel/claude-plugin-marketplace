# Triggering-reliability audit greps — extended reference

Full multi-line audit and validation sweeps referenced from `SKILL.md` under **Audit process for an existing plugin** and **Validation: what good looks like**. Run from the repo root, in priority order — earlier items have larger blast radius. Every row of output is a triggering bug.

## Audit sweep (P0 → P2)

On bash/macOS/Linux:

```bash
# 1. Find skills with no frontmatter (BROKEN, P0)
for f in plugins/*/skills/*/SKILL.md; do
  head -1 "$f" | grep -q "^---" || echo "NO FRONTMATTER: $f"
done

# 2. Find agents still using deprecated agent: true (P0)
grep -rn "^agent: true" plugins/*/agents/*.md

# 3. Find agents missing example blocks (P1)
for f in plugins/*/agents/*.md; do
  grep -q "<example>" "$f" || echo "NO EXAMPLES: $f"
done

# 4. Find skills missing PROACTIVELY activate for: (P1)
for f in plugins/*/skills/*/SKILL.md; do
  head -20 "$f" | grep -q "PROACTIVELY activate for:" || echo "NO ENUMERATION: $f"
done

# 5. Find skills missing Provides: (P1)
for f in plugins/*/skills/*/SKILL.md; do
  head -20 "$f" | grep -q "Provides:" || echo "NO PROVIDES: $f"
done

# 6. Find agents missing model: inherit (P2)
for f in plugins/*/agents/*.md; do
  head -20 "$f" | grep -q "^model: inherit" || echo "NO MODEL INHERIT: $f"
done

# 7. Find Windows boilerplate inside YAML descriptions (P0)
grep -rn "MANDATORY: Always Use Backslashes" plugins/*/agents/*.md plugins/*/skills/*/SKILL.md
```

On PowerShell (Windows):

```powershell
# 1. Skills with no frontmatter
Get-ChildItem -Recurse -Path plugins -Filter SKILL.md | ForEach-Object {
    $first = (Get-Content -LiteralPath $_.FullName -TotalCount 1)
    if ($first -notmatch '^---') { "NO FRONTMATTER: $($_.FullName)" }
}

# 2. Deprecated agent: true
Get-ChildItem -Recurse -Path plugins -Filter *.md `
  | Where-Object { $_.FullName -match '\\agents\\' } `
  | Select-String -Pattern '^agent: true'

# 3. Agents missing <example>
Get-ChildItem -Recurse -Path plugins -Filter *.md `
  | Where-Object { $_.FullName -match '\\agents\\' } `
  | ForEach-Object {
      if (-not (Select-String -Path $_.FullName -Pattern '<example>' -Quiet)) {
          "NO EXAMPLES: $($_.FullName)"
      }
  }

# 4. Skills missing PROACTIVELY activate for:
Get-ChildItem -Recurse -Path plugins -Filter SKILL.md | ForEach-Object {
    $head = Get-Content -LiteralPath $_.FullName -TotalCount 20
    if (-not ($head -match 'PROACTIVELY activate for:')) {
        "NO ENUMERATION: $($_.FullName)"
    }
}

# 5. Skills missing Provides:
Get-ChildItem -Recurse -Path plugins -Filter SKILL.md | ForEach-Object {
    $head = Get-Content -LiteralPath $_.FullName -TotalCount 20
    if (-not ($head -match 'Provides:')) {
        "NO PROVIDES: $($_.FullName)"
    }
}

# 6. Agents missing model: inherit
Get-ChildItem -Recurse -Path plugins -Filter *.md `
  | Where-Object { $_.FullName -match '\\agents\\' } `
  | ForEach-Object {
      $head = Get-Content -LiteralPath $_.FullName -TotalCount 20
      if (-not ($head -match '^model: inherit')) {
          "NO MODEL INHERIT: $($_.FullName)"
      }
  }

# 7. Windows boilerplate inside YAML descriptions
Get-ChildItem -Recurse -Path plugins -Include *.md `
  | Where-Object { $_.FullName -match '\\(agents|skills)\\' } `
  | Select-String -Pattern 'MANDATORY: Always Use Backslashes'
```

## Validation: positive signal

After fixes, all seven sweeps above should produce zero output (or, for items 4 and 5, the count should trend dramatically toward zero as skills are rewritten).

For a positive signal, confirm:

On bash/macOS/Linux:

```bash
# Count agents with example blocks (should equal total agent count)
grep -l "<example>" plugins/*/agents/*.md | wc -l

# Count skills with PROACTIVELY enumeration
grep -l "PROACTIVELY activate for:" plugins/*/skills/*/SKILL.md | wc -l
```

On PowerShell (Windows):

```powershell
# Count agents with example blocks
(Get-ChildItem -Recurse -Path plugins -Filter *.md `
   | Where-Object { $_.FullName -match '\\agents\\' } `
   | Select-String -Pattern '<example>' -List).Count

# Count skills with PROACTIVELY enumeration
(Get-ChildItem -Recurse -Path plugins -Filter SKILL.md `
   | Select-String -Pattern 'PROACTIVELY activate for:' -List).Count
```
