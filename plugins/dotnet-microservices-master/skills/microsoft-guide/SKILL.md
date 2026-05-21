---
name: microsoft-guide
description: |
  Microsoft .NET Microservices Architecture Guide reference.
  PROACTIVELY activate for: (1) reading or applying patterns from Microsoft .NET Microservices Architecture for Containerized .NET Applications, (2) eShopOnContainers reference architecture, (3) DDD and bounded contexts, (4) integration events (RabbitMQ, Azure Service Bus), (5) API gateway patterns (Ocelot, YARP), (6) resilience patterns (Polly), (7) data patterns (CQRS, event sourcing), (8) testing strategies in microservices, (9) deployment to Kubernetes/AKS/Container Apps.
  Provides: chapter-by-chapter summary, code patterns from eShopOnContainers, decision matrices for sync vs async integration, and links into specific guide sections.
---

# Microsoft .NET Microservices Architecture Guide (v7.0)

This skill provides access to the complete official Microsoft guide: ".NET Microservices Architecture for Containerized .NET Applications" (Edition v7.0 - Updated to ASP.NET Core 7.0).

## When to Use This Skill

Invoke this skill when you need:
- **Detailed technical information** from the official Microsoft guide
- **Specific implementation patterns** or code examples
- **In-depth explanations** beyond your summarized knowledge
- **Official Microsoft recommendations** for microservices architecture
- **Reference to eShopOnContainers** implementation details
- **Comprehensive coverage** of specific topics (DDD, CQRS, Docker, Kubernetes, etc.)

## What This Skill Contains

The complete 350-page Microsoft guide (text content only) including:
- Container fundamentals and Docker concepts
- Choosing between .NET and .NET Framework
- Microservices architecture principles
- API Gateway patterns
- Event-driven architecture
- Domain-Driven Design (DDD) tactical and strategic patterns
- CQRS (Command Query Responsibility Segregation)
- Data management in microservices
- Resilience patterns (Circuit Breaker, Retry, Bulkhead)
- Security best practices
- Kubernetes and orchestration
- eShopOnContainers reference application details
- Complete code examples and implementation guidance
- All architectural concepts explained in text (diagrams removed for size optimization)

## How to Use

When a user asks about:
1. Specific technical details you need to verify
2. Code implementation examples
3. eShopOnContainers architecture details
4. Official Microsoft recommendations
5. Complex patterns requiring detailed explanations

Invoke this skill and follow the procedure below.

## Core Procedure

1. Restate the architecture decision or implementation question in concrete terms: boundary, service, data ownership, deployment target, and failure mode.
2. Search the guide for the relevant pattern rather than relying on memory alone.
3. Separate Microsoft guide recommendations from project-specific constraints or newer platform guidance.
4. Prefer decision matrices over one-size-fits-all answers for sync vs async calls, gateway placement, data ownership, and deployment topology.
5. When giving code or YAML, label it as a focused pattern excerpt and ask the implementation agent to adapt it to the user's runtime/version.
6. Call out trade-offs: autonomy vs consistency, latency vs resilience, operational simplicity vs scalability.

## Quick Pattern Map

| User intent | Guide area to inspect |
|---|---|
| Define service boundaries | DDD, bounded contexts, data ownership |
| Choose HTTP vs messaging | Communication in microservices, integration events |
| Add API gateway | API Gateway patterns, Ocelot/YARP considerations |
| Improve resilience | Retry, circuit breaker, timeout, health checks, Polly |
| Split databases | Data sovereignty, eventual consistency, CQRS |
| Deploy containers | Docker, Kubernetes, orchestrators, environment configuration |

---

## Full Microsoft Guide Content

The complete guide is available in this skill directory at:
`NET-Microservices-Architecture.md`

When you invoke this skill, you have access to read this file which contains the full 350-page Microsoft guide with all technical details, code examples, architecture patterns, and implementation guidance.

## Usage Instructions

When this skill is invoked:
1. Read the NET-Microservices-Architecture.md file in this directory
2. Use Grep to search for specific topics the user is asking about
3. Provide detailed, accurate answers based on the official Microsoft guide content
4. Reference specific sections and code examples from the guide
5. Cite the guide as the source of information

**Note**: The guide contains comprehensive text explanations of all concepts, patterns, and implementations. Image references have been removed to optimize plugin size (reduced from 18MB to ~800KB).
