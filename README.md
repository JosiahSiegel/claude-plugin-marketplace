# Claude Plugin Marketplace

> A curated collection of Claude Code plugins for plugin development, context optimization, cloud infrastructure, DevOps automation, and productivity tools.

## Quick start

**1. Add this marketplace:**

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
```

**2. Install any plugin:**

```bash
/plugin install <plugin-name>@claude-plugin-marketplace
```

**3. Browse the plugin catalog and install what you need.**

Plugin versions are defined in [`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json) and mirrored in each plugin's `.claude-plugin/plugin.json`. Treat the marketplace manifest as the source for the full, current catalog; the list below highlights commonly used plugins.

## Available plugins

### Core development tools

- **[plugin-master](./plugins/plugin-master)** ([Docs](./plugins/plugin-master/README.md)) - Claude Code plugin development with skills, commands, agents, hooks, MCP integration, testing, and marketplace publishing guidance.
- **[context-master](./plugins/context-master)** ([Docs](./plugins/context-master/README.md)) - Context management for complex multi-file tasks, planning, delegation, token budgeting, and long-running sessions.
- **[doc-master](./plugins/doc-master)** ([Docs](./plugins/doc-master/README.md)) - Documentation diagnostic, Markdown style, and ADR expert that routes docs to the right form before drafting.

### Cloud and infrastructure

- **[azure-master](./plugins/azure-master)** ([Docs](./plugins/azure-master/README.md)) - Azure resource provisioning, AI Foundry, networking, deployment stacks, debugging, and cost optimization.
- **[azure-to-docker-master](./plugins/azure-to-docker-master)** ([Docs](./plugins/azure-to-docker-master/README.md)) - Azure-to-Docker migration for local development, Compose generation, emulators, and dev-to-prod parity.
- **[terraform-master](./plugins/terraform-master)** ([Docs](./plugins/terraform-master/README.md)) - Terraform and OpenTofu guidance for IaC design, state management, imports, providers, validation, and CI/CD.

### DevOps and CI/CD

- **[docker-master](./plugins/docker-master)** ([Docs](./plugins/docker-master/README.md)) - Docker build, run, debug, optimization, Compose, container security, networking, and registry workflows.
- **[ado-master](./plugins/ado-master)** ([Docs](./plugins/ado-master/README.md)) - Azure DevOps and Azure Pipelines YAML, identity, security, templates, analytics, and troubleshooting.
- **[git-master](./plugins/git-master)** ([Docs](./plugins/git-master/README.md)) - Git and GitHub workflows, history recovery, signed commits, worktrees, sparse checkouts, and repository operations.

### Scripting and automation

- **[bash-master](./plugins/bash-master)** ([Docs](./plugins/bash-master/README.md)) - Bash and shell scripting, ShellCheck guidance, POSIX portability, security-first patterns, and cross-platform execution.
- **[powershell-master](./plugins/powershell-master)** ([Docs](./plugins/powershell-master/README.md)) - PowerShell scripting, modules, CI/CD automation, cloud administration, debugging, and cross-platform patterns.

### Testing and quality

- **[test-master](./plugins/test-master)** ([Docs](./plugins/test-master/README.md)) - Vitest, Playwright, MSW, unit/integration/E2E testing, debugging, coverage, and CI test setup.

### Backend and microservices

- **[dotnet-microservices-master](./plugins/dotnet-microservices-master)** ([Docs](./plugins/dotnet-microservices-master/README.md)) - .NET microservices architecture, Docker, DDD, CQRS, resilience, API gateways, and cloud-native patterns.

### Languages and frameworks

- **[python-master](./plugins/python-master)** ([Docs](./plugins/python-master/README.md)) - Python, asyncio, typing, FastAPI, testing, packaging, performance, security, and deployment.
- **[react-master](./plugins/react-master)** ([Docs](./plugins/react-master/README.md)) - React components, hooks, state management, TypeScript, forms, performance, and testing.
- **[nextjs-master](./plugins/nextjs-master)** ([Docs](./plugins/nextjs-master/README.md)) - Next.js App Router, Server Components, Server Actions, caching, middleware, auth, and deployment.
- **[tailwindcss-master](./plugins/tailwindcss-master)** ([Docs](./plugins/tailwindcss-master/README.md)) - Tailwind CSS configuration, utilities, responsive design, dark mode, performance, and framework integration.
- **[ffmpeg-master](./plugins/ffmpeg-master)** ([Docs](./plugins/ffmpeg-master/README.md)) - FFmpeg meta-bundle for encoding, effects, platform deployment, Python integrations, and social-video workflows.

### Database and data

- **[ssdt-master](./plugins/ssdt-master)** ([Docs](./plugins/ssdt-master/README.md)) - SQL Server Data Tools, SqlPackage, DACPAC/BACPAC workflows, schema comparison, and database CI/CD.
- **[adf-master](./plugins/adf-master)** ([Docs](./plugins/adf-master/README.md)) - Azure Data Factory pipeline JSON, activities, linked services, datasets, triggers, expressions, and deployment.
- **[tsql-master](./plugins/tsql-master)** ([Docs](./plugins/tsql-master/README.md)) - T-SQL query optimization, execution plans, indexing, Query Store, window functions, and Azure SQL tuning.

### Platform-specific

- **[salesforce-master](./plugins/salesforce-master)** ([Docs](./plugins/salesforce-master/README.md)) - Salesforce API, Apex, Lightning, Flow, data model, integrations, deployment, and security patterns.
- **[windows-path-master](./plugins/windows-path-master)** ([Docs](./plugins/windows-path-master/README.md)) - Windows path resolution and Git Bash compatibility for Claude Code file operations.
- **[cloudflare-master](./plugins/cloudflare-master)** ([Docs](./plugins/cloudflare-master/README.md)) - Cloudflare Workers, Pages, AI, storage primitives, Zero Trust, MCP, observability, and CI/CD.

## 🤝 Contributing

Want to add a plugin to this marketplace? See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for guidelines.

## 📊 Marketplace Info

- **Owner:** Josiah Siegel
- **Repository:** https://github.com/JosiahSiegel/claude-plugin-marketplace
- **License:** MIT
- **Issues:** [Report here](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)

## 📄 License

MIT - See [LICENSE](./LICENSE) for details.
