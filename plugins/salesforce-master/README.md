# Salesforce Master Plugin

Complete Salesforce expertise system for Claude Code covering all aspects of Salesforce development, integration, data modeling, and platform architecture.

## Overview

The `salesforce-master` plugin transforms Claude into a comprehensive Salesforce expert with deep knowledge of:

- **Salesforce APIs** (REST, SOAP, Bulk, Streaming, Metadata)
- **Apex Development** (classes, triggers, batch, scheduled, queueable)
- **Data Modeling** (objects, fields, relationships, SOQL/SOSL)
- **Lightning Platform** (LWC, Aura, Lightning Flow)
- **Integration Patterns** (source-to-SF, SF-to-target, bidirectional)
- **Deployment** (SFDX, change sets, metadata API, CI/CD)
- **Security** (OAuth, permissions, sharing, field-level security)

## Installation

### Via GitHub Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add JosiahSiegel/claude-code-marketplace

# Install salesforce-master
/plugin install salesforce-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use marketplace installation method instead.

```bash
# Clone the repository
git clone https://github.com/JosiahSiegel/claude-code-marketplace.git

# Copy plugin to Claude Code plugins directory
cp -r claude-code-marketplace/plugins/salesforce-master ~/.local/share/claude/plugins/
```

## Windows & Git Bash Compatibility

This plugin provides comprehensive guidance for **Windows Git Bash/MINGW environments**, which are commonly used for Salesforce CLI development on Windows.

### Key Features for Windows Developers

**Path Conversion Handling**: Automatic path conversion in Git Bash can cause issues with Salesforce CLI commands. The plugin includes:
- Shell detection patterns ($MSYSTEM, uname -s)
- MSYS_NO_PATHCONV usage for disabling path conversion
- Cross-platform deployment script examples
- cygpath usage for manual path conversion

**SF CLI Best Practices**: Windows-specific guidance for:
- `sf project deploy start` with proper path handling
- `sf project retrieve start` with manifest files
- CI/CD pipelines on Windows runners
- Relative vs absolute path strategies

**Cross-Platform Integration**: Node.js integration code with:
- path.resolve() for cross-platform compatibility
- Shell environment detection (Git Bash, WSL, PowerShell)
- File system operations that work on all platforms

**Affected Commands**: Windows path guidance is integrated into:
- `/sf-deploy` - Deployment with Git Bash path handling
- `/sf-integrate` - Integration scripts with shell detection
- All commands include cross-platform examples

## Features

### Slash Commands

Comprehensive commands covering all major Salesforce areas:

#### `/sf-api` - Salesforce API Integration
Work with Salesforce REST, SOAP, Bulk, Streaming, and Metadata APIs with authentication and best practices.

**Use for:**
- Setting up OAuth 2.0 authentication
- Designing REST API requests
- Implementing Bulk API workflows
- Working with Platform Events and Streaming API
- Handling API errors and rate limits

#### `/sf-apex` - Apex Development
Develop, debug, and optimize Apex code including classes, triggers, batch jobs, and test classes.

**Use for:**
- Writing production-ready Apex classes
- Implementing trigger frameworks
- Creating batch, scheduled, and queueable jobs
- Ensuring governor limits compliance
- Writing comprehensive test classes (>75% coverage)

#### `/sf-data` - Data Operations
Design SOQL/SOSL queries, perform CRUD operations, and manage Salesforce data models.

**Use for:**
- Writing optimized SOQL queries
- Understanding standard object schemas
- Designing selective queries (indexed fields)
- Implementing bulk data operations
- Data security and sharing rules

#### `/sf-integrate` - Integration Architecture
Autonomously wire up any source to Salesforce or Salesforce to any target with integration patterns.

**Use for:**
- Choosing the right integration pattern
- Implementing Platform Events and Change Data Capture
- Designing bidirectional sync architectures
- Error handling and retry logic
- Middleware and iPaaS integration

#### `/sf-deploy` - Deployment and Metadata
Deploy metadata, manage change sets, use SFDX CLI, and implement CI/CD pipelines.

