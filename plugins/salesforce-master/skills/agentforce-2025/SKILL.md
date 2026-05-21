---
name: agentforce-2025
description: |
  Salesforce Agentforce AI agents and autonomous automation (2025-2026).
  PROACTIVELY activate for: (1) building Agentforce agents and topics, (2) Agent Builder configuration, (3) Atlas Reasoning Engine usage, (4) Agentforce action setup (Apex, Flow, Prompt Templates), (5) topic-based routing and instructions, (6) Agentforce Service Agent vs Sales Agent vs Custom, (7) Einstein Trust Layer (data masking, toxicity detection), (8) prompt engineering for grounded responses, (9) Agentforce testing and Test Center, (10) deploying agents across orgs.
  Provides: agent design patterns, topic and action templates, prompt engineering recipes, Trust Layer configuration, and deployment workflow.
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

# Agentforce: AI Agents for Salesforce (2025)

## What is Agentforce?

Agentforce is Salesforce's enterprise AI agent platform that enables autonomous, proactive applications to execute specialized tasks for employees and customers. Agentforce agents use large language models (LLMs) with the Atlas Reasoning Engine to analyze context, reason through decisions, and take action autonomously.

**Key Distinction**: Agentforce represents the evolution from Einstein Copilot (conversational assistant) to autonomous agents that can complete tasks without human prompting.

## Core Architecture

### Atlas Reasoning Engine

The Atlas Reasoning Engine is the brain of Agentforce, enabling agents to:
- **Understand**: Analyze full context of customer interactions or automated triggers
- **Decide**: Reason through decisions using LLMs and business logic
- **Act**: Execute actions autonomously across any system
- **Learn**: Improve over time based on outcomes and feedback

### Agent Components

```text
┌─────────────────────────────────────────────────┐
│              Agentforce Agent                   │
├─────────────────────────────────────────────────┤
│  1. Topics (what agent handles)                 │
│  2. Actions (what agent can do)                 │
│  3. Instructions (how agent behaves)            │
│  4. Channel Integrations (where agent works)    │
│  5. Data Sources (what agent knows)             │
└─────────────────────────────────────────────────┘
```

## Agentforce 2.0 (GA December 2024)

Agentforce 2.0 is the digital labor platform for enterprises, enabling a limitless workforce through AI agents. Key enhancements:

- **Pre-built Skills Library**: Rapid agent customization with out-of-the-box capabilities
- **Workflow Integrations**: MuleSoft for Flow, MuleSoft API Catalog, Topic Center (Q1 2025)
- **Slack Deployment**: Native Slack integration for collaboration agents
- **Enhanced RAG**: Improved retrieval augmented generation for accurate responses
- **Advanced Reasoning**: More sophisticated Atlas Reasoning Engine capabilities
- **Pricing**: $2 per conversation (GA October 25, 2024)

## Agentforce Builder Workflow

Detailed Agentforce Builder workflow — agent creation, topics, instructions, actions, grounding, testing, publishing, Data Cloud integration, trust / guardrails, and deployment mechanics — lives in `references/agentforce-builder.md`. Load that reference when building or configuring agents rather than just selecting an architecture.

## Agent Types and Use Cases

### 1. Service Agent (Customer Support)

**Capabilities**:
- Answer FAQs from Knowledge Base
- Retrieve order/account status
- Process returns and exchanges
- Reset passwords and unlock accounts
- Create and route cases to specialists
- Provide troubleshooting steps

**Example Flow**:
```text
Customer: "Where is my order #12345?"
↓
Agent: Validates order number
↓
Agent: Queries Order object
↓
Agent: Retrieves tracking information
↓
Agent: "Your order #12345 shipped yesterday and will arrive Thursday.
       Tracking: UPS 1Z999AA10123456784. Need anything else?"
```

### 2. Sales Development Agent (SDR)

**Capabilities**:
- Qualify inbound leads
- Answer product questions
- Handle objections with sales playbooks
- Book meetings with sales reps
- Send follow-up emails
- Update lead scores based on engagement

**Example Flow**:
```text
Lead: "Tell me about your enterprise plan"
↓
Agent: Retrieves product information
↓
Agent: Explains features, pricing
↓
Agent: Detects buying intent
↓
Agent: "Would you like to schedule a demo with our sales team?"
↓
Agent: Creates meeting, updates lead status to "Meeting Scheduled"
```

### 3. Personal Shopper Agent (E-commerce)

**Capabilities**:
- Recommend products based on preferences
- Answer product questions
- Check inventory and availability
- Process orders and payments
- Apply discounts and promotions
- Handle cart abandonment

### 4. Operations Agent (Internal Automation)

**Capabilities**:
- Process employee requests (PTO, equipment)
- Automate approvals based on rules
- Onboard new employees
- Generate reports and insights
- Monitor system health
- Trigger workflows based on events

