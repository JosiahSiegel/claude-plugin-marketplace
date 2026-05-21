---
name: flow-orchestrator-2025
description: |
  Salesforce Flow Orchestrator for multi-user, multi-step business processes (2025).
  PROACTIVELY activate for: (1) building Flow Orchestrations (autolaunched and screen flows), (2) work assignment to users, queues, or roles, (3) interactive vs background steps, (4) approval-style workflows in Flow, (5) parallel and sequential stages, (6) Flow Orchestrator events (StageCompleted, OrchestrationCanceled), (7) error handling and resume patterns, (8) testing orchestrations, (9) migrating from legacy Process Builder/Workflow Rules, (10) Flow Orchestrator vs Approval Process tradeoffs.
  Provides: orchestration design patterns, stage/step templates, error-handling recipes, and migration guidance.
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

# Salesforce Flow Orchestrator (2025)

## What is Flow Orchestrator?

Flow Orchestrator coordinates multi-user, multi-step, multi-stage business processes without code. Different users complete sequential tasks in one workflow with built-in approvals, conditional logic, and error handling.

**Key Capabilities**:
- **Multi-User Workflows**: Assign tasks to different users/teams across stages
- **Stage-Based Execution**: Organize work into logical stages
- **Background Automation**: Combine user tasks with automated steps
- **Visual Progress Tracking**: Users see their position in the workflow
- **Fault Paths**: Handle errors gracefully (Summer '25)
- **No-Code**: Build complex processes without Apex

## When to Use Flow Orchestrator

| Use Case | Flow Orchestrator? | Why |
|----------|-------------------|-----|
| Employee Onboarding (HR → IT → Manager) | ✅ Yes | Multi-user, sequential stages |
| Quote-to-Cash (Sales → Finance → Operations) | ✅ Yes | Cross-functional approval process |
| Case Escalation (L1 → L2 → L3 Support) | ✅ Yes | Tiered assignment with SLAs |
| Simple record automation (create/update) | ❌ No | Use Record-Triggered Flow |
| Single-user process | ❌ No | Use Screen Flow |
| Batch data processing | ❌ No | Use Scheduled Flow or Apex Batch |

## Orchestration Architecture

```text
Orchestration = Stages → Steps → Background Automations

Stage 1: "HR Review"
├─ Step 1.1: Interactive Step (HR Manager reviews)
├─ Step 1.2: Background Automation (create records)
└─ Decision: Approved? → Next Stage : End

Stage 2: "IT Provisioning"
├─ Step 2.1: Interactive Step (IT assigns equipment)
├─ Step 2.2: Background Automation (provision accounts)
└─ Step 2.3: Interactive Step (IT confirms completion)

Stage 3: "Manager Onboarding"
├─ Step 3.1: Interactive Step (Manager schedules 1:1)
└─ Step 3.2: Background Automation (send welcome email)
```

## Building an Orchestration (Step-by-Step)

### Example: Employee Onboarding Process

**Requirements**:
- HR reviews new hire documents → Approved/Rejected
- If approved, IT provisions accounts and equipment
- Manager schedules first day and assigns mentor
- System sends notifications at each stage

### Step 1: Create Orchestration

```yaml
Setup → Flows → New Flow → Orchestration
Name: Employee_Onboarding
Object: Employee__c (custom object)
Trigger: Record Created, Status = 'Pending Onboarding'
```

### Step 2: Design Stages

**Stage 1: HR Document Review**
```text
Stage Name: HR_Document_Review
Stage Description: HR verifies employee documentation
Run Mode: One at a Time (sequential)

Step 1.1 (Interactive):
- Name: Review_Documents
- Assigned To: Queue "HR_Onboarding_Queue"
- Due Date: 2 days from start
- Screen Flow: HR_Document_Review_Screen
- Inputs: Employee__c.Id

Step 1.2 (Background - Decision):
- If HR_Approved = true → Next Stage
- If HR_Approved = false → End + Send Rejection Email
```

**Stage 2: IT Provisioning**
```text
Stage Name: IT_Provisioning
Condition: Runs only if Stage 1 approved

Step 2.1 (Interactive):
- Name: Assign_Equipment
- Assigned To: Queue "IT_Provisioning_Queue"
- Due Date: 3 days from stage start
- Screen Flow: IT_Equipment_Assignment
- Inputs: Employee__c.Id

Step 2.2 (Background):
- Name: Create_AD_Account
- Autolaunched Flow: Create_Active_Directory_Account
- Inputs: Employee__c.Email, Employee__c.FirstName

Step 2.3 (Background):
- Name: Send_IT_Confirmation
- Action: Send Email Template
- Recipient: Employee__c.Email
- Template: Welcome_Email
```

**Stage 3: Manager Setup**
```text
Stage Name: Manager_Setup
Depends On: Stage 2 complete

Step 3.1 (Interactive):
- Name: Schedule_First_Day
- Assigned To: Employee__c.Manager__c
- Due Date: 1 day from stage start
- Screen Flow: Manager_Onboarding_Tasks

Step 3.2 (Background):
- Name: Update_Status
- Record Update: Employee__c.Status = 'Onboarding Complete'
```

### Step 3: Implement Fault Paths (Summer '25)

**Fault Path on IT Provisioning Failure**:
```text
If Step 2.2 (Create_AD_Account) fails:
├─ Retry Step (1 attempt after 10 minutes)
├─ If still fails:
│  ├─ Send email to IT Manager with error details
│  ├─ Create Task for manual provisioning
│  └─ Assign Interactive Step to IT Manager for resolution
└─ Continue to Stage 3 (don't block entire process)
```

**Configuration**:
```text
Step 2.2: Create_AD_Account
├─ Fault Path Enabled: true
├─ Retry Attempts: 1
├─ Retry Delay: 10 minutes
└─ On Final Failure:
   ├─ Create Task
   │  ├─ Subject: "Manual AD Account Creation Needed"
   │  ├─ Assigned To: IT_Manager_Queue
   │  └─ Priority: High
   └─ Send Email Notification
      ├─ Template: IT_Provisioning_Failure
      └─ Recipients: IT Managers
```

## Interactive Steps vs Background Steps

### Interactive Steps

**Use for**: Actions requiring human judgment or input

```text
Interactive Step Configuration:
├─ Screen Flow: Define UI for user input
├─ Assigned To: User, Queue, or Role
├─ Due Date: Formula (TODAY() + 2 for 2 days)
├─ Instructions: What user should do
├─ Input Variables: Data passed to screen flow
└─ Output Variables: Data returned from user
```

**Example Screen Flow** (HR Review):
```text
Screen: Review Documents
├─ Display: Employee Name, Position, Documents Uploaded
├─ Input: Radio Button (Approve / Reject)
├─ Input: Text Area (Comments - required if reject)
└─ Action: Save & Submit

Output Variables:
- HR_Approved (Boolean)
- HR_Comments (Text)
```

### Background Steps

**Use for**: Automated actions without user interaction

```text
Background Step Types:
├─ Autolaunched Flow: Call another flow
├─ Apex Action: Invoke Apex method
├─ Send Email: Email template or custom
├─ Post to Chatter: Notify users
├─ Create Records: DML operations
├─ Update Records: Field updates
├─ External Service: REST callout
└─ Wait: Pause for duration or until condition
```

## Advanced Patterns and Monitoring

Advanced Flow Orchestrator designs (parallel approvals, conditional branches, retry / escalation, record-triggered orchestration, external integration handoffs) plus monitoring, reporting, and operational dashboards live in `references/advanced-patterns-monitoring.md`. Load that reference for complex multi-stage implementations and production observability.

## Integration with Other Features

### Pattern: Orchestration + Approval Process

```text
Stage 2: Manager Approval
├─ Step 2.1 (Interactive): Manager reviews
│  └─ Screen Flow with Approve/Reject buttons
├─ Background Automation: Update approval status
└─ If Approved: Proceed to Stage 3
   If Rejected: Send rejection email, End orchestration
```

### Pattern: Orchestration + Platform Events

**Publish events at stage transitions**:
```apex
trigger OrchestrationStageTrigger on FlowOrchestrationStageInstance (after insert, after update) {
    List<OrchestrationStageEvent__e> events = new List<OrchestrationStageEvent__e>();

    for (FlowOrchestrationStageInstance stage : Trigger.new) {
        if (stage.Status == 'Completed') {
            events.add(new OrchestrationStageEvent__e(
                OrchestrationId__c = stage.OrchestrationInstanceId,
                StageName__c = stage.StepDefinitionName,
                CompletedDate__c = System.now()
            ));
        }
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}
```

**Subscribe externally**:
```javascript
// External system tracks orchestration progress
client.subscribe('/event/OrchestrationStageEvent__e', (message) => {
    const { OrchestrationId__c, StageName__c } = message.data.payload;
    console.log(`Stage ${StageName__c} completed for ${OrchestrationId__c}`);

    // Update external dashboard
    updateOrchestrationStatus(OrchestrationId__c, StageName__c);
});
```

### Pattern: Orchestration + Agentforce

**AI agent handles certain steps**:
```text
Stage 2: Document Verification
├─ Step 2.1 (Background): AI agent verifies documents
│  └─ Agentforce Action: Verify_Document_Compliance
│     - Uses Einstein OCR to extract text
│     - Uses LLM to validate against compliance rules
│     - Returns: Compliant (true/false) + Confidence score
├─ Decision: If confidence < 90% → Human review
└─ Step 2.2 (Interactive - Conditional): Human verifies (if AI uncertain)
```

## Best Practices

### Design
- **Plan stages before building**: Sketch workflow on paper/whiteboard
- **One business process per orchestration**: Don't combine unrelated processes
- **Meaningful stage/step names**: Use business terminology, not technical jargon
- **Clear instructions**: Tell users exactly what to do in each step
- **Appropriate due dates**: Balance urgency with realistic timelines

### Performance
- **Minimize steps per stage**: <10 steps per stage for maintainability
- **Avoid unnecessary waits**: Only pause when truly needed
- **Bulkify background automations**: Process multiple records efficiently
- **Use decision logic wisely**: Skip unnecessary stages with conditions
- **Monitor active orchestrations**: Archive completed ones regularly

### Error Handling
- **Always implement fault paths** (Summer '25): Don't let failures block entire process
- **Retry transient errors**: Network issues, temporary API failures
- **Escalate permanent errors**: Create tasks for manual intervention
- **Log failures**: Track what went wrong for troubleshooting
- **Test error scenarios**: Intentionally trigger failures in sandbox

### Security
- **Respect sharing rules**: Use "with sharing" in Apex called by orchestrations
- **Field-level security**: Ensure users have access to fields in screen flows
- **Queue membership**: Verify users in queues have necessary permissions
- **Sensitive data**: Mask or encrypt PII in screen flows and work items

### User Experience
- **Mobile-friendly screens**: Many users work on mobile devices
- **Progress indicators**: Show users where they are in process
- **Clear next steps**: Always tell users what happens after they complete a step
- **Timely notifications**: Send reminders before due dates
- **Feedback on submission**: Confirm action was successful

## Troubleshooting

### Common Issues

**Issue 1: Work items not appearing for users**
```yaml
Causes:
- User not in assigned queue
- User lacks permission to object
- Filter criteria on view excludes item

Solution:
1. Check queue membership: Setup → Queues
2. Verify object permissions: User profile/permission set
3. Review work item list view filters
```

**Issue 2: Background step failing silently**
```yaml
Causes:
- Apex error in called flow/action
- Required field missing
- Governor limit exceeded

Solution:
1. Enable debug logs: Setup → Debug Logs
2. Check Flow error emails: Setup → Process Automation Settings
3. Implement fault path to catch and handle errors
```

**Issue 3: Orchestration not triggering**
```yaml
Causes:
- Trigger criteria not met
- Record not updated properly
- Orchestration inactive

Solution:
1. Verify record meets entry criteria
2. Check orchestration activation status
3. Review audit trail for record updates
```

### Debug with Apex

```apex
// Query orchestration details for debugging
public class OrchestrationDebugger {
    public static void debugOrchestration(Id recordId) {
        // Find orchestration instances for record
        List<FlowOrchestrationInstance> instances = [
            SELECT Id, Label, Status, CreatedDate
            FROM FlowOrchestrationInstance
            WHERE RelatedRecordId = :recordId
            ORDER BY CreatedDate DESC
        ];

        for (FlowOrchestrationInstance instance : instances) {
            System.debug('Orchestration: ' + instance.Label);
            System.debug('Status: ' + instance.Status);

            // Get work items
            List<FlowOrchestrationWorkItem> items = [
                SELECT Id, Label, Status, AssignedToId, DueDate
                FROM FlowOrchestrationWorkItem
                WHERE OrchestrationInstanceId = :instance.Id
                ORDER BY CreatedDate
            ];

            for (FlowOrchestrationWorkItem item : items) {
                System.debug('  Step: ' + item.Label + ', Status: ' + item.Status);
            }
        }
    }
}
```

## Pricing and Availability

- **Editions**: Enterprise, Performance, Unlimited, Developer
- **Included Runs**: 600 orchestration runs/year (no charge)
- **Additional Runs**: Purchase in blocks for high-volume use
- **Permissions Required**:
  - **Create/Edit**: Manage Flows permission
  - **View**: View Orchestration in Automation App (Winter '26)
  - **Approve Flows**: Approval Designer system permission (Winter '26)

## Resources

- **Flow Orchestrator Guide**: https://help.salesforce.com/s/articleView?id=platform.orchestrator_flow_orchestrator.htm
- **Trailhead**: "Flow Orchestration Basics"
- **Release Notes**: Summer '25 and Winter '26 for latest features
- **FlowOrchestrationWorkItem Reference**: Salesforce Object Reference documentation

## Migration from Process Builder

**Process Builder → Flow Orchestrator**:
```text
Process Builder supports only simple automation
Flow Orchestrator adds:
- Multi-user coordination
- Interactive steps
- Stage-based organization
- Visual progress tracking
- Fault handling

When to migrate:
- Process involves multiple users
- Need stage-based workflow
- Want user interface for steps
- Require better error handling
```

Flow Orchestrator transforms complex, cross-functional business processes into visual, manageable workflows that scale across your organization.