**Use for:**
- SFDX project setup and commands
- Change set creation and deployment
- Metadata API operations
- CI/CD pipeline implementation (GitHub Actions, Azure DevOps)
- Deployment validation and testing strategies

#### `/sf-lightning` - Lightning Component Development
Develop Lightning Web Components (LWC) and Aura components with best practices.

**Use for:**
- Creating Lightning Web Components
- Component communication patterns
- Lightning Data Service (LDS)
- Jest testing for LWC
- SLDS styling and responsive design

#### `/sf-schema` - Data Model Design
Design Salesforce data models including objects, fields, relationships, and validation rules.

**Use for:**
- Creating custom objects and fields
- Designing relationships (lookup, master-detail, hierarchical)
- Writing formula fields and roll-up summaries
- Implementing validation rules
- Schema optimization for performance

### Specialized Skills (2025)

Deep-dive knowledge modules for cutting-edge Salesforce features:

#### Agentforce 2025 (`agentforce-2025`)
Comprehensive guide to building autonomous AI agents with Salesforce Agentforce platform. Covers Atlas Reasoning Engine, agent architecture, topics/actions/instructions, multi-channel deployment, and integration with external AI systems (OpenAI, Claude).

**Topics**: AI agents, autonomous automation, LLM integration, agent actions, Platform Events for agents, monitoring AI performance

#### Data Cloud 2025 (`data-cloud-2025`)
Complete Data Cloud integration patterns including real-time streaming, batch import, zero-copy architecture (Snowflake/Databricks), identity resolution, calculated insights, segmentation, and activation patterns.

**Topics**: Customer Data Platform (CDP), zero-copy integration, data harmonization, identity resolution, real-time activation, reverse ETL

#### Flow Orchestrator 2025 (`flow-orchestrator-2025`)
Multi-user, multi-stage workflow orchestration with interactive steps, background automation, fault paths, and SLA monitoring. Build complex business processes without code.

**Topics**: Multi-user workflows, stage-based automation, fault handling, orchestration monitoring, FlowOrchestrationWorkItem queries

#### Hyperforce 2025 (`hyperforce-2025`)
Salesforce cloud-native infrastructure on AWS/Azure/GCP. Covers immutable infrastructure, multi-AZ design, Zero Trust security, data residency, and migration strategies.

**Topics**: Public cloud architecture, Kubernetes/containers, data residency, AWS PrivateLink, Azure Private Link, Hyperforce migration

#### Lightning 2025 Features (`lightning-2025-features`)
Winter '26 Lightning Web Components updates including lightning/graphql module, local development, Lightning Out 2.0, SLDS 2.0 dark mode, and Agentforce targets.

**Topics**: LWC GraphQL, local development, Lightning Out 2.0, SLDS dark mode, unified testing APIs

### Specialized Agents

Expert agents for deep Salesforce knowledge:

#### `sf-api-expert` - API Integration Specialist
Complete expertise in all Salesforce APIs (REST, SOAP, Bulk, Streaming, Metadata, Tooling). Provides production-ready authentication, error handling, and performance optimization.

**Activates for:**
- ANY Salesforce API task
- Authentication implementation
- API endpoint design
- Composite API optimization
- Rate limit management

#### `sf-apex-expert` - Apex Development Specialist
Deep Apex knowledge including trigger frameworks, asynchronous patterns, governor limit optimization, and test coverage strategies.

**Activates for:**
- ANY Apex coding task
- Trigger framework design
- Batch/Scheduled/Queueable Apex
- Test class creation
- Performance troubleshooting

#### `sf-data-expert` - Data Model and SOQL Specialist
Expert in data model design, SOQL query optimization, relationship patterns, and large-scale data operations.

**Activates for:**
- ANY data model design task
- SOQL/SOSL query optimization
- Schema design and relationships
- Query performance troubleshooting
- Data security and sharing

#### `sf-integration-expert` - Integration Architecture Specialist
Complete integration patterns expertise for connecting Salesforce with external systems in any direction.

