# .NET Microservices Architecture Expert

A Claude Code agent with comprehensive knowledge of .NET microservices architecture, containerization, Docker, DDD, CQRS, and cloud-native patterns. Based on Microsoft's official ".NET Microservices Architecture for Containerized .NET Applications" guide (v7.0).

## What is This?

This plugin provides a specialized AI agent that acts as your personal .NET microservices architect. The agent has mastered the entire Microsoft .NET Microservices Architecture guide and can help you with:

- 🏗️ **Architecture design** - Microservices patterns, API Gateways, event-driven systems
- 🐳 **Docker & Containers** - Containerization, docker-compose, multi-container apps  
- ☸️ **Kubernetes & Azure** - AKS deployment, Helm charts, cloud-native patterns
- 🎯 **DDD & CQRS** - Domain-Driven Design, aggregates, repositories, CQRS patterns
- 🔄 **Resilience** - Circuit Breaker, Retry, Bulkhead patterns with Polly
- 🔒 **Security** - Authentication, authorization, secrets management
- 📊 **Data Management** - Database per service, eventual consistency, event sourcing
- 🚀 **eShopOnContainers** - Deep knowledge of Microsoft's reference application

## Installation

### Via Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace

# Install the plugin
/plugin install dotnet-microservices-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use marketplace installation method instead.

```bash
# Extract ZIP to plugins directory
unzip dotnet-microservices-expert.zip -d ~/.local/share/claude/plugins/
```

## Usage

Once installed, the agent is available in Claude Code:

```bash
# View available agents
/agents

# The agent will be available as ".NET Microservices Architect"
```

Simply select the agent and start asking questions about .NET microservices architecture!

## Example Questions

### Architecture & Design
- "Should I use microservices for my new application?"
- "How do I design API Gateways for my microservices?"
- "What's the difference between synchronous and asynchronous communication?"
- "How do I implement the event bus pattern with RabbitMQ?"

### Domain-Driven Design
- "Explain aggregates and aggregate roots in DDD"
- "How do I identify bounded contexts for my microservices?"
- "When should I use value objects vs entities?"
- "How do domain events work in the ordering microservice?"

### CQRS Patterns
- "How do I implement CQRS in .NET?"
- "Should I use separate databases for read and write models?"
- "What's the role of MediatR in CQRS?"
- "How does eShopOnContainers implement queries with Dapper?"

### Implementation
- "How do I use IHttpClientFactory with Polly for resilience?"
- "Show me how to implement the repository pattern with EF Core"
- "How do I create integration events between microservices?"
- "What's the best way to handle transactions across services?"

### Containers & Deployment
- "How do I create a Dockerfile for a .NET 7 API?"
- "What's the difference between docker-compose and Kubernetes?"
- "How do I deploy microservices to Azure Kubernetes Service?"
- "Explain Helm charts for .NET microservices"

### Resilience & Security
- "How do I implement circuit breaker pattern?"
- "What retry strategies should I use?"
- "How do I implement health checks in ASP.NET Core?"
- "What's the best authentication strategy for microservices?"

## Agent Knowledge Base

The agent has deep expertise in:

**Core Technologies:**
- .NET 7 / ASP.NET Core 7
- Docker & Docker Compose
- Kubernetes (AKS)
- Azure cloud services

**Architectural Patterns:**
- Microservices architecture
- API Gateway pattern (Ocelot)
- Event-driven architecture
- CQRS and Event Sourcing
- Domain-Driven Design (DDD)

**Implementation Patterns:**
- Repository and Unit of Work
- Command and Query handlers
- Domain events
- Integration events
- Aggregate pattern

**Resilience Patterns:**
- Circuit Breaker (Polly)
- Retry with exponential backoff
- Bulkhead isolation
- Timeout policies
- Health checks

**Data Management:**
- Entity Framework Core
- Dapper for queries
- Database per service pattern
- Eventual consistency
- Saga pattern

**Security:**
- OAuth 2.0 / OpenID Connect
- IdentityServer
- JWT bearer tokens
- Azure Key Vault
- Managed Identity

## Based On

