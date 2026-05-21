# Agentforce Builder (GA December 2024)

Detailed Agentforce Builder workflow: agent creation, topics, instructions, actions, grounding, testing, publishing, Data Cloud integration, trust/guardrails, and deployment mechanics. SKILL.md keeps architecture, Agentforce 2.0, agent types, Platform Events, external AI integrations, monitoring, best practices, pricing, and migration.

## Building Agents with Agentforce Builder (GA December 2024)

### Step 1: Define Agent Purpose

Identify what the agent should accomplish:
- **Service Agent**: Handle support cases, answer FAQs, resolve issues (4 new actions in Spring '25)
- **Sales Development Agent**: Qualify leads, answer product questions, book meetings
- **Personal Shopper Agent**: Recommend products, handle orders, track shipments
- **Operations Agent**: Automate approvals, process requests, manage workflows
- **Slack Agent**: Proactive notifications and collaboration assistance

### Step 2: Configure Agent Topics

Topics define what the agent can help with:

```apex
// Example: Service Agent Topics
Topic: Password Reset
- Intent: User wants to reset password
- Required Data: Email, Username
- Connected Action: PasswordResetFlow

Topic: Order Status
- Intent: User wants order status
- Required Data: Order Number or Email
- Connected Action: GetOrderStatus

Topic: Escalate to Human
- Intent: User needs human assistance
- Required Data: Case context
- Connected Action: CreateCase + NotifyAgent
```

### Step 3: Define Agent Actions

Actions are what the agent can execute. These can be:
- **Standard Actions**: Pre-built Salesforce actions (create/update records)
- **Flow Actions**: Custom Flow automations
- **Apex Actions**: Custom Apex invocable methods
- **MuleSoft Actions**: API integrations via MuleSoft connectors
- **External API Actions**: REST/SOAP callouts

**Example Apex Action**:
```apex
public class AgentActions {
    @InvocableMethod(label='Get Order Status' description='Retrieves order status for customer')
    public static List<OrderStatus> getOrderStatus(List<OrderRequest> requests) {
        List<OrderStatus> results = new List<OrderStatus>();

        for (OrderRequest req : requests) {
            Order order = [SELECT Id, Status, EstimatedDelivery__c
                          FROM Order
                          WHERE OrderNumber = :req.orderNumber
                          LIMIT 1];

            OrderStatus status = new OrderStatus();
            status.orderNumber = req.orderNumber;
            status.status = order.Status;
            status.estimatedDelivery = order.EstimatedDelivery__c;
            results.add(status);
        }

        return results;
    }

    public class OrderRequest {
        @InvocableVariable(required=true)
        public String orderNumber;
    }

    public class OrderStatus {
        @InvocableVariable
        public String orderNumber;
        @InvocableVariable
        public String status;
        @InvocableVariable
        public Date estimatedDelivery;
    }
}
```

### Step 4: Write Agent Instructions

Instructions guide the agent's behavior and tone:

```yaml
You are a helpful customer service agent for Acme Corp.

Personality:
- Friendly, professional, and empathetic
- Patient with customers who are frustrated
- Proactive in offering solutions

Guidelines:
- Always greet customers by name if available
- Verify customer identity before sharing account information
- Offer alternatives if the requested action cannot be completed
- Escalate to human agent for: refunds >$500, legal issues, abusive customers
- Use simple language, avoid jargon
- Provide order numbers and case numbers in responses

Security:
- Never share: passwords, credit card numbers, SSN
- Always verify identity using: email, phone, or account number
- Log all interactions for compliance

Response Format:
- Keep responses under 3 sentences when possible
- Use bullet points for multiple items
- Include next steps or call-to-action
```

### Step 5: Connect Data Sources

Agentforce agents can access:
- **Salesforce Objects**: Standard and custom objects
- **Data Cloud**: Unified customer data from all sources
- **Knowledge Base**: Salesforce Knowledge articles
- **External Systems**: Via APIs and MuleSoft connectors

**Data Cloud Integration**:
```apex
// Query Data Cloud from Agentforce
public class AgentDataCloudActions {
    @InvocableMethod(label='Get Customer 360 View')
    public static List<Customer360> getCustomer360(List<String> customerIds) {
        // Query Data Cloud for unified customer data
        List<Customer360> results = new List<Customer360>();

        for (String customerId : customerIds) {
            // Data Cloud connector provides unified view
            DataCloudConnector.QueryRequest req = new DataCloudConnector.QueryRequest();
            req.sql = 'SELECT * FROM Unified_Customer WHERE customer_id = \'' + customerId + '\'';

            DataCloudConnector.QueryResponse res = DataCloudConnector.query(req);

            Customer360 customer = new Customer360();
            customer.customerId = customerId;
            customer.totalPurchases = (Decimal)res.data.get('total_purchases');
            customer.preferredChannel = (String)res.data.get('preferred_channel');
            customer.lifetimeValue = (Decimal)res.data.get('lifetime_value');
            results.add(customer);
        }

        return results;
    }
}
```

### Step 6: Configure Channels

Deploy agents across multiple channels:
- **Web Chat**: Embedded on website
- **Mobile App**: In Salesforce Mobile or custom apps
- **SMS/WhatsApp**: Messaging platforms
- **Slack/Teams**: Collaboration tools
- **Voice**: Phone support with voice-to-text
- **Email**: Email case management

