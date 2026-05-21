# Real-Time Activation Patterns

Reference for triggering actions based on Data Cloud events: Flow automation, Agentforce, and Reverse ETL.

## Pattern 1: Flow Automation Based on Data Cloud Events

**Use Case:** Trigger Flow when customer behavior detected in Data Cloud.

```text
Data Cloud Calculated Insight: "High-Value Customer at Risk"
- Logic: Purchase frequency decreased by 50% in last 30 days
- Trigger: When insight calculated
↓
Platform Event: HighValueCustomerRisk__e
↓
Salesforce Flow: "Retain High-Value Customer"
- Create Task for Account Manager
- Send personalized offer via Marketing Cloud
- Add to "At-Risk" campaign
- Log activity timeline
```

### Apex Implementation

```apex
// Subscribe to Data Cloud insights
trigger DataCloudInsightTrigger on HighValueCustomerRisk__e (after insert) {
    List<Task> tasks = new List<Task>();

    for (HighValueCustomerRisk__e event : Trigger.new) {
        // Create retention task
        Task task = new Task(
            Subject = 'Urgent: High-value customer at risk',
            Description = 'Customer ' + event.CustomerName__c +
                         ' shows declining engagement. Take action.',
            WhatId = event.AccountId__c,
            Priority = 'High',
            Status = 'Open',
            ActivityDate = Date.today().addDays(1)
        );
        tasks.add(task);

        // Trigger retention campaign
        RetentionCampaignService.addToRetentionCampaign(
            event.CustomerId__c,
            event.RiskScore__c
        );
    }

    if (!tasks.isEmpty()) {
        insert tasks;
    }
}
```

## Pattern 2: Agentforce with Data Cloud

**Use Case:** AI agent uses Data Cloud for complete customer context.

```apex
public class AgentforceDataCloudActions {
    @InvocableMethod(label='Get Customer 360 Profile')
    public static List<CustomerProfile> getCustomer360(List<String> customerIds) {
        List<CustomerProfile> profiles = new List<CustomerProfile>();

        for (String customerId : customerIds) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:DataCloud/v1/profile/' + customerId);
            req.setMethod('GET');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> data = (Map<String, Object>)
                    JSON.deserializeUntyped(res.getBody());

                CustomerProfile profile = new CustomerProfile();
                profile.customerId = customerId;

                // Demographics
                profile.name = (String)data.get('name');
                profile.email = (String)data.get('email');
                profile.segment = (String)data.get('segment');

                // Behavioral
                profile.totalPurchases = (Decimal)data.get('total_purchases');
                profile.avgOrderValue = (Decimal)data.get('avg_order_value');
                profile.lastPurchaseDate = Date.valueOf((String)data.get('last_purchase_date'));
                profile.preferredChannel = (String)data.get('preferred_channel');

                // Engagement
                profile.emailEngagement = (Decimal)data.get('email_engagement_score');
                profile.websiteVisits = (Integer)data.get('website_visits_30d');
                profile.supportCases = (Integer)data.get('support_cases_90d');

                // Predictive
                profile.churnRisk = (Decimal)data.get('churn_risk_score');
                profile.lifetimeValue = (Decimal)data.get('predicted_lifetime_value');
                profile.nextBestAction = (String)data.get('next_best_action');

                profiles.add(profile);
            }
        }

        return profiles;
    }

    public class CustomerProfile {
        @InvocableVariable public String customerId;
        @InvocableVariable public String name;
        @InvocableVariable public String email;
        @InvocableVariable public String segment;
        @InvocableVariable public Decimal totalPurchases;
        @InvocableVariable public Decimal avgOrderValue;
        @InvocableVariable public Date lastPurchaseDate;
        @InvocableVariable public String preferredChannel;
        @InvocableVariable public Decimal emailEngagement;
        @InvocableVariable public Integer websiteVisits;
        @InvocableVariable public Integer supportCases;
        @InvocableVariable public Decimal churnRisk;
        @InvocableVariable public Decimal lifetimeValue;
        @InvocableVariable public String nextBestAction;
    }
}
```