**Activates for:**
- ANY integration task
- Integration pattern selection
- Event-driven architecture
- Middleware/iPaaS design
- Bidirectional sync strategies

## Usage Examples

### Example 1: API Integration

```bash
# Get comprehensive API integration guidance
/sf-api

# Or let the API expert agent handle it proactively
"How do I authenticate to Salesforce using OAuth 2.0 JWT flow and create accounts via REST API?"
# sf-api-expert agent activates automatically
```

### Example 2: Apex Development

```bash
# Get Apex development guidance
/sf-apex

# Or ask directly for specific Apex patterns
"Write a bulkified trigger handler for Account that updates related Contacts"
# sf-apex-expert agent activates automatically
```

### Example 3: Data Queries

```bash
# Get data operations guidance
/sf-data

# Or ask for specific SOQL queries
"Write an optimized SOQL query to get Accounts with their Contacts and Opportunities, filtering on Industry"
# sf-data-expert agent activates automatically
```

### Example 4: Integration Design

```bash
# Get integration architecture guidance
/sf-integrate

# Or describe your integration scenario
"Design an integration to sync orders from my e-commerce platform to Salesforce in real-time"
# sf-integration-expert agent activates automatically
```

### Example 5: Deployment

```bash
# Get deployment guidance
/sf-deploy

# Or ask about specific deployment scenarios
"Set up a CI/CD pipeline with GitHub Actions to deploy Apex classes to Salesforce"
# Provides complete pipeline configuration and SFDX commands
```

## Key Capabilities

### Salesforce API Mastery
- **REST API**: CRUD operations, queries, composite requests, API versioning
- **SOAP API**: Enterprise WSDL, partner WSDL, legacy integrations
- **Bulk API**: Large data volumes (>2K records), CSV/JSON operations, job monitoring
- **Streaming API**: Real-time push notifications, CometD, generic/PushTopic
- **Platform Events**: Pub/sub messaging, event-driven architecture
- **Change Data Capture**: Automatic change notifications, data replication
- **Metadata API**: Deploy/retrieve metadata, CI/CD automation
- **Tooling API**: Development tools, debug logs, code coverage

### Apex Development Expertise
- **Trigger Patterns**: One trigger per object, handler pattern, service layer
- **Asynchronous Apex**: Batch (>50K records), Scheduled (cron), Queueable (chaining), Future (callouts)
- **Governor Limits**: Bulkification, SOQL/DML limits, heap size, CPU time
- **Test Classes**: Code coverage strategies, test data factories, mocking
- **Best Practices**: with sharing, error handling, logging, performance monitoring

### Data Model and SOQL
- **Standard Objects**: Complete schema knowledge (Account, Contact, Opportunity, Lead, Case, etc.)
- **Custom Objects**: Field types, relationships, validation rules, formulas
- **Relationships**: Lookup, Master-Detail, Hierarchical, Many-to-Many (junction)
- **SOQL**: Selective queries, subqueries, aggregations, optimization
- **SOSL**: Full-text search, multi-object queries
- **Query Optimization**: Indexed fields, query plan, pagination, avoiding full table scans

### Integration Patterns
- **Request-Response**: Synchronous API calls, real-time lookups
- **Batch Sync**: Scheduled data synchronization, ETL workflows
- **Event-Driven**: Platform Events, Change Data Capture, streaming
- **Bidirectional Sync**: Conflict resolution, last write wins, external IDs
- **Middleware**: MuleSoft, Dell Boomi, Informatica, API Gateway
- **Security**: OAuth 2.0, Named Credentials, JWT, encryption

