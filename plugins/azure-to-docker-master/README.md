# Azure-to-Docker Master Plugin

> Complete Azure-to-Docker migration system for creating production-ready local development environments with 2025 best practices.

## Overview

The **azure-to-docker-master** plugin provides autonomous expertise for migrating Azure infrastructure to local Docker-based development environments. It extracts Azure resource configurations, generates optimized Docker Compose stacks with Azure service emulators, creates production-ready Dockerfiles, and exports databases—all following 2025 industry standards.

## Why Use This Plugin?

- **Autonomous Azure Migration**: Automatically extract Azure infrastructure and convert to Docker
- **2025 Azure Emulators**: Latest emulators (Azurite, SQL Server 2025, Cosmos DB, Service Bus)
- **Production-Ready Compose**: Generate secure, optimized docker-compose.yml with health checks
- **Complete Database Export**: Export and import Azure SQL/PostgreSQL/MySQL to Docker
- **Modern Best Practices**: No version field (Compose v2.42+), security hardening, resource limits
- **Development-Production Parity**: Mirror Azure infrastructure locally for efficient development

## Key Features

### Azure Service Mapping

Maps all Azure services to their Docker equivalents:

| Azure Service | Docker Image | Purpose |
|---------------|-------------|---------|
| App Service | Custom build | Application containers |
| Azure SQL Database | `mcr.microsoft.com/mssql/server:2025-latest` | SQL Server with AI features |
| PostgreSQL | `postgres:16.6-alpine` | PostgreSQL database |
| MySQL | `mysql:9.2` | MySQL database |
| Redis Cache | `redis:7.4-alpine` | Redis cache |
| Storage Account | `mcr.microsoft.com/azure-storage/azurite` | Blob/Queue/Table storage |
| Cosmos DB | `mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview` | NoSQL database |
| Service Bus | `mcr.microsoft.com/azure-messaging/servicebus-emulator` or `rabbitmq:3.14-alpine` | Message queue |
| App Insights | `jaegertracing/all-in-one` | Observability |

### 2025 Features

**Azure Emulators:**
- Azurite: Azure Storage emulator (v3.35.0, API 2025-11-05)
- SQL Server 2025: Latest with Vector Search and AI features
- Cosmos DB Emulator: vnext-preview (Linux-based, ARM64 support)
- Service Bus Emulator: Official Docker container (mcr.microsoft.com/azure-messaging/servicebus-emulator)

**Docker Compose v2.42+:**
- No `version` field (obsolete in 2025)
- Health check conditions for dependencies
- Multi-environment configuration (dev/prod)
- YAML anchors for reusable config
- Docker Compose Watch mode (GA) for hot reload

**Security Hardening:**
- Non-root users in all containers
- Read-only filesystems with tmpfs
- Capability drops (ALL) and selective adds
- `no-new-privileges` security option
- Runtime-only secrets (mounted in /run/secrets, never persisted)
- Secrets management (Docker secrets)

**Production Patterns:**
- Resource limits (CPU, memory)
- Comprehensive health checks
- Network isolation (frontend/backend)
- Logging configuration
- Restart policies

## Installation

### From Claude Code Marketplace

```bash
# Add to your project
claude-code plugin add azure-to-docker-master
```

### From GitHub

```bash
git clone https://github.com/JosiahSiegel/claude-plugin-marketplace.git
cd claude-plugin-marketplace/plugins/azure-to-docker-master
```

## Commands

### `/extract-infrastructure`

Extract Azure infrastructure and generate Docker Compose stack.

**What it does:**
1. Authenticates with Azure CLI
2. Extracts resource configurations (App Services, databases, caches, storage)
3. Analyzes service dependencies
4. Maps Azure services to Docker equivalents
5. Generates production-ready docker-compose.yml
6. Creates .env.template with all required variables
7. Generates Makefile for common operations
8. Produces comprehensive README

**Usage:**
```bash
/azure-to-docker-master:extract-infrastructure
```

**Example output:**
```
azure-project/
├── docker-compose.yml          # Main compose file
├── docker-compose.override.yml # Development overrides
├── .env.template               # Environment variables
├── Makefile                    # Common operations
├── README.md                   # Setup documentation
├── init/                       # Database init scripts
│   ├── 01-create-db.sql
│   └── 02-seed-data.sql
└── secrets/                    # Secrets (gitignored)
    ├── sa_password.txt
    └── postgres_password.txt
```

### `/generate-dockerfile`

