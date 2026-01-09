---
name: Setup Schedule
description: Set up scheduled and cron functions with timezone support
argument-hint: "<cron-expression|period> [timezone]"
---

# Modal Schedule Command

Set up scheduled and cron functions with timezone support.

## Task

Help configure scheduled Modal functions with:

1. **Schedule Type Selection**
   - Cron expressions for specific times
   - Period-based for intervals

2. **Timezone Configuration**
   - UTC vs local timezone
   - Daylight saving handling

3. **Best Practices**
   - Error handling and retries
   - Monitoring and logging
   - Resource configuration

## Schedule Types

### Cron Expressions

```python
import modal

app = modal.App("scheduled-app")

# Daily at 8 AM UTC
@app.function(schedule=modal.Cron("0 8 * * *"))
def daily_job():
    print("Running daily job")

# With timezone
@app.function(schedule=modal.Cron("0 6 * * *", timezone="America/New_York"))
def daily_eastern():
    print("Running at 6 AM Eastern")

# Every Monday at 9 AM
@app.function(schedule=modal.Cron("0 9 * * 1"))
def weekly_report():
    generate_report()

# First day of month at midnight
@app.function(schedule=modal.Cron("0 0 1 * *"))
def monthly_cleanup():
    cleanup_old_data()

# Every 15 minutes
@app.function(schedule=modal.Cron("*/15 * * * *"))
def frequent_check():
    check_status()

# Weekdays at 9 AM
@app.function(schedule=modal.Cron("0 9 * * 1-5"))
def weekday_job():
    pass

# Multiple times per day
@app.function(schedule=modal.Cron("0 8,12,18 * * *"))
def three_times_daily():
    pass
```

### Period-Based Scheduling

```python
# Every 5 hours
@app.function(schedule=modal.Period(hours=5))
def periodic_job():
    pass

# Every 2 days
@app.function(schedule=modal.Period(days=2))
def bi_daily_job():
    pass

# Every 30 minutes
@app.function(schedule=modal.Period(minutes=30))
def half_hourly():
    pass
```

## Cron Syntax Reference

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
* * * * *
```

**Special Characters:**
- `*` - Any value
- `,` - Value list (1,3,5)
- `-` - Range (1-5)
- `/` - Step (*/15 = every 15)

**Common Patterns:**
| Pattern | Meaning |
|---------|---------|
| `0 * * * *` | Every hour |
| `0 0 * * *` | Daily at midnight |
| `0 0 * * 0` | Weekly on Sunday |
| `0 0 1 * *` | Monthly on 1st |
| `*/5 * * * *` | Every 5 minutes |
| `0 9-17 * * 1-5` | Hourly, 9-5, Mon-Fri |

## Complete Example: Data Pipeline

```python
import modal
from datetime import datetime

app = modal.App("data-pipeline")

vol = modal.Volume.from_name("pipeline-data", create_if_missing=True)

@app.function(
    schedule=modal.Cron("0 6 * * *", timezone="America/New_York"),
    secrets=[modal.Secret.from_name("database")],
    volumes={"/data": vol},
    timeout=3600,  # 1 hour max
    retries=3,
)
def daily_etl():
    import os

    print(f"Starting ETL at {datetime.now()}")

    try:
        # Extract
        db_url = os.environ["DATABASE_URL"]
        data = extract_from_database(db_url)
        print(f"Extracted {len(data)} records")

        # Transform
        transformed = transform_data(data)
        print(f"Transformed {len(transformed)} records")

        # Load
        output_path = f"/data/output_{datetime.now().strftime('%Y%m%d')}.parquet"
        save_to_parquet(transformed, output_path)
        vol.commit()

        # Notify success
        send_notification(f"ETL completed: {len(transformed)} records")

        return {"status": "success", "records": len(transformed)}

    except Exception as e:
        send_alert(f"ETL failed: {str(e)}")
        raise
```

## Example: Health Monitoring

```python
import modal

app = modal.App("health-monitor")

@app.function(
    schedule=modal.Cron("*/5 * * * *"),  # Every 5 minutes
    secrets=[modal.Secret.from_name("monitoring")],
)
def health_check():
    import os
    import requests

    endpoints = [
        "https://api.example.com/health",
        "https://app.example.com/health",
    ]

    results = []
    for endpoint in endpoints:
        try:
            response = requests.get(endpoint, timeout=10)
            results.append({
                "endpoint": endpoint,
                "status": response.status_code,
                "healthy": response.status_code == 200
            })
        except Exception as e:
            results.append({
                "endpoint": endpoint,
                "status": "error",
                "error": str(e),
                "healthy": False
            })

    # Alert on failures
    unhealthy = [r for r in results if not r["healthy"]]
    if unhealthy:
        send_alert(unhealthy)

    return results
```

## Example: Cleanup Job

```python
import modal
from datetime import datetime, timedelta

app = modal.App("cleanup")

vol = modal.Volume.from_name("data-volume")

@app.function(
    schedule=modal.Cron("0 2 * * *"),  # 2 AM daily
    volumes={"/data": vol},
)
def cleanup_old_files():
    import os

    cutoff = datetime.now() - timedelta(days=30)
    deleted = 0

    for root, dirs, files in os.walk("/data"):
        for file in files:
            path = os.path.join(root, file)
            mtime = datetime.fromtimestamp(os.path.getmtime(path))
            if mtime < cutoff:
                os.remove(path)
                deleted += 1

    vol.commit()
    print(f"Deleted {deleted} files older than 30 days")
    return {"deleted": deleted}
```

## Important Notes

1. **Deployment Required**: Scheduled functions only run when deployed with `modal deploy`, not with `modal run`

2. **Test First**: Always test with `modal run app.py::function_name` before deploying

3. **Timezone Handling**: Use explicit timezone to avoid DST issues

4. **Error Handling**: Always wrap in try/except and send alerts on failure

5. **Idempotency**: Design jobs to be safely re-runnable

6. **Logging**: Include timestamps and progress logging

7. **Timeouts**: Set appropriate timeout for long-running jobs

## Deployment

```bash
# Test the function manually
modal run app.py::daily_etl

# Deploy for scheduled execution
modal deploy app.py

# Check scheduled functions
modal app list

# View execution logs
modal app logs data-pipeline --follow
```

## Monitoring

- Check Modal dashboard for execution history
- Set up alerts for failed runs
- Monitor execution duration
- Track error rates

## Troubleshooting

1. **Job not running**: Verify deployed with `modal deploy`
2. **Wrong time**: Check timezone configuration
3. **Timeout**: Increase timeout parameter
4. **Failures**: Check logs with `modal app logs`
5. **Missed runs**: Review execution history in dashboard