### Lightning Platform (2025)
- **Lightning Web Components (LWC)**: Modern JavaScript, Shadow DOM, ES6+
- **lightning/graphql module**: New GraphQL API (Winter '26)
- **Local Development**: sf lightning dev component (instant feedback, no deployment)
- **Component Communication**: Parent-child, events, Lightning Message Service
- **Lightning Data Service**: Wire adapters, imperative Apex, DML operations
- **Lightning Out 2.0**: Web components-based embedding (GA Winter '26)
- **Testing**: Jest unit tests, mocking, DOM assertions
- **SLDS 2.0**: Dark mode support, SLDS linter with auto-fix

### Deployment and CI/CD
- **SFDX CLI**: Project setup, retrieve/deploy, scratch orgs, source-driven development
- **Change Sets**: Outbound/inbound, dependency management, deployment validation
- **Metadata API**: Package.xml, destructive changes, deployment monitoring
- **CI/CD**: GitHub Actions, Azure DevOps, automated testing, deployment pipelines
- **Environment Strategy**: Dev → Test → UAT → Production workflow

## Salesforce Version Support

The plugin provides guidance for **Salesforce API version 62.0+ (Winter '25/Winter '26/2025)** and includes the latest 2025 features:

### API & Development (API 62.0+)
- Lightning/graphql module (replaces deprecated lightning/uiGraphQLApi)
- Lightning Out 2.0 (GA) - Web components-based embedding
- LWC for Local Actions in Flows (client-side execution)
- Enhanced local development with platform modules
- API 62.0 breaking changes (collection iteration restrictions)
- 2025 security standards (MFA mandatory, WITH SECURITY_ENFORCED, stripInaccessible)

### AI & Automation (2025)
- **Agentforce**: Autonomous AI agents with Atlas Reasoning Engine
- **Agentforce Builder**: Build, test, deploy AI agents (Beta November 2025)
- **Einstein Copilot → Agentforce Assistant**: Conversational AI evolution
- **Flow Orchestrator**: Multi-user, multi-stage workflows with fault paths (Summer '25)
- **Data Cloud**: Real-time CDP with 200+ connectors and zero-copy architecture

### Infrastructure (2025)
- **Hyperforce**: Cloud-native architecture on AWS/Azure/GCP
- **Multi-AZ deployments**: 99.95%+ SLA with automatic failover
- **Zero Trust security**: Verify everything, trust nothing
- **Data residency**: 25+ global regions with compliance guarantees

When version-specific features are mentioned, the documentation clearly indicates the minimum required version.

## Best Practices Enforced

- **API**: OAuth 2.0 authentication, error handling, rate limit management, composite APIs
- **Apex**: Bulkification (200+ records), governor limits, test coverage (>75%), trigger frameworks
- **Data**: Selective queries, indexed fields, External IDs for integration, data security
- **Integration**: Retry logic, error logging, idempotency, monitoring, secure credentials
- **Deployment**: Version control (Git), automated CI/CD, validation before production, rollback plans

## Official Salesforce Documentation

The plugin always references official Salesforce documentation for the most up-to-date guidance:

- **Developer Guides**: https://developer.salesforce.com/docs
- **API References**: REST, SOAP, Bulk, Streaming, Metadata, Tooling APIs
- **Apex Reference**: Classes, interfaces, system methods
- **SOQL/SOSL**: Query language reference
- **LWC Guide**: Component library, patterns, testing
- **Integration Patterns**: Architecture guides, best practices
- **Trailhead**: Learning paths for all Salesforce topics

## Contributing

Contributions are welcome! If you find issues or have suggestions for improvements:

1. Open an issue: https://github.com/JosiahSiegel/claude-code-marketplace/issues
2. Submit a pull request with your changes
3. Follow the existing code style and documentation patterns

## License

MIT License - See LICENSE file for details

## Support

For questions, issues, or feature requests:

- **GitHub Issues**: https://github.com/JosiahSiegel/claude-code-marketplace/issues
- **Plugin Documentation**: https://docs.claude.com/en/docs/claude-code/plugins

## Acknowledgments

Built with comprehensive knowledge of Salesforce platform capabilities, best practices, and architectural patterns. Designed to help developers build production-ready, scalable Salesforce solutions.

---

**Note**: This plugin provides guidance and code examples for Salesforce development. Always test thoroughly in a sandbox environment before deploying to production.