## Integrating Agentforce with Platform Events

Publish events to trigger Agentforce actions:

```apex
// Publish event when order status changes
public class OrderEventPublisher {
    public static void publishOrderUpdate(Id orderId, String newStatus) {
        OrderStatusChangeEvent__e event = new OrderStatusChangeEvent__e(
            OrderId__c = orderId,
            NewStatus__c = newStatus,
            Timestamp__c = System.now()
        );

        EventBus.publish(event);

        // Agentforce subscribes to this event
        // Triggers proactive customer notification
    }
}

// Trigger
trigger OrderTrigger on Order (after update) {
    for (Order ord : Trigger.new) {
        if (ord.Status != Trigger.oldMap.get(ord.Id).Status) {
            OrderEventPublisher.publishOrderUpdate(ord.Id, ord.Status);
        }
    }
}
```

**Agentforce Flow** (subscribed to OrderStatusChangeEvent__e):
```text
1. Receive event
2. Query order and customer details
3. Determine notification channel (email, SMS, push)
4. Generate personalized message using LLM
5. Send notification via preferred channel
6. Log interaction in Customer timeline
```

## Agentforce with External AI Systems

Integrate Agentforce with external AI providers:

### OpenAI GPT Integration

```apex
public class AgentOpenAIIntegration {
    @InvocableMethod(label='Generate Response with GPT-4')
    public static List<String> generateResponse(List<AIRequest> requests) {
        List<String> responses = new List<String>();

        for (AIRequest req : requests) {
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:OpenAI/v1/chat/completions');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'model' => 'gpt-4',
                'messages' => new List<Object>{
                    new Map<String, String>{
                        'role' => 'system',
                        'content' => req.systemPrompt
                    },
                    new Map<String, String>{
                        'role' => 'user',
                        'content' => req.userMessage
                    }
                },
                'temperature' => 0.7,
                'max_tokens' => 500
            };

            httpReq.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse httpRes = http.send(httpReq);

            if (httpRes.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
                List<Object> choices = (List<Object>)result.get('choices');
                Map<String, Object> choice = (Map<String, Object>)choices[0];
                Map<String, Object> message = (Map<String, Object>)choice.get('message');
                responses.add((String)message.get('content'));
            }
        }

        return responses;
    }

    public class AIRequest {
        @InvocableVariable(required=true)
        public String systemPrompt;
        @InvocableVariable(required=true)
        public String userMessage;
    }
}
```

### Anthropic Claude Integration

```apex
public class AgentClaudeIntegration {
    @InvocableMethod(label='Generate Response with Claude')
    public static List<String> generateResponse(List<AIRequest> requests) {
        List<String> responses = new List<String>();

        for (AIRequest req : requests) {
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:Anthropic/v1/messages');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('anthropic-version', '2023-06-01');

            Map<String, Object> payload = new Map<String, Object>{
                'model' => 'claude-3-5-sonnet-20241022',
                'max_tokens' => 1024,
                'system' => req.systemPrompt,
                'messages' => new List<Object>{
                    new Map<String, String>{
                        'role' => 'user',
                        'content' => req.userMessage
                    }
                }
            };

            httpReq.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse httpRes = http.send(httpReq);

            if (httpRes.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
                List<Object> content = (List<Object>)result.get('content');
                Map<String, Object> contentBlock = (Map<String, Object>)content[0];
                responses.add((String)contentBlock.get('text'));
            }
        }

        return responses;
    }
}
```

## Monitoring and Analytics

### Agent Performance Metrics

Track agent effectiveness:
- **Resolution Rate**: % of interactions resolved without escalation
- **Average Handle Time**: Time to resolve customer request
- **Customer Satisfaction**: Post-interaction survey scores
- **Containment Rate**: % of interactions handled by agent vs human
- **Action Success Rate**: % of successful action executions

**Custom Reporting Object**:
```apex
public class AgentInteractionLogger {
    public static void logInteraction(String agentName, String topic,
                                     Boolean resolved, Decimal duration) {
        AgentInteraction__c interaction = new AgentInteraction__c(
            AgentName__c = agentName,
            Topic__c = topic,
            Resolved__c = resolved,
            Duration__c = duration,
            Timestamp__c = System.now()
        );
        insert interaction;
    }
}
```

### Analytics Dashboard Queries

```sql
-- Resolution rate by agent
SELECT AgentName__c,
       COUNT(Id) as TotalInteractions,
       SUM(CASE WHEN Resolved__c = true THEN 1 ELSE 0 END) as Resolved,
       AVG(Duration__c) as AvgDuration
FROM AgentInteraction__c
WHERE CreatedDate = LAST_N_DAYS:30
GROUP BY AgentName__c

-- Top topics requiring human escalation
SELECT Topic__c,
       COUNT(Id) as Escalations
FROM AgentInteraction__c
WHERE Resolved__c = false
  AND CreatedDate = LAST_N_DAYS:30
GROUP BY Topic__c
ORDER BY COUNT(Id) DESC
LIMIT 10
```

