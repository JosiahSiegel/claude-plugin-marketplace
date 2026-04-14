---
name: hyperforce-2025
description: Salesforce Hyperforce public cloud infrastructure and architecture (2025). PROACTIVELY activate for: (1) understanding Hyperforce architecture (multi-region, public cloud), (2) Hyperforce migration planning, (3) data residency and regional deployments, (4) Hyperforce security model (BYOK, Shield encryption), (5) network architecture (PrivateLink, public IP allowlists), (6) Hyperforce vs first-generation infrastructure differences, (7) backup and disaster recovery on Hyperforce, (8) Hyperforce performance and SLA, (9) compliance certifications (HIPAA, FedRAMP, GDPR). Provides: Hyperforce overview, migration checklist, network architecture patterns, BYOK setup, and DR/backup configuration.
---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

# Salesforce Hyperforce Architecture (2025)

## What is Hyperforce?

Hyperforce is Salesforce's next-generation infrastructure architecture built on public cloud platforms (AWS, Azure, Google Cloud). It represents a complete re-architecture of Salesforce from data center-based infrastructure to cloud-native, containerized microservices.

**Key Innovation**: Infrastructure as code that can be deployed anywhere, giving customers choice, control, and data residency compliance.

## Five Architectural Principles

### 1. Immutable Infrastructure

**Traditional**: Patch and update existing servers
**Hyperforce**: Destroy and recreate servers with each deployment

```
Old Architecture:
Server → Patch → Patch → Patch → Configuration Drift

Hyperforce:
Container Image v1 → Deploy
New Code → Build Container Image v2 → Replace v1 with v2
Result: Every deployment is identical, reproducible
```

**Benefits**:
- No configuration drift
- Consistent environments (dev = prod)
- Fast rollback (redeploy previous image)
- Security patches applied immediately

### 2. Multi-Availability Zone Design

**Architecture**:
```
Region: US-East (Virginia)
├─ Availability Zone A (Data Center 1)
│  ├─ App Servers (Kubernetes pods)
│  ├─ Database Primary
│  └─ Load Balancer
├─ Availability Zone B (Data Center 2)
│  ├─ App Servers (Kubernetes pods)
│  ├─ Database Replica
│  └─ Load Balancer
└─ Availability Zone C (Data Center 3)
   ├─ App Servers (Kubernetes pods)
   ├─ Database Replica
   └─ Load Balancer

Traffic Distribution: Round-robin across all AZs
Failure Handling: If AZ fails, traffic routes to remaining AZs
RTO (Recovery Time Objective): <5 minutes
RPO (Recovery Point Objective): <30 seconds
```

**Impact on Developers**:
- Higher availability (99.95%+ SLA)
- Transparent failover (no code changes)
- Regional data residency guaranteed

### 3. Zero Trust Security

**Traditional**: Perimeter security (firewall protects everything inside)
**Hyperforce**: No implicit trust - verify everything, always

```
Zero Trust Model:
├─ Identity Verification (MFA required for all users by 2025)
├─ Device Trust (managed devices only)
├─ Network Segmentation (micro-segmentation between services)
├─ Least Privilege Access (minimal permissions by default)
├─ Continuous Monitoring (real-time threat detection)
└─ Encryption Everywhere (TLS 1.3, data at rest encryption)
```

**Code Impact**:
```apex
// OLD: Assume internal traffic is safe
public without sharing class InternalService {
    // No auth checks - trusted network
}

// HYPERFORCE: Always verify, never trust
public with sharing class InternalService {
    // Always enforce sharing rules
    // Always validate session
    // Always check field-level security

    public List<Account> getAccounts() {
        // WITH SECURITY_ENFORCED prevents data leaks
        return [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];
    }
}
```

**2025 Requirements**:
- **MFA Mandatory**: All users must enable MFA
- **Session Security**: Shorter session timeouts, IP restrictions
- **API Security**: JWT with short expiration (15 minutes)

### 4. Infrastructure as Code (IaC)

**Everything defined as code, version-controlled**:

```yaml
# Hyperforce deployment manifest (conceptual)
apiVersion: hyperforce.salesforce.com/v1
kind: SalesforceOrg
metadata:
  name: production-org
  region: aws-us-east-1
spec:
  edition: enterprise
  features:
    - agentforce
    - dataCloud
    - einstein
  compute:
    pods: 50
    autoScaling:
      min: 10
      max: 100
      targetCPU: 70%
  storage:
    size: 500GB
    replication: 3
  backup:
    frequency: hourly
    retention: 30days
  networking:
    privateLink: enabled
    ipWhitelist:
      - 203.0.113.0/24
```