Generate production-ready Dockerfiles from Azure App Service configurations.

**What it does:**
1. Analyzes App Service runtime stack
2. Selects appropriate base image
3. Generates multi-stage Dockerfile
4. Applies security hardening
5. Implements health checks
6. Optimizes layer caching
7. Creates .dockerignore

**Supports:**
- .NET (Core, Framework)
- Node.js
- Python
- Java (Spring Boot)
- PHP
- Static sites (Next.js, Angular)

**Usage:**
```bash
/azure-to-docker-master:generate-dockerfile
```

### `/export-database`

Export Azure databases and import into local Docker containers.

**What it does:**
1. Configures Azure firewall rules
2. Exports database (BACPAC, SQL script, pg_dump, mysqldump)
3. Transfers to local environment
4. Imports into Docker container
5. Verifies data integrity
6. Cleans up firewall rules

**Supports:**
- Azure SQL Database
- Azure Database for PostgreSQL
- Azure Database for MySQL

**Usage:**
```bash
/azure-to-docker-master:export-database
```

## Skills

### `azure-emulators-2025`

Comprehensive knowledge of Azure service emulators:
- Azurite (Storage)
- SQL Server 2025
- Cosmos DB Emulator
- Service Bus Emulator
- PostgreSQL
- MySQL
- Redis

Includes configuration examples, connection strings, limitations, and migration checklists.

### `compose-patterns-2025`

Production Docker Compose patterns:
- Multi-environment strategy
- Security hardening
- Health checks
- Dependency management
- Network isolation
- Resource limits
- YAML anchors
- Validation and testing

## Agent

### `azure-docker-expert`

Specialized agent for generating Docker Compose files from Azure configurations. Provides:
- Azure service mapping expertise
- 2025 emulator configuration
- Production-ready patterns
- Security best practices
- Network architecture
- Volume management
- Health check strategies

## Quick Start

### 1. Extract Azure Infrastructure

```bash
# Authenticate with Azure
az login

# Extract infrastructure
/azure-to-docker-master:extract-infrastructure

# Follow prompts to select resource group
```

### 2. Review Generated Files

```bash
# Validate Compose syntax
docker compose config

# Check services
docker compose config --services

# Review environment template
cat .env.template
```

### 3. Configure Environment

```bash
# Copy template and set passwords
cp .env.template .env
nano .env  # Set all passwords
```

### 4. Start Services

```bash
# Using Makefile
make up

# Or directly
docker compose up -d

# Check status
make health
# Or
docker compose ps
```

### 5. Export Databases (Optional)

```bash
/azure-to-docker-master:export-database

# Follow prompts for database selection
```

### 6. Generate Dockerfiles for Apps

```bash
/azure-to-docker-master:generate-dockerfile

# For each App Service in Azure
```

## Example Scenarios

### Scenario 1: Simple Web App + Database

**Azure Resources:**
- 1 App Service (Node.js)
- 1 Azure SQL Database

**Generated Stack:**
```yaml
services:
  webapp:
    build: ./webapp
    ports: ["8080:8080"]
    depends_on:
      sqlserver:
        condition: service_healthy

  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    healthcheck: ...
```

### Scenario 2: Three-Tier Application

**Azure Resources:**
- Frontend App Service (React)
- Backend App Service (.NET)
- Azure SQL Database
- Redis Cache
- Storage Account

**Generated Stack:**
```yaml
services:
  frontend:
    build: ./frontend
    networks: [frontend]

  backend:
    build: ./backend
    networks: [frontend, backend]

  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    networks: [backend]

  redis:
    image: redis:7.4-alpine
    networks: [backend]

  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    networks: [backend]
```

### Scenario 3: Microservices Architecture

**Azure Resources:**
- 5 App Services (microservices)
- Azure SQL + Cosmos DB
- Redis Cache
- Service Bus
- Application Insights

**Generated Stack:**
- Nginx gateway
- 5 microservice containers
- SQL Server 2025 + Cosmos DB Emulator
- Redis
- RabbitMQ (Service Bus alternative)
- Jaeger + Grafana (monitoring)
- Complete network isolation
- Health checks for all services

## Configuration Examples

### Environment Variables

```bash
# .env file
# SQL Server
MSSQL_SA_PASSWORD=YourStrong!Passw0rd

# PostgreSQL
POSTGRES_PASSWORD=postgres123

# Redis
REDIS_PASSWORD=redis123

# Azurite (standard development connection string)
AZURITE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;

# Application
ASPNETCORE_ENVIRONMENT=Development
NODE_ENV=development
```

