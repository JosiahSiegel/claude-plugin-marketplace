# TMDL / TOM Scripting from Python (Fabric Notebooks)

As of 2026, the canonical Python path for scripting semantic models is the `semantic-link-labs` library (formerly `sempy_labs`), which runs natively in Microsoft Fabric notebooks and wraps the Tabular Object Model (TOM) in Pythonic context managers. It eliminates the need to manually import .NET assemblies via `pythonnet` (although that still works) and handles authentication implicitly when executed inside a Fabric workspace.

This reference shows complete, working recipes for every common TMDL/TOM authoring task from a Fabric Python notebook.

## Installation and Imports

```python
%pip install semantic-link-labs -q

import sempy.fabric as fabric
import sempy_labs as labs
from sempy_labs.tom import connect_semantic_model
```

Inside a Fabric notebook, `semantic-link` is preinstalled (Spark 3.4+). Only `semantic-link-labs` needs the `%pip install`. Both packages are published by Microsoft.

## Connecting and the TOM Wrapper

`connect_semantic_model` is a context manager that:

1. Opens a TOM connection to the named semantic model in the workspace
2. Exposes a `TOMWrapper` instance (referred to below as `tom`) with shortcut methods
3. Calls `SaveChanges()` on context exit unless `readonly=True`

```python
with connect_semantic_model(
    dataset="SalesModel",
    workspace="Sales-Dev",
    readonly=False,
) as tom:
    # scripting goes here
    pass
# Changes are saved automatically on exit
```

Pass `readonly=True` when you only want to inspect the model (e.g., list measures, export TMDL) without risking mutation.

## Adding and Updating Measures

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    # Simple measure
    tom.add_measure(
        table_name="Sales",
        measure_name="Sales Amount",
        expression="SUM(Sales[Amount])",
        format_string="$ #,##0.00",
        display_folder="Revenue",
        description="Total sales revenue",
    )

    # YoY measure with multi-line DAX
    yoy_dax = """
    VAR CurrentSales = [Sales Amount]
    VAR PYSales = CALCULATE([Sales Amount], SAMEPERIODLASTYEAR('Calendar'[Date]))
    RETURN DIVIDE(CurrentSales - PYSales, PYSales)
    """
    tom.add_measure(
        table_name="Sales",
        measure_name="YoY Growth %",
        expression=yoy_dax,
        format_string="0.00%",
        display_folder="Growth",
    )

    # Update an existing measure
    measure = tom.model.Tables["Sales"].Measures["Sales Amount"]
    measure.Expression = "SUMX(Sales, Sales[Quantity] * Sales[Unit Price])"
    measure.Description = "Recalculated from quantity * unit price"
```

## Adding Calculation Groups

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    tom.add_calculation_group(
        name="Time Intelligence",
        precedence=1,
        description="Time intelligence calc group",
    )

    tom.add_calculation_item(
        table_name="Time Intelligence",
        calculation_item_name="Current",
        expression="SELECTEDMEASURE()",
        ordinal=0,
    )

    tom.add_calculation_item(
        table_name="Time Intelligence",
        calculation_item_name="YTD",
        expression="CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date]))",
        ordinal=1,
    )

    tom.add_calculation_item(
        table_name="Time Intelligence",
        calculation_item_name="PY",
        expression="CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))",
        ordinal=2,
    )

    tom.add_calculation_item(
        table_name="Time Intelligence",
        calculation_item_name="YoY %",
        expression="""
            VAR C = SELECTEDMEASURE()
            VAR P = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))
            RETURN DIVIDE(C - P, P)
        """,
        format_string_expression='"0.00%"',
        ordinal=3,
    )
```

## Incremental Refresh Policy

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Prod") as tom:
    tom.add_incremental_refresh_policy(
        table_name="Sales",
        column_name="OrderDate",
        start_date="2020-01-01T00:00:00",
        end_date="2025-12-31T00:00:00",
        incremental_granularity="Day",
        incremental_periods=30,
        rolling_window_granularity="Month",
        rolling_window_periods=36,
        only_refresh_complete_days=True,
        detect_data_changes_column=None,
    )

    # Inspect the result
    print(tom.model.Tables["Sales"].RefreshPolicy)
```

## Row-Level Security (RLS)

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    tom.add_role(role_name="RegionalManager", description="RLS for regional managers")

    tom.set_rls(
        role_name="RegionalManager",
        table_name="Sales",
        filter_expression="Sales[Region] = USERPRINCIPALNAME()",
    )

    tom.set_rls(
        role_name="RegionalManager",
        table_name="Sales Targets",
        filter_expression="'Sales Targets'[Region] = USERPRINCIPALNAME()",
    )
```

Role members (users/groups) are managed at the dataset-permission level, not via TOM. Use the `fabric` REST API to add users to roles:

```python
fabric.add_user_to_role(
    workspace="Sales-Dev",
    dataset="SalesModel",
    role="RegionalManager",
    user_principal_name="alice@contoso.com",
)
```

## Object-Level Security (OLS)

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    tom.set_ols(
        role_name="RegionalManager",
        table_name="Sales",
        column_name="Unit Cost",
        permission="None",  # "None" = hide column from role
    )
```

## Adding Relationships

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    tom.add_relationship(
        from_table="Sales",
        from_column="Product Key",
        to_table="Product",
        to_column="Product Key",
        from_cardinality="Many",
        to_cardinality="One",
        cross_filtering_behavior="OneDirection",
        is_active=True,
    )

    # Bidirectional bridge
    tom.add_relationship(
        from_table="Bridge Table",
        from_column="Tag Id",
        to_table="Tags",
        to_column="Tag Id",
        from_cardinality="Many",
        to_cardinality="Many",
        cross_filtering_behavior="BothDirections",
    )
```

