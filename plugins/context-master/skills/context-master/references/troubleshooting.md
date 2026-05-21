# Context troubleshooting

Symptoms you may see in long or complex sessions, with universal and environment-specific remedies.

## "Responses are getting less focused"

Symptom: Claude references old, irrelevant information or responses drift off topic.

Solutions:
- Web/API: "Setting aside previous discussion, let's focus on..."
- Claude Code: `/clear` or `/compact`
- Universal: break task into new phases with clear boundaries

## "Complex task feels overwhelming"

Symptom: unsure where to start, too many moving parts.

Solutions:
1. "think harder about breaking this into phases"
2. Create a planning artifact
3. Execute one phase at a time
4. Reference plan artifact as you go

## "Conversation getting too long"

Symptom: long history, hard to track what's been decided.

Solutions:
- Web/API: create a `decisions.md` artifact to summarize key points
- Claude Code: `/compact` to compress history
- Universal: start a new conversation with "Previously we decided X, Y, Z. Now let's..."

## "Need to maintain context across sessions"

Symptom: having to re-explain everything each time.

Solutions:
- Create artifacts documenting key decisions and context.
- Claude Code: use `CLAUDE.md` for persistent project memory.
- Start new sessions with "Continuing from previous work where we [brief summary]".

## "Code keeps being regenerated instead of edited"

Symptom: small changes result in entire code rewrites.

Solutions:
1. Use artifacts for code.
2. Request specific edits: "Update the `handle_request` function to add validation".
3. Don't say "show me the code again" - reference the existing artifact.

## "Responses include too much explanation"

Symptom: lengthy explanations when you just want output.

Solutions:
- Be explicit: "Just create the artifact, minimal explanation".
- "Output only, no commentary".
- "Concise response please".

## "Extended thinking not being used"

Symptom: jumping straight to solutions without analysis.

Solutions:
- Explicitly request: "think hard about...".
- Use stronger triggers: "ultrathink about...".
- Ask for planning: "think about multiple approaches".
