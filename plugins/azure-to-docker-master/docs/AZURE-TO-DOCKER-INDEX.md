# Azure to Docker Compose - Complete Resource Index

## Overview

This repository contains everything you need to containerize existing Azure infrastructure and run it locally using Docker Compose with a single `docker-compose up` command.

---

## 📚 Documentation

### Primary Guides

1. **[AZURE-TO-DOCKER-QUICKSTART.md](AZURE-TO-DOCKER-QUICKSTART.md)**
   - **Start here!** Quick 5-step guide
   - Get running in under 10 minutes
   - Common workflows and troubleshooting

2. **[azure-to-docker-compose-guide.md](azure-to-docker-compose-guide.md)**
   - Comprehensive 50+ page guide
   - Detailed explanations for every step
   - Tools, methods, and best practices
   - Complete code examples
   - Gotchas and limitations
   - Data migration strategies
   - Environment variable management

### Example Project

3. **[examples/complete-docker-compose-example/](examples/complete-docker-compose-example/)**
   - Complete working example
   - Production-ready docker-compose.yml
   - All Azure services configured
   - Makefile with 20+ convenience commands
   - Full monitoring stack (Jaeger, Grafana, Prometheus)
   - Database initialization scripts
   - Nginx reverse proxy configuration

---

## 🛠️ Tools & Scripts

### Automated Migration Scripts

Located in `scripts/`:

1. **[azure-to-docker-compose.sh](scripts/azure-to-docker-compose.sh)**
   - **Main automation tool**
   - Discovers all Azure resources in a resource group
   - Exports configurations
   - Generates docker-compose.yml
   - Creates complete project structure
   - Usage: `./scripts/azure-to-docker-compose.sh MyResourceGroup`

2. **[export-azure-sql.sh](scripts/export-azure-sql.sh)**
   - Exports Azure SQL databases to BACPAC
   - Includes error handling and validation
   - Shows export progress and file size
   - Provides import instructions
   - Usage: `./scripts/export-azure-sql.sh server db user password`

3. **[generate-dockerfile.sh](scripts/generate-dockerfile.sh)**
   - Generates Dockerfiles based on runtime
   - Supports: Node.js, .NET, Python, Java, PHP, Ruby
   - Multi-stage builds for development and production
   - Security best practices (non-root users)
   - Usage: `./scripts/generate-dockerfile.sh "NODE|18-lts" myapp`

---

## 📁 Project Structure

```
claude-plugin-marketplace/
│
├── AZURE-TO-DOCKER-QUICKSTART.md          # ⭐ Start here
├── azure-to-docker-compose-guide.md       # Complete guide
├── AZURE-TO-DOCKER-INDEX.md              # This file
│
├── scripts/
│   ├── azure-to-docker-compose.sh        # Main automation
│   ├── export-azure-sql.sh               # Database export
│   └── generate-dockerfile.sh            # Dockerfile generator
│
└── examples/
    └── complete-docker-compose-example/
        ├── docker-compose.yml            # Complete orchestration
        ├── Makefile                      # 20+ commands
        ├── .env.template                 # Configuration template
        ├── README.md                     # Project documentation
        ├── .gitignore                    # Git ignore rules
        │
        ├── database/
        │   ├── backups/                  # .bacpac files
        │   └── init/
        │       └── restore-database.sh   # Auto-restore script
        │
        ├── nginx/
        │   └── nginx.conf                # Reverse proxy config
        │
        └── redis/
            └── redis.conf                # Redis configuration
```

---

## 🚀 Quick Start Path

### Option 1: Automated (Recommended)

```bash
# 1. Export everything from Azure
./scripts/azure-to-docker-compose.sh MyResourceGroup

# 2. Export databases
cd azure-migration
make sync-db

# 3. Add application code
git clone https://github.com/your-org/backend.git apps/backend
git clone https://github.com/your-org/frontend.git apps/frontend

# 4. Configure
nano .env

# 5. Start
make up
```

### Option 2: Use Example Project

```bash
# 1. Copy example
cp -r examples/complete-docker-compose-example my-project
cd my-project

# 2. Setup
make setup

# 3. Export databases manually
../../scripts/export-azure-sql.sh myserver mydb user pass

# 4. Add code
# Place your app code in backend/ and frontend/

# 5. Configure and start
nano .env
make up
```

