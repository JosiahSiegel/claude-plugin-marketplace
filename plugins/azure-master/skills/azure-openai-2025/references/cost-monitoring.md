# Azure OpenAI: Cost Optimization, Monitoring, Alerts

Detailed cost optimization strategies, token budgeting, quota-aware routing, Azure Monitor metrics, Log Analytics queries, and alert rules for Azure OpenAI deployments. SKILL.md keeps latest models, deployment, usage, AI Foundry integration, capacity/quota, security/networking, and best practices.

## Cost Optimization

### Model Selection Strategy

**Use GPT-5-mini or GPT-5-nano for:**
- Simple questions
- Classification tasks
- Content moderation
- Summarization

**Use GPT-5 or GPT-4.1 for:**
- Complex reasoning
- Long-form content generation
- Document analysis
- Code generation

**Use Reasoning Models (o3, o4-mini) for:**
- Mathematical problems
- Scientific analysis
- Step-by-step reasoning
- Logic puzzles

### Implement Caching

```python
# Use semantic cache to reduce duplicate requests
from azure.ai.cache import SemanticCache

cache = SemanticCache(
    similarity_threshold=0.95,
    ttl_seconds=3600
)

# Check cache before API call
cached_response = cache.get(user_query)
if cached_response:
    return cached_response

response = client.chat.completions.create(
    model="gpt-5",
    messages=messages
)

cache.set(user_query, response)
```

### Token Management

```python
import tiktoken

# Count tokens before API call
encoding = tiktoken.get_encoding("cl100k_base")
tokens = len(encoding.encode(prompt))

if tokens > 100000:
    print(f"Warning: Prompt has {tokens} tokens, this will be expensive!")

# Use shorter max_tokens when appropriate
response = client.chat.completions.create(
    model="gpt-5",
    messages=messages,
    max_tokens=500  # Limit output tokens
)
```

## Monitoring and Alerts

### Set Up Cost Alerts

```bash
# Create budget alert
az consumption budget create \
  --budget-name openai-monthly-budget \
  --resource-group MyRG \
  --amount 1000 \
  --category Cost \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2025-12-31 \
  --notifications '{
    "actual_GreaterThan_80_Percent": {
      "enabled": true,
      "operator": "GreaterThan",
      "threshold": 80,
      "contactEmails": ["billing@example.com"]
    }
  }'
```

### Application Insights Integration

```python
from opencensus.ext.azure.log_exporter import AzureLogHandler
import logging

# Configure logging
logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
))

# Log API calls
logger.info("OpenAI API call", extra={
    "custom_dimensions": {
        "model": "gpt-5",
        "tokens": response.usage.total_tokens,
        "cost": calculate_cost(response.usage.total_tokens),
        "latency_ms": response.response_ms
    }
})
```