**Benefits for Developers**:
- **Reproducible**: Recreate exact environment anytime
- **Version Controlled**: Track all infrastructure changes in Git
- **Testable**: Validate infrastructure before deployment
- **Automated**: No manual configuration, eliminates human error

### 5. Clean Slate (No Legacy Constraints)

**Hyperforce rebuilt from scratch**:
- Modern Kubernetes orchestration
- Cloud-native services (managed databases, object storage)
- API-first design (everything accessible via API)
- Microservices architecture (independent scaling)
- No legacy code or technical debt

## Public Cloud Integration

### AWS Hyperforce Architecture

```
┌────────────────────────────────────────────────────────┐
│                  AWS Region (us-east-1)                │
├────────────────────────────────────────────────────────┤
│  VPC (Virtual Private Cloud)                           │
│  ├─ Public Subnets (3 AZs)                             │
│  │  └─ Application Load Balancer (ALB)                 │
│  ├─ Private Subnets (3 AZs)                            │
│  │  ├─ EKS Cluster (Kubernetes)                        │
│  │  │  ├─ Salesforce App Pods (autoscaling)            │
│  │  │  ├─ Metadata Service Pods                        │
│  │  │  ├─ API Gateway Pods                             │
│  │  │  └─ Background Job Pods (Batch, Scheduled)       │
│  │  ├─ RDS Aurora PostgreSQL (multi-AZ)                │
│  │  ├─ ElastiCache Redis (session storage)             │
│  │  └─ S3 Buckets (attachments, documents)             │
│  └─ Database Subnets (3 AZs)                           │
│     └─ Aurora Database Cluster                         │
├────────────────────────────────────────────────────────┤
│  Additional Services                                   │
│  ├─ CloudWatch (monitoring, logs)                      │
│  ├─ CloudTrail (audit logs)                            │
│  ├─ AWS Shield (DDoS protection)                       │
│  ├─ AWS WAF (web application firewall)                 │
│  ├─ KMS (encryption key management)                    │
│  └─ PrivateLink (secure connectivity)                  │
└────────────────────────────────────────────────────────┘
```

**AWS Services Used**:
- **Compute**: EKS (Elastic Kubernetes Service)
- **Database**: Aurora PostgreSQL (multi-master)
- **Storage**: S3 (object storage), EBS (block storage)
- **Networking**: VPC, ALB, Route 53, CloudFront CDN
- **Security**: IAM, KMS, Shield, WAF, Certificate Manager

### Azure Hyperforce Architecture

```
Azure Region (East US)
├─ Virtual Network (VNet)
│  ├─ AKS (Azure Kubernetes Service)
│  │  └─ Salesforce workloads
│  ├─ Azure Database for PostgreSQL (Hyperscale)
│  ├─ Azure Cache for Redis
│  └─ Azure Blob Storage
├─ Azure Front Door (CDN + Load Balancer)
├─ Azure Monitor (logging, metrics)
├─ Azure Active Directory (identity)
└─ Azure Key Vault (secrets, encryption)
```

### Google Cloud Hyperforce Architecture

```
GCP Region (us-central1)
├─ VPC Network
│  ├─ GKE (Google Kubernetes Engine)
│  ├─ Cloud SQL (PostgreSQL)
│  ├─ Memorystore (Redis)
│  └─ Cloud Storage (GCS)
├─ Cloud Load Balancing
├─ Cloud Armor (DDoS protection)
├─ Cloud Monitoring (Stackdriver)
└─ Cloud KMS (encryption)
```

## Data Residency and Compliance

### Geographic Regions (2025)

**Available Hyperforce Regions**:
```
Americas:
├─ US East (Virginia) - AWS, Azure
├─ US West (Oregon) - AWS
├─ US Central (Iowa) - GCP
├─ Canada (Toronto) - AWS
└─ Brazil (São Paulo) - AWS

Europe:
├─ UK (London) - AWS
├─ Germany (Frankfurt) - AWS, Azure
├─ France (Paris) - AWS
├─ Ireland (Dublin) - AWS
└─ Switzerland (Zurich) - AWS

Asia Pacific:
├─ Japan (Tokyo) - AWS
├─ Australia (Sydney) - AWS
├─ Singapore - AWS
├─ India (Mumbai) - AWS
└─ South Korea (Seoul) - AWS

Middle East:
└─ UAE (Dubai) - AWS
```

### Data Residency Guarantees

**What stays in region**:
- All customer data (records, attachments, metadata)
- Database backups
- Transaction logs
- Audit logs