## Direct Lake Connections

```python
with connect_semantic_model(dataset="DirectLakeModel", workspace="Analytics-Prod") as tom:
    # Switch Direct Lake fallback behavior
    tom.set_direct_lake_behavior(direct_lake_behavior="Automatic")
    # Options: "Automatic", "DirectLakeOnly", "DirectQueryOnly"
```

Or update the Direct Lake source at the model level:

```python
labs.update_direct_lake_model_connection(
    dataset="DirectLakeModel",
    workspace="Analytics-Prod",
    source_type="Lakehouse",  # or "Warehouse"
    source_workspace="Data-Platform",
    source=".Lakehouse",
)
```

## Best Practice Analyzer (BPA)

```python
# Run the Microsoft BPA ruleset against a model
bpa_results = labs.run_model_bpa(
    dataset="SalesModel",
    workspace="Sales-Dev",
    export=False,
    language="en-US",
)
display(bpa_results)

# Report-level BPA
report_bpa = labs.run_report_bpa(
    report="SalesReport",
    workspace="Sales-Dev",
)
display(report_bpa)
```

`run_model_bpa` produces a pandas DataFrame listing each BPA rule violation with rule name, severity, object, and description -- ideal for CI gates inside a notebook-based pipeline.

## Export / Import Model as TMDL

```python
# Export a live workspace model to a TMDL folder in the Fabric notebook attached Lakehouse
labs.export_model_to_tmdl(
    dataset="SalesModel",
    workspace="Sales-Dev",
    path="/lakehouse/default/Files/tmdl_export/SalesModel",
)

# Deploy a TMDL folder back into a target workspace
labs.deploy_semantic_model(
    source_dataset="SalesModel",
    source_workspace="Sales-Dev",
    target_dataset="SalesModel",
    target_workspace="Sales-Prod",
    refresh_target_dataset=False,
)
```

## Reading Model Metadata with DAX INFO Functions

For read-only model introspection (listing measures, columns, relationships), prefer DAX INFO functions via `fabric.evaluate_dax` over TOM:

```python
import sempy.fabric as fabric

measures_df = fabric.evaluate_dax(
    dataset="SalesModel",
    workspace="Sales-Dev",
    dax_string="EVALUATE INFO.MEASURES()",
)
display(measures_df)

columns_df = fabric.evaluate_dax(
    dataset="SalesModel",
    workspace="Sales-Dev",
    dax_string="EVALUATE INFO.COLUMNS()",
)
display(columns_df)
```

INFO functions (INFO.MEASURES, INFO.COLUMNS, INFO.TABLES, INFO.RELATIONSHIPS, INFO.CALCULATIONGROUPS, INFO.CALCULATIONITEMS, INFO.ROLES, etc.) are the 2026-preferred alternative to DMV queries and are fully supported in Power BI, Fabric, AAS, and SQL 2025 AS.

## Low-Level: Raw TOM via pythonnet (Fallback)

When `semantic-link-labs` does not expose a needed TOM property, drop down to raw TOM inside the same context:

```python
with connect_semantic_model(dataset="SalesModel", workspace="Sales-Dev") as tom:
    # tom.model is the raw Microsoft.AnalysisServices.Tabular.Model
    from Microsoft.AnalysisServices.Tabular import Annotation

    annotation = Annotation()
    annotation.Name = "CustomMetadata"
    annotation.Value = '{"owner":"data-team","refreshSchedule":"daily"}'
    tom.model.Tables["Sales"].Annotations.Add(annotation)
```

All TOM classes under `Microsoft.AnalysisServices.Tabular` are reachable because `semantic-link-labs` has already loaded the assemblies.

## CI Gate Pattern: BPA Failure Blocks Deployment

```python
import sys

results = labs.run_model_bpa(
    dataset="SalesModel",
    workspace="Sales-Dev",
    language="en-US",
)

critical = results[results["Severity"] == "Error"]
if len(critical) > 0:
    display(critical)
    raise RuntimeError(f"BPA blocked deployment: {len(critical)} Error-severity violations")

# Proceed with deployment
labs.deploy_semantic_model(
    source_dataset="SalesModel",
    source_workspace="Sales-Dev",
    target_dataset="SalesModel",
    target_workspace="Sales-Prod",
)
```

Run this notebook on a schedule or from a pipeline job (`runMultiple` / Fabric Data Pipeline -> Notebook activity) to gate deployments on BPA.

## Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `RuntimeError: readonly model` when saving | `readonly=True` passed to context manager | Set `readonly=False` (default) |
| Changes not persisting after context exit | Exception raised inside `with` block | Ensure block completes without exceptions; wrap risky operations in try/except |
| `add_measure` fails with "already exists" | Measure name collision | Use `tom.remove_object(tom.model.Tables["X"].Measures["Y"])` first, or update `Expression` directly |
| `Direct Lake fallback not supported` | Model is Import or DirectQuery mode | Direct Lake APIs only apply to Direct Lake models |
| `CopyTo` fails on XMLA target | Model size exceeds capacity limit | Use `deploy_semantic_model` with `overwrite=True`, or export TMDL and redeploy |
| Notebook runtime too old | Spark 3.3 or earlier | Use Fabric runtime 1.3+ (Spark 3.5) -- semantic-link-labs requires Fabric Spark 3.4+ |

## References

- [semantic-link-labs on GitHub](https://github.com/microsoft/semantic-link-labs) -- source and release notes
- [semantic-link-labs on PyPI](https://pypi.org/project/semantic-link-labs/) -- latest version
- [sempy.fabric package reference](https://learn.microsoft.com/en-us/python/api/semantic-link-sempy/sempy.fabric) -- lower-level SemPy API
- [Semantic link overview](https://learn.microsoft.com/en-us/fabric/data-science/semantic-link-overview)