### Option 3: Manual Migration

Follow the complete guide: [azure-to-docker-compose-guide.md](azure-to-docker-compose-guide.md)

---

## 📊 What Gets Migrated

| Azure Service | Local Equivalent | Port | Script |
|--------------|------------------|------|--------|
| Azure SQL Database | SQL Server 2022 | 1433 | `export-azure-sql.sh` |
| Azure App Service | Docker container | 8080 | `generate-dockerfile.sh` |
| Azure Static Web Apps | Docker container | 3000 | `generate-dockerfile.sh` |
| Azure Redis Cache | Redis 7 | 6379 | docker-compose.yml |
| Azure Storage | Azurite | 10000-10002 | docker-compose.yml |
| Azure Cosmos DB | Cosmos Emulator | 8081 | docker-compose.yml |
| Azure Service Bus | Service Bus Emulator | 5672 | docker-compose.yml |
| Application Insights | Jaeger + OTEL | 16686 | docker-compose.yml |
| Application Gateway | Nginx | 80/443 | nginx.conf |
| SendGrid | MailDev | 1080 | docker-compose.yml |
| Azure Monitor | Prometheus + Grafana | 3001, 9090 | docker-compose.yml |

---

## 🎯 Key Features

### Automation Scripts

- ✅ **Resource Discovery**: Automatically find all Azure resources
- ✅ **Configuration Export**: Extract app settings, connection strings
- ✅ **Database Export**: BACPAC generation with progress tracking
- ✅ **Dockerfile Generation**: Runtime-specific, multi-stage builds
- ✅ **Complete Project Setup**: docker-compose.yml, Makefile, .env

### Example Project

- ✅ **All Azure Services**: SQL, Redis, Storage, Cosmos, Service Bus
- ✅ **Monitoring Stack**: Jaeger, Grafana, Prometheus
- ✅ **Email Testing**: MailDev for local email testing
- ✅ **Hot Reload**: Development mode with live code reload
- ✅ **Health Checks**: All services have health check endpoints
- ✅ **Resource Limits**: Proper memory and CPU limits
- ✅ **Security**: Non-root users, TLS support
- ✅ **Makefile**: 20+ commands for common tasks

### Developer Experience

- ✅ **One Command Start**: `make up` starts everything
- ✅ **Automatic Restore**: Databases auto-restore on startup
- ✅ **Connection Strings**: Pre-configured for all services
- ✅ **Logging**: Centralized logging with `make logs`
- ✅ **Debugging**: Shell access to all containers
- ✅ **Documentation**: README in every directory

---

## 📖 Documentation Details

### AZURE-TO-DOCKER-QUICKSTART.md

**Sections:**
1. TL;DR (5-step quick start)
2. Detailed Quick Start
3. What Gets Migrated (comparison table)
4. Common Workflows
5. Troubleshooting
6. Connection Strings Reference
7. Advanced Usage
8. Best Practices

**Best For:**
- Getting started quickly
- Common workflows
- Quick reference

### azure-to-docker-compose-guide.md

**Sections:**
1. Prerequisites
2. Extracting Azure Infrastructure Configurations
3. Exporting Azure SQL Databases
4. Converting Azure App Services to Docker Containers
5. Creating Docker Compose Configuration
6. Data Migration Strategies
7. Environment Variables and Secrets Management
8. Complete Working Example
9. Automation Scripts
10. Gotchas and Limitations

**Best For:**
- Understanding how everything works
- Advanced scenarios
- Customization
- Troubleshooting complex issues

### examples/complete-docker-compose-example/README.md

**Sections:**
1. Overview
2. Quick Start
3. Accessing Services
4. Available Commands
5. Project Structure
6. Database Management
7. Environment Configuration
8. Monitoring & Observability
9. Code Changes & Hot Reload
10. Troubleshooting
11. Differences from Azure
12. Best Practices
13. CI/CD Integration

**Best For:**
- Running the example project
- Learning by example
- Production setup
- Team onboarding

---

## 🔧 Makefile Commands

The example project includes 20+ Makefile commands:

### Setup & Management
```bash
make setup      # Initial setup
make up         # Start all services
make down       # Stop all services
make restart    # Restart services
make clean      # Remove everything
```

### Development
```bash
make logs         # View logs
make logs-follow  # Follow logs
make ps           # Show status
make health       # Health checks
make build        # Rebuild images
```

### Database
```bash
make shell-db     # SQL Server CLI
make sync-db      # Sync from Azure
make restore-db   # Restore backups
make reset-db     # Reset database
```

### Services
```bash
make shell-backend   # Backend shell
make shell-frontend  # Frontend shell
make shell-redis     # Redis CLI
```

### Monitoring
```bash
make open-jaeger   # Open Jaeger UI
make open-grafana  # Open Grafana UI
make open-maildev  # Open MailDev UI
make stats         # Resource usage
```

---

## 🔍 Script Details

### azure-to-docker-compose.sh

**What it does:**
1. Discovers all resources in Azure resource group
2. Exports web app configurations
3. Exports SQL server information
4. Exports Redis, Storage Account details
5. Generates docker-compose.yml with all services
6. Creates Makefile with convenience commands
7. Sets up directory structure
8. Generates README with instructions

**Output:**
- `azure-migration/` directory with complete project
- docker-compose.yml
- Makefile
- .env.template
- Database export instructions
- README.md

**Usage:**
```bash
./scripts/azure-to-docker-compose.sh MyResourceGroup
```

### export-azure-sql.sh

**What it does:**
1. Validates sqlpackage is installed
2. Exports Azure SQL Database to BACPAC
3. Verifies export integrity
4. Shows file size and duration
5. Provides import instructions

**Features:**
- Progress tracking
- Error handling
- Compression
- Validation

**Usage:**
```bash
./scripts/export-azure-sql.sh myserver mydb user password [output.bacpac]
```

### generate-dockerfile.sh

**What it does:**
1. Detects runtime (Node.js, .NET, Python, Java, PHP, Ruby)
2. Generates multi-stage Dockerfile
3. Includes development and production stages
4. Adds security best practices
5. Configures non-root users

**Supported Runtimes:**
- Node.js: 14, 16, 18, 20
- .NET: 6.0, 7.0, 8.0
- Python: 3.9, 3.10, 3.11, 3.12
- Java: 8, 11, 17, 21
- PHP: 8.0, 8.1, 8.2
- Ruby: 3.0, 3.1, 3.2

**Usage:**
```bash
./scripts/generate-dockerfile.sh "NODE|18-lts" myapp
./scripts/generate-dockerfile.sh "DOTNET|8.0" myapi
./scripts/generate-dockerfile.sh "PYTHON|3.11" myservice
```

---

## 🎓 Learning Path

### For Beginners

1. Read: [AZURE-TO-DOCKER-QUICKSTART.md](AZURE-TO-DOCKER-QUICKSTART.md)
2. Try: Run example project
   ```bash
   cd examples/complete-docker-compose-example
   make setup
   make up
   ```
3. Explore: View services, logs, databases
4. Practice: Make code changes and see hot reload

### For Intermediate Users

1. Read: [azure-to-docker-compose-guide.md](azure-to-docker-compose-guide.md)
2. Export: Run `azure-to-docker-compose.sh` on your Azure resource group
3. Migrate: Export databases and application code
4. Customize: Modify docker-compose.yml for your needs
5. Document: Note differences from Azure

### For Advanced Users

1. Study: Review all scripts in `scripts/`
2. Customize: Modify automation scripts for your workflow
3. Extend: Add additional Azure services
4. Optimize: Tune performance and resource usage
5. Contribute: Share improvements

---

## 🐛 Troubleshooting Resources

### Quick Fixes

See [AZURE-TO-DOCKER-QUICKSTART.md](AZURE-TO-DOCKER-QUICKSTART.md) → "Troubleshooting"

Common issues:
- Port conflicts
- Database restore failures
- Out of memory
- Service startup issues

### Detailed Solutions

See [azure-to-docker-compose-guide.md](azure-to-docker-compose-guide.md) → "Gotchas and Limitations"

Covers:
- Database limitations
- Storage limitations
- Networking differences
- Authentication issues
- Performance differences
- Configuration drift

### Debug Commands