## Best Practices

### Security and Compliance
- **Field-Level Security**: Always use WITH SECURITY_ENFORCED in SOQL
- **Data Access**: Respect sharing rules with `with sharing` keywords
- **PII Protection**: Never log sensitive data (SSN, credit cards, passwords)
- **Audit Trail**: Log all agent actions for compliance
- **Human Oversight**: Require approval for high-impact actions

### Performance Optimization
- **Batch Processing**: Group similar actions to reduce API calls
- **Caching**: Cache frequently accessed data (product catalogs, FAQs)
- **Async Execution**: Use @future or Queueable for non-critical actions
- **Rate Limiting**: Implement throttling for external API calls
- **Timeout Handling**: Set appropriate timeouts and retry logic

### User Experience
- **Response Time**: Aim for <3 second responses
- **Personalization**: Use customer data for personalized responses
- **Transparency**: Clearly identify agent vs human interactions
- **Escalation**: Provide easy path to human agent when needed
- **Feedback Loop**: Collect user feedback to improve agent

### Testing
- **Unit Tests**: Test individual actions in isolation
- **Integration Tests**: Test end-to-end agent flows
- **Load Tests**: Simulate high volume to test scalability
- **User Acceptance Tests**: Validate with real users in sandbox
- **A/B Testing**: Compare different agent configurations

## Agentforce Pricing and Licensing (2025)

- **Agentforce Service Agent**: $2 per conversation (GA October 2024)
- **Agentforce Sales Development Agent**: $2 per conversation
- **Custom Agents**: Available with Einstein 1 Edition or add-on
- **Agent Runs**: 600 free orchestration runs per year (Enterprise+)
- **Consumption Model**: Pay-per-use based on conversations
- **Vision**: One billion agents with Agentforce by end of 2025

## Spring '25 and Summer '25 Updates

### Spring '25 (API 63.0) - Available Q2 2025
- **Enhanced Service Agent**: 4 new agent actions + 1 new topic
- **Salesforce LLM Open Connector**: Connect any LLM (OpenAI, Claude, custom models)
- **Conversation Context Testing**: Specify language, app, page type for precise testing
- **Einstein Decision Element**: Automate flow paths based on email engagement metrics
- **Einstein-Powered Flow Creation**: New Einstein Panel in Flow Builder

### Summer '25 (API 64.0) - Available Q3 2025
- **Hybrid Search**: Combines semantic search with keyword search for accuracy
- **Multi-language Semantic Search**: Cross-language case similarity (e.g., French → English)
- **Report Formula Generation**: Plain language descriptions create complex formulas
- **AI-driven Account Summarization**: Automated insights for service agents

## Resources

- **Agentforce Platform**: https://www.salesforce.com/agentforce/
- **Agentforce Builder Documentation**: https://help.salesforce.com/s/articleView?id=sf.einstein_studio.htm
- **Einstein 1 Studio**: https://help.salesforce.com/s/articleView?id=sf.einstein_studio.htm
- **Atlas Reasoning Engine**: Technical documentation in Winter '26 release notes
- **Agentforce Trailhead**: Search "Agentforce" on Trailhead for modules
- **LLM Open Connector**: Spring '25 release notes

## Migration from Einstein Copilot

**IMPORTANT**: Einstein Copilot was retired in January 2025 and renamed to "Agentforce (Default)". It is now one of the Agentforce agents.

If you have Einstein Copilot (now Agentforce Assistant), migration path:

```text
Einstein Copilot → Agentforce (Default)
- Automatically migrated in January 2025
- Conversational UI remains the same
- Add autonomous triggers and workflows
- Convert Copilot Actions to Agent Actions
- Add proactive agent behaviors
- Enable multi-channel deployment (including Slack in 2.0)
```

**Action Migration Example**:
```apex
// Einstein Copilot Action (reactive)
@InvocableMethod(label='Copilot: Get Account Info')
public static List<Account> getAccountInfo(List<Id> accountIds) {
    return [SELECT Id, Name, Industry FROM Account WHERE Id IN :accountIds];
}

// Agentforce Action (proactive + reactive)
@InvocableMethod(label='Agent: Monitor and Alert on Account Changes')
public static void monitorAccounts(List<Id> accountIds) {
    // Not only retrieve data, but also:
    // 1. Monitor for changes
    // 2. Detect anomalies (sudden revenue drop)
    // 3. Proactively alert account manager
    // 4. Suggest next best actions
}
```

Agentforce represents a paradigm shift from conversational assistants to autonomous agents that can complete complex, multi-step tasks without human intervention while maintaining trust and security.