## Pattern 3: Reverse ETL (Data Cloud → External Systems)

**Use Case:** Push enriched Data Cloud data back to external systems.

### Configuration

```text
Data Cloud → Data Actions → Create Data Action
- Target: External API endpoint
- Trigger: Segment membership change, insight calculated
- Payload: Customer profile fields
- Authentication: Named Credential
- Schedule: Real-time or batch
```

### Apex Outbound Sync

```apex
public class DataCloudReverseETL {
    @InvocableMethod(label='Sync Enriched Profile to External System')
    public static void syncToExternalSystem(List<String> customerIds) {
        for (String customerId : customerIds) {
            Map<String, Object> profile = DataCloudService.getProfile(customerId);

            Map<String, Object> payload = new Map<String, Object>{
                'customer_id' => customerId,
                'segment' => profile.get('segment'),
                'lifetime_value' => profile.get('ltv'),
                'churn_risk' => profile.get('churn_risk'),
                'next_best_product' => profile.get('next_best_product')
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ExternalCRM/api/customers/' + customerId);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            DataCloudSyncLog__c log = new DataCloudSyncLog__c(
                CustomerId__c = customerId,
                Direction__c = 'Outbound',
                Success__c = res.getStatusCode() == 200,
                Timestamp__c = System.now()
            );
            insert log;
        }
    }
}
```

## Calculated Insights and Segmentation

### Create Calculated Insights

```sql
-- Example: Customer Lifetime Value
CREATE CALCULATED INSIGHT customer_lifetime_value AS
SELECT
    customer_id,
    SUM(order_total) as total_revenue,
    COUNT(order_id) as total_orders,
    AVG(order_total) as avg_order_value,
    DATEDIFF(day, first_order_date, CURRENT_DATE) as customer_age_days,
    SUM(order_total) / NULLIF(DATEDIFF(day, first_order_date, CURRENT_DATE), 0) * 365 as annual_revenue,
    (SUM(order_total) / NULLIF(DATEDIFF(day, first_order_date, CURRENT_DATE), 0) * 365) * 5 as predicted_ltv_5yr
FROM unified_orders
GROUP BY customer_id, first_order_date
```

### Dynamic Segmentation

```sql
-- Segment: High-Value Active Customers
CREATE SEGMENT high_value_active_customers AS
SELECT customer_id
FROM customer_360_profile
WHERE
    predicted_ltv_5yr > 10000
    AND last_purchase_date >= CURRENT_DATE - INTERVAL '30' DAY
    AND email_engagement_score > 0.7
    AND churn_risk_score < 0.3
```

### Use in Salesforce

```apex
List<Contact> highValueContacts = [
    SELECT Id, Name, Email
    FROM Contact
    WHERE Id IN (
        SELECT ContactId__c
        FROM DataCloudSegmentMember__c
        WHERE SegmentName__c = 'high_value_active_customers'
    )
];
```

## Data Cloud SQL (ANSI SQL Support)

Query Data Cloud using standard SQL:

```sql
-- Complex analytical query across multiple sources
SELECT
    c.customer_id,
    c.name,
    c.segment,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.order_total) as revenue,
    AVG(s.satisfaction_score) as avg_satisfaction,
    MAX(o.order_date) as last_order_date
FROM
    unified_customer c
    INNER JOIN unified_orders o ON c.customer_id = o.customer_id
    LEFT JOIN support_interactions s ON c.customer_id = s.customer_id
WHERE
    o.order_date >= CURRENT_DATE - INTERVAL '90' DAY
GROUP BY
    c.customer_id, c.name, c.segment
HAVING
    COUNT(DISTINCT o.order_id) >= 3
ORDER BY
    revenue DESC
LIMIT 100
```