**What may leave region**:
- Telemetry data (anonymized performance metrics)
- Security threat intelligence
- Platform health monitoring

**Code Implication**:
```apex
// Data residency automatically enforced
// No code changes needed - Hyperforce handles it

// Example: File stored in org's region
ContentVersion cv = new ContentVersion(
    Title = 'Customer Contract',
    PathOnClient = 'contract.pdf',
    VersionData = Blob.valueOf('contract data')
);
insert cv;

// File automatically stored in:
// - AWS S3 in org's region
// - Encrypted at rest (AES-256)
// - Replicated across 3 AZs in region
// - Never leaves region boundary
```

### Compliance Certifications

**Hyperforce maintains**:
- **SOC 2 Type II**: Security, availability, confidentiality
- **ISO 27001**: Information security management
- **GDPR**: EU data protection compliance
- **HIPAA**: Healthcare data protection (BAA available)
- **PCI DSS**: Payment card data security
- **FedRAMP**: US government cloud security (select regions)

## Performance Improvements

### Latency Reduction

**Old Architecture** (data center-based):
```
User (Germany) → Transatlantic cable → US Data Center → Response
Latency: 150-200ms
```

**Hyperforce**:
```
User (Germany) → Frankfurt Hyperforce Region → Response
Latency: 10-30ms

Result: 5-10x faster for regional users
```

### Auto-Scaling

**Traditional**: Fixed capacity, must provision for peak load
**Hyperforce**: Dynamic scaling based on demand

```
Business Hours (9 AM - 5 PM):
├─ High user load
├─ Kubernetes scales up pods: 50 → 150
└─ Response times maintained

Off Hours (6 PM - 8 AM):
├─ Low user load
├─ Kubernetes scales down pods: 150 → 30
└─ Cost savings (pay for what you use)

Black Friday (peak event):
├─ Extreme load
├─ Kubernetes scales to maximum: 30 → 500 pods in minutes
└─ No downtime, no performance degradation
```

**Governor Limits - No Change**:
```apex
// Hyperforce does NOT change governor limits
// Limits remain the same as classic Salesforce:
// - 100 SOQL queries per transaction
// - 150 DML statements
// - 6 MB heap size (sync), 12 MB (async)

// But: Infrastructure scales to handle more concurrent users
```

## Migration to Hyperforce

### Migration Process

**Salesforce handles migration** (no customer action required):

```
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
```
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
```
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
```
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

## Best Practices for Hyperforce

### Security
- **Enable MFA**: Required for all users in 2025
- **Use WITH SECURITY_ENFORCED**: Field-level security in SOQL
- **Implement IP whitelisting**: Restrict access to known IPs
- **Monitor audit logs**: Setup → Event Monitoring
- **Rotate credentials**: API keys, certificates, passwords regularly

### Performance
- **Leverage caching**: Platform Cache for frequently accessed data
- **Optimize queries**: Use indexed fields, selective queries
- **Async processing**: Use @future, Queueable for non-critical work
- **Bulkification**: Always design for 200+ records
- **Monitor limits**: Use Limits class to track governor limit usage

### Data Residency
- **Understand requirements**: Know your compliance obligations
- **Choose correct region**: Select region meeting your needs
- **Validate configurations**: Ensure integrations respect boundaries
- **Document decisions**: Maintain records of data residency choices

### Cost Optimization
- **Right-size storage**: Archive old data, delete unnecessary records
- **Optimize API calls**: Batch API calls, use composite APIs
- **Schedule batch jobs efficiently**: Run during off-peak hours
- **Monitor usage**: Track API calls, storage, compute usage

## Resources

- **Hyperforce Trust Site**: https://trust.salesforce.com/en/infrastructure/hyperforce/
- **Hyperforce FAQ**: Salesforce Help documentation
- **Available Regions**: https://help.salesforce.com/s/articleView?id=sf.getstart_domain_overview.htm
- **Migration Guide**: Provided by Salesforce 90 days before migration
- **Trust & Compliance**: https://compliance.salesforce.com/

## Future Roadmap (2025+)

**Expected Enhancements**:
- More regions (Africa, additional Asia Pacific)
- Bring Your Own Cloud (BYOC) - use your own AWS/Azure account
- Multi-region active-active (write to multiple regions simultaneously)
- Edge computing (Salesforce at CDN edge locations)
- Kubernetes cluster API (direct pod management for enterprises)

Hyperforce represents Salesforce's commitment to modern, cloud-native infrastructure that scales globally while meeting the most stringent compliance and performance requirements.
