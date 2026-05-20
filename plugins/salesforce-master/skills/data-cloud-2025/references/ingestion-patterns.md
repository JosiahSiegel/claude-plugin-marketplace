# Data Cloud Ingestion Patterns

Reference for real-time streaming, batch import, and Zero Copy integration with Snowflake/Databricks/BigQuery.

## Pattern 1: Real-Time Streaming with Change Data Capture

**Use Case:** Keep Data Cloud synchronized with Salesforce objects in real-time.

```apex
// Enable Change Data Capture for objects
// Setup → Change Data Capture → Select: Account, Contact, Opportunity
// Data Cloud automatically subscribes to CDC channels - no code needed

// Optional: Custom streaming logic
public class DataCloudStreamHandler {
    public static void publishCustomEvent(Id recordId, String changeType) {
        DataCloudChangeEvent__e event = new DataCloudChangeEvent__e(
            RecordId__c = recordId,
            ObjectType__c = 'Custom_Object__c',
            ChangeType__c = changeType,
            Timestamp__c = System.now(),
            PayloadJson__c = JSON.serialize(getRecordData(recordId))
        );

        EventBus.publish(event);
    }

    private static Map<String, Object> getRecordData(Id recordId) {
        String objectType = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT FIELDS(ALL) FROM ' + objectType +
                      ' WHERE Id = :recordId LIMIT 1';
        SObject record = Database.query(query);
        return (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record));
    }
}
```

## Pattern 2: Batch Import from External Systems

**Use Case:** Import data from ERP, e-commerce, or other business systems.

### Data Cloud Configuration

```text
1. Create Data Source (Setup → Data Cloud → Data Sources)
   - Type: Amazon S3, SFTP, Azure Blob, Google Cloud Storage
   - Authentication: API key, OAuth, IAM role
   - Schedule: Hourly, Daily, Weekly

2. Map to Data Model Objects (DMO)
   - Source Field → DMO Field mapping
   - Data type conversions
   - Formula fields and transformations

3. Configure Identity Resolution
   - Match rules (email, customer ID, phone)
   - Reconciliation rules (which source wins)
```

### API-Based Batch Import

```python
# Python example: Push data to Data Cloud via API
import requests
import pandas as pd

def upload_to_data_cloud(csv_file, object_name, access_token, instance_url):
    """Upload CSV to Data Cloud via Bulk API"""

    # Step 1: Create ingestion job
    job_url = f"{instance_url}/services/data/v62.0/jobs/ingest"
    job_payload = {
        "object": object_name,
        "operation": "upsert",
        "externalIdFieldName": "ExternalId__c"
    }

    response = requests.post(
        job_url,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        },
        json=job_payload
    )

    job_id = response.json()["id"]

    # Step 2: Upload CSV data
    with open(csv_file, 'rb') as f:
        csv_data = f.read()

    upload_url = f"{job_url}/{job_id}/batches"
    requests.put(
        upload_url,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "text/csv"
        },
        data=csv_data
    )

    # Step 3: Close job
    close_url = f"{job_url}/{job_id}"
    requests.patch(
        close_url,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        },
        json={"state": "UploadComplete"}
    )

    return job_id
```

## Pattern 3: Zero Copy Integration (Snowflake, Databricks)

**Use Case:** Access data warehouse data without copying to Salesforce.

**Benefits:**
- No data duplication (single source of truth)
- No data transfer costs
- Real-time access to warehouse data
- Maintain data governance in warehouse

### Snowflake Zero Copy Setup

```sql
-- In Snowflake: Grant access to Salesforce
GRANT USAGE ON DATABASE customer_data TO ROLE salesforce_role;
GRANT USAGE ON SCHEMA customer_data.public TO ROLE salesforce_role;
GRANT SELECT ON TABLE customer_data.public.orders TO ROLE salesforce_role;

-- Create secure share
CREATE SHARE salesforce_data_share;
GRANT USAGE ON DATABASE customer_data TO SHARE salesforce_data_share;
ALTER SHARE salesforce_data_share ADD ACCOUNTS = 'SALESFORCE_ORG_ID';
```

### Data Cloud Configuration

```text
1. Add Zero Copy Connector (Data Cloud → Data Sources)
   - Type: Snowflake Zero Copy
   - Connection: Account URL, username, private key
   - Database/Schema selection

2. Create Data Stream (virtual tables)
   - Select Snowflake tables to expose
   - Map to DMO or keep as is
   - Configure refresh (real-time or scheduled)

3. Query in Salesforce
   - Use SOQL-like syntax to query Snowflake data
   - Join with Salesforce data
   - No data movement required
```

### Query Zero Copy Data from Apex

```apex
public class DataCloudZeroCopyQuery {
    public static List<Map<String, Object>> querySnowflakeOrders(String customerId) {
        String query = 'SELECT order_id, total_amount, order_date ' +
                      'FROM snowflake_orders ' +
                      'WHERE customer_id = \'' + customerId + '\' ' +
                      'ORDER BY order_date DESC LIMIT 10';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DataCloud/v1/query');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{'query' => query}));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (List<Map<String, Object>>)result.get('data');
        }

        return new List<Map<String, Object>>();
    }
}
```
