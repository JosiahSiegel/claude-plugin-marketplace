# Power BI Gotchas and Pitfalls - Deep Dive

## 1. Auto Date/Time Overhead

**Problem:** Power BI Desktop creates a hidden date table for every date/time column in the model. Each hidden table contains a full calendar hierarchy (Year, Quarter, Month, Day) consuming memory.

**Impact:** A model with 20 date columns gets 20 hidden date tables. Can add 100MB+ to model size.

**Fix:**
1. File > Options > Data Load > uncheck "Auto date/time for new files"
2. Current file > Options > Current File > Data Load > uncheck "Auto date/time"
3. Create ONE explicit Date dimension table:

```dax
Date =
ADDCOLUMNS(
    CALENDARAUTO(),
    "Year", YEAR([Date]),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "Month", FORMAT([Date], "MMMM"),
    "MonthNumber", MONTH([Date]),
    "YearMonth", FORMAT([Date], "YYYY-MM"),
    "WeekDay", FORMAT([Date], "dddd"),
    "WeekDayNumber", WEEKDAY([Date], 2),
    "IsWeekend", IF(WEEKDAY([Date], 2) > 5, TRUE, FALSE)
)
```

4. Mark it as a Date table: select table > Table tools > Mark as date table

## 2. Bidirectional Cross-Filtering

**Problem:** Setting cross-filter direction to "Both" causes filters to flow in both directions across a relationship. This creates ambiguous paths when multiple relationships exist.

**Impact:**
- Wrong aggregation results with no error message
- Significant performance degradation (filter propagation explodes)
- Unexpected row counts in visuals
- Security filters (RLS) may not propagate correctly

**When it seems needed:** Typically for "many-to-many" slicer scenarios.

**Fix:** Use DAX CROSSFILTER() or TREATAS() instead:
```dax
Sales by Selected Category =
CALCULATE(
    [Total Sales],
    TREATAS(VALUES(CategoryBridge[CategoryID]), Sales[CategoryID])
)
```

## 3. Implicit vs Explicit Measures

**Problem:** Dragging a numeric column directly to a visual creates an "implicit measure" with a default aggregation (usually SUM). These cannot be reused, formatted consistently, or used in complex calculations.

**Impact:**
- Inconsistent calculations across visuals
- No formula bar showing the logic
- Cannot reference in other DAX expressions
- Field list clutter
- Governance nightmare in large models

**Fix:** ALWAYS create explicit measures:
```dax
// BAD: Dragging Revenue column and setting to "Sum"
// GOOD: Explicit measure
Total Revenue = SUM(Sales[Revenue])
```

**Best practice:** Hide numeric columns from the report view after creating measures for them. Put measures in a dedicated "Measures" display folder or a disconnected measures table.

## 4. BLANK vs Zero vs Null

**Problem:** DAX has three distinct concepts that developers conflate:

| Value | DAX Representation | Visual Behavior | Arithmetic |
|-------|-------------------|-----------------|------------|
| BLANK | BLANK() | Row hidden from visual | BLANK + 5 = 5 |
| Zero | 0 | Row shown with "0" | 0 + 5 = 5 |
| Null (from source) | Converted to BLANK | Row hidden | Same as BLANK |

**Common mistakes:**
```dax
// This returns BLANK when Sales is blank, not 0
Bad = IF(Sales[Amount] = 0, "No Sales", "Has Sales")
// BLANK <> 0, so BLANK rows show "Has Sales"!

// Correct
Good = IF(ISBLANK(Sales[Amount]) || Sales[Amount] = 0, "No Sales", "Has Sales")
```

**DIVIDE behavior:**
```dax
// DIVIDE returns BLANK (not error) on division by zero
Ratio = DIVIDE([Numerator], [Denominator])
// Returns BLANK when Denominator is 0 or BLANK

// To return 0 instead of BLANK:
Ratio = DIVIDE([Numerator], [Denominator], 0)
```

## 5. Circular Dependency Errors

**Problem:** DAX calculated columns or tables referencing each other (directly or indirectly) create a circular dependency. This also happens with bidirectional relationships combined with calculated columns.

