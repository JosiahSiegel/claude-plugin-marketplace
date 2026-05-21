# Hyperforce Migration and Developer Workflow

Detailed Hyperforce migration phases, readiness checks, pre/post-migration testing, rollback considerations, developer workflow changes, CLI/API notes, sandbox strategy, endpoint handling, and deployment considerations. SKILL.md keeps architecture, public cloud integration, data residency, compliance, performance, best practices, resources, and roadmap.

## Migration to Hyperforce

### Migration Process

**Salesforce handles migration** (no customer action required):

```text
Phase 1: Assessment (Salesforce internal)
├─ Analyze org size, customizations
├─ Identify any incompatible features
└─ Plan migration window

Phase 2: Pre-Migration (Customer notified)
├─ Salesforce sends notification (90 days notice)
├─ Customer tests in sandbox (migrated first)
└─ Customer validates functionality

Phase 3: Migration (Weekend maintenance window)
├─ Backup all data
├─ Replicate data to Hyperforce
├─ Cutover DNS (redirect traffic)
└─ Validate migration success

Phase 4: Post-Migration
├─ Monitor performance
├─ Support customer issues
└─ Decommission old infrastructure

Downtime: Typically <2 hours
```

### What Changes for Developers?

**No Code Changes Required**:
```apex
// Your Apex code works identically on Hyperforce
public class MyController {
    public List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 10];
    }
}

// No changes needed
// Same APIs, same limits, same behavior
```

**Potential Performance Improvements**:
- Faster API responses (lower latency)
- Better handling of concurrent users
- Improved batch job processing (parallel execution)

**Backward Compatibility**: 100% compatible with existing code

### Testing Pre-Migration

**Use Sandbox Migration**:
```text
1. Salesforce migrates your sandbox first
2. Test all critical functionality:
   ├─ Custom Apex classes
   ├─ Triggers and workflows
   ├─ Integrations (API callouts)
   ├─ Lightning components
   └─ Reports and dashboards

3. Validate performance:
   ├─ Run load tests
   ├─ Check API response times
   └─ Verify batch jobs complete

4. Report any issues to Salesforce
5. Production migration scheduled after sandbox validated
```

## Hyperforce for Developers

### Enhanced APIs

**Hyperforce exposes infrastructure APIs**:

```apex
// Query org's Hyperforce region (API 62.0+)
Organization org = [SELECT Id, InstanceName, InfrastructureRegion__c FROM Organization LIMIT 1];
System.debug('Region: ' + org.InfrastructureRegion__c); // 'aws-us-east-1'

// Check if org is on Hyperforce
System.debug('Is Hyperforce: ' + org.IsHyperforce__c); // true
```

### Private Connectivity

**AWS PrivateLink / Azure Private Link**:
```yaml
Traditional: Salesforce API → Public Internet → Your API
Security: TLS encryption, but still public internet

Hyperforce PrivateLink: Salesforce API → Private Network → Your API
Security: Never touches public internet, lower latency

Setup:
1. Create VPC Endpoint (AWS) or Private Endpoint (Azure)
2. Salesforce provides service endpoint name
3. Configure Named Credential in Salesforce with private endpoint
4. API calls route over private network
```

**Configuration**:
```apex
// Named Credential uses PrivateLink endpoint
// Setup → Named Credentials → External API (PrivateLink)
// URL: https://api.internal.example.com (private endpoint)

// Apex callout
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:ExternalAPIPrivateLink/data');
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);

// Callout never leaves private network
// Lower latency, higher security
```

### Monitoring

**CloudWatch / Azure Monitor Integration**:
```text
Salesforce publishes metrics to your cloud account:
├─ API request volume
├─ API response times
├─ Error rates
├─ Governor limit usage
└─ Batch job completion times

Benefits:
- Unified monitoring (Salesforce + your apps)
- Custom alerting (CloudWatch Alarms)
- Cost attribution (AWS Cost Explorer)
```

