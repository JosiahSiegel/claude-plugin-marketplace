---
description: Generate a DAX measure or pattern for a specific business requirement
---

# Power BI DAX Generator

Generate a DAX measure based on the user's business requirement.

## Process

1. Ask the user to describe the business metric they need (e.g., "year-over-year growth", "running total", "customer retention rate")
2. Load the `powerbi-master:dax-mastery` skill for DAX patterns
3. Generate the complete DAX measure with:
   - Proper variable usage (VAR/RETURN)
   - Safe division (DIVIDE instead of /)
   - ISBLANK/BLANK handling where appropriate
   - Comments explaining the logic
   - Format string recommendation
4. Include any prerequisites (e.g., "requires a Date table marked as date table")
5. Warn about potential gotchas

## Output Format

```dax
// [Description of what the measure calculates]
// Prerequisites: [any requirements]
[Measure Name] =
VAR ...
RETURN ...
```

Followed by:
- **Format string:** recommended format
- **Display folder:** suggested folder name
- **Notes:** any caveats or assumptions