**Common causes:**
- Calculated column A references calculated column B, which references A
- Bidirectional relationship + calculated column using RELATED()
- Row-level security filter referencing a calculated column that depends on the filtered table

**Fix:**
- Restructure calculations to avoid mutual references
- Replace calculated columns with measures where possible
- Remove bidirectional filtering
- Use EARLIER() for recursive row context scenarios

## 6. 1GB PBIX File Size Limit

**Problem:** Power BI Desktop cannot save files larger than 1GB. The Power BI Service supports up to 10GB for Premium/PPU but Desktop remains capped.

**Warning signs:** File save takes progressively longer, eventually fails.

**Strategies to reduce size:**
1. Remove unused columns (biggest impact) -- especially high-cardinality text columns
2. Reduce cardinality of text columns (group rare values into "Other")
3. Avoid calculated columns with high cardinality results
4. Disable auto date/time (see gotcha #1)
5. Use Import mode with column selection rather than SELECT *
6. Reduce decimal precision (round to 2 decimal places)
7. Move detail data to a separate model; keep summary in the report model
8. Use PBIP/PBIR format for source control (does not have the 1GB limit; large models deploy directly to service)

## 7. Gateway Refresh Failures

**Common failure patterns:**

| Error | Cause | Fix |
|-------|-------|-----|
| "The credentials provided for the data source are invalid" | Password changed/expired | Update credentials in gateway settings |
| "Unable to connect to the data source" | Network/firewall issue | Check connectivity from gateway machine |
| "The gateway is offline" | Gateway service stopped or machine down | Restart gateway service, check machine |
| "Data source not found" | Data source removed or renamed | Reconfigure data source in gateway |
| "Out of memory" | Gateway machine memory exhausted during refresh | Add RAM or optimize query to reduce memory |
| "Query timeout" | Source query exceeds timeout | Optimize query, increase timeout in source |
| "Mashup Exception" | Power Query error during refresh | Test query in Desktop, check data changes |

**Monitoring best practices:**
- Enable gateway performance monitoring (PerformanceCounters in gateway config)
- Set up alerts on refresh failures in Power BI Service
- Schedule refreshes during off-peak hours
- Use gateway cluster (multiple machines) for high availability

## 8. DirectQuery Gotchas

| Limitation | Detail |
|-----------|--------|
| No Power Query transforms | All transforms must be done in source |
| Limited DAX functions | Many iterator functions degrade or fail |
| No calculated columns | Cannot add calculated columns to DQ tables |
| 1M row limit per visual | Queries returning >1M rows are truncated |
| Report perf = source perf | Slow source = slow report, no caching |
| No table-level aggregations | Must use aggregation tables (composite models) |
| Query reduction needed | Each slicer change sends a query; enable "Apply" button |
| Connection limit | Heavy usage can overwhelm source with concurrent queries |

## 9. Power BI Service vs Desktop Feature Gaps

| Feature | Desktop | Service |
|---------|---------|---------|
| PBIR/PBIP editing | Full editing | View/deploy only |
| Paginated reports | Separate Report Builder tool | Native support |
| Email subscriptions | Not available | Available |
| Apps | Not available | Available |
| Deployment pipelines | Not available | Available (Premium/PPU/Fabric) |
| Dataflows | Not available (author in service) | Full authoring |
| Real-time streaming visuals | Not available | Available |
| XMLA endpoint | Connect via external tools | Read/Write (Premium/PPU/Fabric) |
| Git integration | Local PBIP files | Azure Repos / GitHub sync |
| Goals/Metrics | Not available | Available |
| Data Activator (alerts) | Not available | Fabric only |

## 10. Composite Model Pitfalls

**Problem:** Composite models (mixing Import + DirectQuery) introduce complexity:

- Relationships between Import and DQ tables have limited cross-filtering
- Many-to-many relationships between DQ tables can produce incorrect results
- Security context may not propagate across storage mode boundaries
- Performance varies wildly depending on which tables are queried together

**Best practice:** Use Import for dimensions, DirectQuery for large fact tables. Test thoroughly with production data volumes.

## 11. Row-Level Security (RLS) Gotchas

- RLS is NOT enforced in Power BI Desktop "Test as role" does not support dynamic RLS with USERPRINCIPALNAME() accurately
- RLS must be tested in the Power BI Service with actual user accounts
- RLS does not apply to workspace admins/members -- only viewers
- USERPRINCIPALNAME() returns the UPN, not the email (they differ in some orgs)
- Bidirectional cross-filter + RLS can fail silently -- always test combinations
- DirectQuery RLS adds WHERE clauses to every query, impacting performance

## 12. Large Semantic Model Anti-Patterns

| Anti-Pattern | Why It Hurts | Alternative |
|-------------|-------------|-------------|
| SELECT * from source | Loads unnecessary columns | SELECT only needed columns |
| Storing full timestamps | High cardinality in VertiPaq | Split into Date and Time columns |
| Text descriptions in facts | Destroys compression | Move to dimension, reference by key |
| Multiple date formats | Redundant columns | Use FORMAT() in DAX at display time |
| Pre-aggregated + detail | Redundant data | Use aggregation tables with automatic aggregation |
| Unused relationships | Memory overhead | Remove or make inactive |

## 13. Direct Lake Specific Gotchas (2025-2026)

| Pitfall | Impact | Fix |
|---------|--------|-----|
| DL/OL has no DQ fallback | Queries fail if data cannot be served from memory | Size model within capacity guardrails |
| DL/SQL fallback is silent | Performance degrades without obvious indication | Monitor Capacity Metrics app for fallback events |
| Stale framing | Report shows old data | Schedule frequent framing (metadata refresh) |
| Too many small Parquet files | Exceeds file/row-group guardrails | Run OPTIMIZE on delta tables regularly |
| Calculated columns on DL tables | May trigger DQ fallback (DL/SQL) or failure (DL/OL) | Test impact; prefer measures |
| Not enabling V-Order | Slower column reads from Parquet | Enable V-Order in Spark write configuration |
| Forgetting capacity tier limits | Max rows per table and model size vary by F-SKU | Check guardrails table for your capacity tier |

## 14. Power BI Report Server vs. Desktop/Service Gaps

| Feature | Available in Desktop | Available in Service | Available in Report Server |
|---------|:-------------------:|:-------------------:|:--------------------------:|
| PBIR format | Yes (March 2026 default) | Yes (January 2026 default) | No |
| Composite models | Yes | Yes | No |
| Sensitivity labels | Yes | Yes | No |
| R/Python visuals | Yes | Yes | No |
| Bookmarks | Yes | Yes | No |
| Dynamic M parameters | Yes | Yes | No |
| Q&A natural language | Yes | Yes | No |
| Dashboards | No | Yes | No |
| Email subscriptions (PBI) | No | Yes | No |
| Real-time streaming | No | Yes | No |
| Paginated reports | Report Builder | Yes | Yes |
| RLS | Yes (test mode) | Yes (enforced) | Yes (enforced) |
| Custom visuals | Yes | Yes | Yes |
| Mobile app | No | Yes | Yes |

**Key rule:** If a feature requires cloud infrastructure (AI, streaming, apps, dashboards), it is NOT available in Report Server. Design reports for Report Server using the intersection of Desktop and Report Server capabilities.

## 15. Workspace Identity vs. Service Principal

| Aspect | Workspace Identity | Service Principal |
|--------|-------------------|-------------------|
| Scope | Single Fabric workspace | Any workspace added to |
| Secret management | No secret (managed) | Client secret or certificate |
| Expiration | Never expires | Secret expires (1-2 years) |
| Setup | Workspace settings | Azure AD app registration |
| Best for | Fabric-native data sources | Cross-workspace automation, CI/CD |
| Availability | Fabric workspaces only | Any Power BI workspace |

## 16. PBIR Transition Gotchas (2026)

| Issue | Detail | Mitigation |
|-------|--------|------------|
| Automatic conversion | When PBIR becomes the only format, all reports convert | Test critical reports with PBIR format before cutover |
| Report Server incompatibility | PBIR not supported on Report Server | Continue using PBIX for Report Server deployments |
| Custom visual compatibility | Some older custom visuals may need updates for PBIR | Test all custom visuals in PBIR mode |
| Existing CI/CD pipelines | Tools parsing legacy report.json structure may break | Update automation to handle per-visual folder structure |