```bash
# Check service status
make ps
make health

# View logs
make logs
docker-compose logs sqlserver
docker-compose logs backend

# Resource usage
make stats
docker system df

# Shell access
make shell-db
make shell-backend
make shell-redis

# Test connections
curl http://localhost:8080/health
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P password -Q "SELECT 1"
```

---

## 💡 Best Practices

### Security

1. ✅ Use different passwords for local vs Azure
2. ✅ Never commit .env files
3. ✅ Use dummy API keys locally
4. ✅ Keep .env.template in git
5. ✅ Document secrets in README

### Data

1. ✅ Use minimal data locally (subset of production)
2. ✅ Sync from Azure weekly
3. ✅ Use seed scripts for test data
4. ✅ Never modify production while syncing
5. ✅ Backup local data before reset

### Development

1. ✅ Use hot reload for faster development
2. ✅ Run monitoring stack for debugging
3. ✅ Test emails with MailDev
4. ✅ Use health checks for all services
5. ✅ Document local setup in README

### Team

1. ✅ Share docker-compose.yml in git
2. ✅ Document environment variables
3. ✅ Include setup instructions
4. ✅ Add troubleshooting section
5. ✅ Version lock all dependencies

---

## 🔗 Related Resources

### External Documentation

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SQL Server on Docker](https://hub.docker.com/_/microsoft-mssql-server)
- [Azurite (Storage Emulator)](https://github.com/Azure/Azurite)
- [Cosmos DB Emulator](https://learn.microsoft.com/en-us/azure/cosmos-db/emulator)
- [Azure Service Bus Emulator](https://learn.microsoft.com/en-us/azure/service-bus-messaging/emulator-install)

### Azure Tools

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [SqlPackage](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage)
- [Azure Storage Explorer](https://azure.microsoft.com/en-us/products/storage/storage-explorer/)
- [Azure Data Studio](https://azure.microsoft.com/en-us/products/data-studio/)

### Related Plugins

- [docker-master](plugins/docker-master/) - Docker expertise
- [azure-master](plugins/azure-master/) - Azure expertise
- [ssdt-master](plugins/ssdt-master/) - SQL Server database projects

---

## ✅ Checklist

### Before You Start

- [ ] Docker Desktop installed (8GB RAM, 4 CPUs)
- [ ] Azure CLI installed
- [ ] SqlPackage installed
- [ ] Access to Azure subscription
- [ ] Permissions to export databases

### Migration Steps

- [ ] Export Azure configurations
- [ ] Export databases to BACPAC
- [ ] Download application code
- [ ] Create Dockerfiles
- [ ] Configure environment variables
- [ ] Test locally
- [ ] Document differences
- [ ] Share with team

### Verification

- [ ] All services start successfully
- [ ] Database restored correctly
- [ ] Application connects to database
- [ ] Frontend loads in browser
- [ ] API endpoints respond
- [ ] Monitoring tools accessible
- [ ] Email testing works

---

## 📞 Support

### Getting Help

1. Check troubleshooting sections in documentation
2. Review example project for working configuration
3. Check script error messages
4. View service logs: `make logs`
5. Verify health status: `make health`

### Common Patterns

All documentation follows this pattern:
1. Overview and purpose
2. Prerequisites
3. Step-by-step instructions
4. Code examples
5. Troubleshooting
6. Best practices

---

## 🎉 Success Criteria

You've successfully migrated when you can:

✅ Run `make up` and all services start
✅ Access frontend at http://localhost:3000
✅ Access backend at http://localhost:8080
✅ Connect to SQL Server at localhost:1433
✅ View traces in Jaeger
✅ See metrics in Grafana
✅ Test emails in MailDev
✅ Make code changes and see hot reload
✅ Run tests against local stack
✅ Share setup with team

---

**Ready to get started?**

👉 Begin with [AZURE-TO-DOCKER-QUICKSTART.md](AZURE-TO-DOCKER-QUICKSTART.md)

**Need more details?**

👉 Read [azure-to-docker-compose-guide.md](azure-to-docker-compose-guide.md)

**Want to see a working example?**

👉 Explore [examples/complete-docker-compose-example/](examples/complete-docker-compose-example/)

---

*Last Updated: 2025-10-24*