This agent's knowledge comes from the official Microsoft guide:
**".NET Microservices Architecture for Containerized .NET Applications"**
- Edition v7.0 (Updated to ASP.NET Core 7.0)
- 350 pages of comprehensive guidance
- Reference application: eShopOnContainers

## Real-World Applications

The agent can help you:

1. **Design new microservices systems** from scratch
2. **Migrate monoliths** to microservices architecture  
3. **Implement DDD patterns** in your domain model
4. **Add resilience** to existing services
5. **Deploy to Kubernetes** with best practices
6. **Troubleshoot** architectural issues
7. **Review** microservices designs

## Best Suited For

- **Architects** designing .NET microservices systems
- **Developers** implementing microservices patterns
- **DevOps engineers** deploying containerized apps
- **Technical leads** making architecture decisions
- **Teams** adopting microservices architecture

## Not a Replacement For

While the agent is highly knowledgeable, it's not a replacement for:
- Reading the full Microsoft guide (highly recommended!)
- Hands-on experience building microservices
- Understanding your specific business requirements
- Proper testing and validation

## Windows & Git Bash Compatibility

This plugin is fully compatible with Windows development environments and Git Bash:

### ✅ Path Handling
- Automatically converts Git Bash paths (`/s/repos/`) to Windows format (`S:\repos\`)
- Handles Docker volume mounts correctly across platforms
- Works seamlessly with .NET CLI in Git Bash

### 🔧 Common Scenarios
- **Creating microservices:** Works with both PowerShell and Git Bash
- **Dockerfile generation:** Handles path formats correctly
- **Docker Compose:** Creates files compatible with Windows Docker Desktop
- **.NET project files:** Manages .csproj and .sln files with proper paths

### 💡 Tip for Git Bash Users
If working in Git Bash on Windows, use `pwd -W` to get Windows-formatted paths that the agent can work with directly.

## Tips for Best Results

1. **Be specific** about your scenario and constraints
2. **Mention your tech stack** (Azure, AWS, on-prem)
3. **Ask about trade-offs** to make informed decisions
4. **Request code examples** when you need implementation guidance
5. **Reference eShopOnContainers** for concrete examples
6. **On Windows with Git Bash:** Use `pwd -W` for paths

## Agent Characteristics

The .NET Microservices Expert agent:
- ✅ Provides practical, production-ready guidance
- ✅ Explains trade-offs and when NOT to use patterns
- ✅ References eShopOnContainers for examples
- ✅ Understands Azure services and integration
- ✅ Balances theory with real-world pragmatism
- ✅ Offers code examples in C#
- ❌ Doesn't over-engineer simple problems
- ❌ Doesn't recommend microservices for every scenario
- ❌ Doesn't ignore operational complexity

## Example Interaction

```text
You: I need to build an e-commerce platform. Should I use microservices?

Agent: Let me help you think through this decision. First, consider:

1. **Team size:** Do you have multiple teams that could own separate services?
2. **Complexity:** Does your domain have distinct bounded contexts (catalog, ordering, 
   payment, shipping)?
3. **Scale requirements:** Do different parts need to scale independently?
4. **Deployment needs:** Do you need to deploy features independently?

For e-commerce, microservices can work well because you naturally have boundaries 
like Catalog, Ordering, Basket, Payment, and Identity. However, if you're a small 
team (<10 developers), I'd recommend starting with a modular monolith using clean 
boundaries, then extracting microservices as you grow.

Want me to walk through how eShopOnContainers structures its microservices for 
e-commerce?
```

## Resources

- **eShopOnContainers GitHub:** https://github.com/dotnet-architecture/eShopOnContainers
- **Microsoft Architecture Guide:** https://docs.microsoft.com/dotnet/architecture/microservices/
- **Azure Kubernetes Service:** https://azure.microsoft.com/services/kubernetes-service/
- **Polly Resilience:** https://github.com/App-vNext/Polly

## License

MIT

## Contributing

Have improvements or found issues? Contributions welcome!

---

**Ready to master .NET microservices architecture? Install the plugin and start asking questions!** 🚀