### Connection Strings

**SQL Server:**
```
Server=sqlserver;Database=MyApp;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=True;
```

**PostgreSQL:**
```
postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/myapp
```

**Redis:**
```
redis://:${REDIS_PASSWORD}@redis:6379
```

**Azurite (Blob Storage):**
```
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
```

**Cosmos DB:**
```
AccountEndpoint=https://cosmosdb:8081;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==;
```

## Best Practices

### Security

1. **Never commit .env files** - Use .env.template
2. **Use Docker secrets** for production
3. **Run as non-root users** in all containers
4. **Apply capability drops** (drop ALL, add selectively)
5. **Use read-only filesystems** with tmpfs for writes
6. **Network isolation** (frontend/backend separation)

### Performance

1. **Set resource limits** (CPU, memory)
2. **Use health checks** for all services
3. **Implement dependency ordering** with conditions
4. **Cache Docker layers** appropriately
5. **Use alpine images** where possible

### Development Experience

1. **Use docker-compose.override.yml** for dev settings
2. **Mount source code** with hot reload
3. **Expose debugger ports** (localhost only)
4. **Use Makefile** for common operations
5. **Document connection strings** in README

### Maintainability

1. **Version pin all images** (not `latest`)
2. **Comment complex configurations**
3. **Use YAML anchors** for repeated config
4. **Organize networks logically**
5. **Keep compose files modular**

## Troubleshooting

### Services Fail to Start

```bash
# Check logs
docker compose logs <service-name>

# Verify resource allocation
docker stats

# Check port conflicts
netstat -an | grep <port>
```

### Database Connection Issues

```bash
# Verify health check
docker compose ps

# Test connection
docker compose exec <service> <db-client> -h localhost

# Check network
docker network inspect <network-name>
```

### Import Failures

```bash
# Check disk space
df -h

# Verify file permissions
ls -la <import-file>

# Test connectivity to Azure
az account show
```

## Limitations

**Azure Emulators vs. Production:**
- Performance characteristics differ
- Some Azure-specific features unavailable
- Single-instance only (no clustering)
- Self-signed certificates require trust
- Azure AD authentication not replicated

**Database Emulators:**
- SQL Server 2025: Developer edition only
- Cosmos DB: Limited partition support
- Service Bus: Official emulator in preview

**Known Issues:**
- Azure SQL Edge retired (use SQL Server 2025)
- Cosmos DB requires SSL/TLS trust
- Large database exports may timeout

## Requirements

**Host System:**
- Docker Desktop 4.40+ with Compose v2.42+
- Minimum 8GB RAM (16GB recommended for full stack)
- Minimum 50GB disk space
- Azure CLI installed and configured

**Azure Permissions:**
- Read access to resource groups
- Database access credentials
- Network rule management (for database export)

## Migration Checklist

- [ ] Extract Azure infrastructure
- [ ] Review generated docker-compose.yml
- [ ] Configure .env file with passwords
- [ ] Test service startup: `docker compose up`
- [ ] Verify health checks pass
- [ ] Export databases from Azure
- [ ] Import databases to Docker
- [ ] Generate Dockerfiles for apps
- [ ] Build and test application containers
- [ ] Update application connection strings
- [ ] Test full application locally
- [ ] Document any Azure-specific feature gaps
- [ ] Set up regular data refresh process

## Contributing

Contributions are welcome! Please ensure:
- All examples use 2025 best practices
- No `version` field in Compose files
- Security hardening applied
- Comprehensive health checks included
- Documentation updated

## Support

For issues, questions, or feature requests:
- GitHub Issues: [claude-plugin-marketplace](https://github.com/JosiahSiegel/claude-plugin-marketplace/issues)
- Documentation: [Plugin README](https://github.com/JosiahSiegel/claude-plugin-marketplace/tree/main/plugins/azure-to-docker-master)

## License

MIT License - see LICENSE file for details

## Author

Josiah Siegel (JosiahSiegel@users.noreply.github.com)

## Version

1.0.0 (2025)

## Keywords

azure, docker, migration, compose, emulator, azurite, local-dev, infrastructure, extraction, containerize, sql-server, cosmos, storage, devops, development-environment

## References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Azurite Documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite)
- [SQL Server 2025 in Docker](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [Cosmos DB Emulator](https://learn.microsoft.com/en-us/azure/cosmos-db/local-emulator)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
