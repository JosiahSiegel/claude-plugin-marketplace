---
description: Review a Power BI data model for best practices, performance, and anti-patterns
---

# Power BI Model Review

Analyze a Power BI data model (TMDL, model.bim, or description) for best practices compliance.

## Process

1. Load the `powerbi-master:powerbi-core` and `powerbi-master:performance-optimization` skills
2. Ask the user to provide their model definition (TMDL, BIM JSON, or describe the tables/relationships)
3. Analyze the model against these criteria:

### Star Schema Compliance
- Fact and dimension tables properly identified
- Relationships flow from dimension (one) to fact (many)
- No snowflake patterns (dimensions should be denormalized)

### Relationship Review
- No bidirectional cross-filtering unless justified
- Only one active relationship per table pair
- Integer keys preferred for relationships
- Referential integrity set for DirectQuery

### Column Optimization
- No unused columns
- Text columns not in fact tables
- No high-cardinality columns that could be reduced
- Date/time split where appropriate

### Measure Review
- Explicit measures used (no implicit)
- DIVIDE used instead of /
- Variables used for repeated expressions
- Proper format strings assigned

### Anti-Pattern Detection
- Auto date/time enabled?
- Bidirectional relationships?
- Calculated columns that could be measures?
- Circular dependencies?

## Output Format

Provide a structured review with:
1. **Score:** Overall health (Good / Needs Improvement / Critical Issues)
2. **Issues Found:** Bulleted list with severity (Critical / Warning / Info)
3. **Recommendations:** Specific actions to fix each issue
4. **Model Diagram:** Text-based relationship diagram if possible
