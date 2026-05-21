# Flow Orchestrator: Advanced Patterns and Monitoring

Advanced Flow Orchestrator designs (parallel approvals, conditional branches, retry/escalation, record-triggered orchestration, external integration handoffs) plus monitoring, reporting, and operational dashboards. SKILL.md keeps overview, use cases, architecture, build steps, step types, integrations, best practices, troubleshooting, pricing, and migration.

## Advanced Patterns

### Pattern 1: Conditional Stage Execution

**Use Case**: Skip stages based on criteria

```yaml
Stage 2: Manager Approval
Condition: Order_Total__c > 10000

Entry Criteria Formula:
{!$Record.Order_Total__c} > 10000

Result:
- If order <= $10,000 → Skip Stage 2, go to Stage 3
- If order > $10,000 → Execute Stage 2 (manager approval required)
```

### Pattern 2: Parallel Steps Within Stage

**Use Case**: Multiple teams work simultaneously

```text
Stage 3: Parallel Provisioning
Run Mode: All at Once (parallel)

Step 3.1 (Interactive): IT assigns laptop [Assigned to IT Queue]
Step 3.2 (Interactive): Facilities assigns desk [Assigned to Facilities Queue]
Step 3.3 (Interactive): HR orders business cards [Assigned to HR Queue]

Stage completes when: All steps complete
```

### Pattern 3: Dynamic Assignment

**Use Case**: Assign to different users based on record data

```text
Step Assignment Formula:
IF(
  {!$Record.Region__c} = 'West',
  {!$User.WestCoastManager},
  IF(
    {!$Record.Region__c} = 'East',
    {!$User.EastCoastManager},
    {!$User.DefaultManager}
  )
)
```

### Pattern 4: SLA Monitoring

**Use Case**: Escalate if step not completed on time

```text
Step Due Date: {!$Flow.CurrentDate} + 2 (2 days)

Scheduled Flow: Check_Overdue_Steps
- Schedule: Daily at 8 AM
- Query: OrchestrationWorkItem where DueDate < TODAY AND Status = 'In Progress'
- Action: Send escalation email to manager
```

**Monitor with SOQL**:
```apex
// Query overdue orchestration steps
List<FlowOrchestrationWorkItem> overdueItems = [
    SELECT Id, Label, StepDefinitionName, AssignedToId,
           RelatedRecordId, DueDate, Status
    FROM FlowOrchestrationWorkItem
    WHERE DueDate < TODAY
      AND Status = 'InProgress'
    ORDER BY DueDate ASC
];

// Send escalation notifications
for (FlowOrchestrationWorkItem item : overdueItems) {
    sendEscalationEmail(item);
}
```

## Monitoring and Reporting

### FlowOrchestrationWorkItem Object

**Query work items for reporting**:
```apex
// Active orchestrations
List<FlowOrchestrationWorkItem> activeItems = [
    SELECT Id, Label, StepDefinitionName, AssignedToId,
           CreatedDate, LastModifiedDate, DueDate,
           Status, RelatedRecordId
    FROM FlowOrchestrationWorkItem
    WHERE Status = 'InProgress'
    ORDER BY DueDate ASC
];

// Calculate time spent in each step
for (FlowOrchestrationWorkItem item : activeItems) {
    Long milliseconds = item.LastModifiedDate.getTime() - item.CreatedDate.getTime();
    Decimal hours = milliseconds / (1000.0 * 60 * 60);
    System.debug('Step: ' + item.Label + ', Time: ' + hours + ' hours');
}
```

### Dashboard Metrics

**Key Metrics to Track**:
```sql
1. Average Time per Stage
   SELECT StepDefinitionName,
          AVG(LastModifiedDate - CreatedDate) as AvgDuration
   FROM FlowOrchestrationWorkItem
   WHERE Status = 'Completed'
   GROUP BY StepDefinitionName

2. Completion Rate by Assignee
   SELECT AssignedToId,
          COUNT(CASE WHEN Status = 'Completed' THEN 1 END) as Completed,
          COUNT(CASE WHEN DueDate < TODAY AND Status = 'InProgress' THEN 1 END) as Overdue
   FROM FlowOrchestrationWorkItem
   GROUP BY AssignedToId

3. Bottleneck Identification
   - Which steps take longest?
   - Which steps have highest rejection/failure rate?
   - Which assignees have most overdue items?
```

### Custom Dashboard Component

```apex
public class OrchestrationMetrics {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        // Total active orchestrations
        Integer active = [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Status = 'InProgress'];
        metrics.put('active', active);

        // Overdue count
        Integer overdue = [SELECT COUNT() FROM FlowOrchestrationWorkItem
                          WHERE Status = 'InProgress' AND DueDate < TODAY];
        metrics.put('overdue', overdue);

        // Average completion time (last 30 days)
        AggregateResult[] avgTime = [
            SELECT AVG(LastModifiedDate - CreatedDate) avgDuration
            FROM FlowOrchestrationWorkItem
            WHERE Status = 'Completed'
              AND CreatedDate = LAST_N_DAYS:30
        ];
        metrics.put('avgCompletionHours', (Decimal)avgTime[0].get('avgDuration') / (1000.0 * 60 * 60));

        return metrics;
    }
}
```

