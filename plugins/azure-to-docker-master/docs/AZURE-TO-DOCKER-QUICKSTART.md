# Azure to Docker Compose - Quick Start Guide

## TL;DR

Transform your Azure infrastructure to run locally with Docker Compose in 5 steps:

```bash
# 1. Export Azure configuration
./scripts/azure-to-docker-compose.sh MyResourceGroup

# 2. Navigate to generated directory
cd azure-migration

# 3. Review and update .env
nano .env

# 4. Place BACPAC files in database/backups/

# 5. Start everything
make up
```

Access your app at http://localhost

---

## Detailed Quick Start

### Step 1: Export Azure Infrastructure

```bash
# Run the automated export script
./scripts/azure-to-docker-compose.sh MyResourceGroup
```

This will:
- ✅ Discover all resources in your resource group
- ✅ Export web app configurations
- ✅ Generate docker-compose.yml
- ✅ Create Makefile for easy management
- ✅ Set up directory structure

### Step 2: Export Databases

```bash
# Export a single database
./scripts/export-azure-sql.sh myserver mydb sqladmin 'MyP@ssw0rd'

# Or use the guided sync
cd azure-migration
make sync-db
```

Your `.bacpac` files will be saved to `azure-migration/database/backups/`

### Step 3: Download Application Code

```bash
cd azure-migration

# Clone your application repositories
git clone https://github.com/your-org/backend.git apps/backend
git clone https://github.com/your-org/frontend.git apps/frontend

# Or download via Azure App Service
az webapp deployment source config-local-git \
  --name mywebapp \
  --resource-group MyResourceGroup
```

### Step 4: Configure Environment

```bash
# Copy template
cp .env.template .env

# Edit with your settings
nano .env
```

Key settings to update:
```bash
DB_SA_PASSWORD=YourStrongPassword
DB_NAME=YourDatabaseName
BACKEND_PORT=8080
FRONTEND_PORT=3000
```

### Step 5: Start Services

```bash
# Start everything
make up

# Check status
make ps

# View logs
make logs
```

### Step 6: Verify Everything Works

```bash
# Check service health
make health

# Test frontend
curl http://localhost:3000

# Test backend
curl http://localhost:8080/health

# Connect to database
make shell-db
```

---

## What Gets Migrated

| Azure Service | Local Equivalent | Access |
|--------------|------------------|--------|
| Azure SQL Database | SQL Server 2022 | localhost:1433 |
| Azure App Service | Docker container | localhost:8080 |
| Azure Redis Cache | Redis 7 | localhost:6379 |
| Azure Storage | Azurite | localhost:10000 |
| Azure Cosmos DB | Cosmos Emulator | localhost:8081 |
| Azure Service Bus | Service Bus Emulator | localhost:5672 |
| Application Insights | Jaeger + OpenTelemetry | localhost:16686 |
| Application Gateway | Nginx | localhost:80 |

---

## Common Workflows

### Daily Development

```bash
# Start services
make up

# Make code changes in apps/backend or apps/frontend
# Changes auto-reload (hot reload enabled)

# View logs
make logs-follow

# Stop when done
make down
```

### Sync Database from Azure

```bash
# Weekly or as needed
make sync-db

# Restart to import new data
make down
make up
```

### Debugging

```bash
# Shell into containers
make shell-backend
make shell-frontend
make shell-db

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f sqlserver

# Check resource usage
make stats
```

### Testing Email Flows

All emails are caught by MailDev:

```bash
# Open MailDev UI
make open-maildev

# Or visit http://localhost:1080
```

---

## Troubleshooting

### "Port already in use"

On macOS / Linux / WSL / Git Bash:

```bash
# Find what's using the port
lsof -i :1433

# Change port in .env
echo "DB_PORT=1434" >> .env

# Restart
make restart
```

On Windows PowerShell (when running outside WSL / Git Bash):

```powershell
# Find what's using the port
netstat -ano | findstr :1433

# Change port in .env
Add-Content -Path .env -Value "DB_PORT=1434"

# Restart
make restart
```

### "Database restore failed"

```bash
# Check SQL Server logs
docker-compose logs sqlserver

# Verify BACPAC file
ls -lh database/backups/

# Try manual restore
make shell-db
```

### "Out of memory"

Increase Docker Desktop resources:
- Settings → Resources → Memory: 8GB minimum
- CPU: 4 cores minimum

### "Services won't start"

```bash
# Check Docker is running
docker ps

# Clean up and restart
make clean
make setup
make up
```

### "Can't connect to database"

```bash
# Test SQL Server is running
docker-compose ps sqlserver

# Test connection
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong@Passw0rd -Q "SELECT 1"

# Check connection string in .env
cat .env | grep DB_
```

---

## Connection Strings Reference

### SQL Server

```text
Server=localhost,1433;Database=ApplicationDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;MultipleActiveResultSets=true;
```

### Redis

```text
localhost:6379
```

### Azure Storage (Azurite)

```text
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://localhost:10000/devstoreaccount1;
```

### Cosmos DB

```text
AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
```

---

## Advanced Usage

### Using Specific Services Only

```bash
# Start only database and cache
docker-compose up -d sqlserver redis

# Start without monitoring
docker-compose up -d sqlserver redis backend frontend
```

### Scaling Services

```bash
# Scale backend to 3 instances
docker-compose up -d --scale backend=3

# Nginx will load balance across them
```

### Using Production Build

```bash
# Set build target
echo "BUILD_TARGET=production" >> .env

# Rebuild
make build

# Start
make up
```

### Connecting from Host Machine

Update your app's connection strings to use `localhost` instead of service names:

```bash
# .env.local for running app outside Docker
DB_HOST=localhost
DB_PORT=1433
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## File Structure After Migration

```text
azure-migration/
├── docker-compose.yml       # Main orchestration
├── .env                     # Your configuration
├── Makefile                # Convenience commands
│
├── apps/
│   ├── backend/            # Your backend code
│   └── frontend/           # Your frontend code
│
├── database/
│   ├── backups/           # BACPAC files
│   │   └── mydb.bacpac
│   └── init/              # SQL scripts
│       └── restore-database.sh
│
├── nginx/
│   └── nginx.conf         # Reverse proxy config
│
└── webapp-configs/        # Exported Azure configs
    ├── myapp.env
    └── myapp-appsettings.json
```

---

## Best Practices

### 1. Keep Production Separate

Never use production credentials in `.env`:

```bash
# Use different passwords
DB_SA_PASSWORD=LocalDevPassword123!  # NOT your production password

# Use dummy API keys
SENDGRID_API_KEY=SG.dummy-key  # NOT your production key
```

### 2. Use Minimal Data

Don't sync entire production databases:

```sql
-- Export only recent data
SELECT TOP 1000 * FROM Users ORDER BY CreatedDate DESC
SELECT * FROM Products WHERE IsActive = 1
```

### 3. Commit Configuration, Not Secrets

```bash
# Commit to git
git add docker-compose.yml Makefile .env.template

# Never commit
.env
database/backups/*.bacpac
apps/
```

### 4. Regular Sync

Sync from Azure weekly to catch configuration drift:

```bash
# Add to crontab
0 9 * * 1 cd /path/to/project && make export-azure
```

### 5. Document Differences

Maintain `DIFFERENCES.md` listing Azure-specific features:

```markdown
# Differences from Azure

- Managed Identity → Connection strings
- Auto-scaling → Manual docker-compose scale
- Geo-replication → Single instance
- Application Insights → Jaeger
```

---

## Next Steps

1. ✅ Review generated docker-compose.yml
2. ✅ Update .env with your settings
3. ✅ Export databases from Azure
4. ✅ Download application code
5. ✅ Test locally: `make up`
6. ✅ Share with team
7. ✅ Document any customizations
8. ✅ Set up CI/CD with Docker Compose

---

## Resources

- **Complete Guide**: `azure-to-docker-compose-guide.md`
- **Example Project**: `examples/complete-docker-compose-example/`
- **Scripts**: `scripts/`
  - `azure-to-docker-compose.sh` - Main migration tool
  - `export-azure-sql.sh` - Database export
  - `generate-dockerfile.sh` - Dockerfile generator

---

## Getting Help

### Common Issues

Check `azure-to-docker-compose-guide.md` → "Gotchas and Limitations" section

### Example Setup

See working example in `examples/complete-docker-compose-example/`

### Tool Versions

```bash
# Check installed tools
docker --version
docker-compose --version
az --version
sqlpackage /version
```

### Support

- Review logs: `make logs`
- Check health: `make health`
- View stats: `make stats`
- Clean restart: `make clean && make setup && make up`

---

**🎉 You're ready to develop locally with your Azure infrastructure!**

Start with: `./scripts/azure-to-docker-compose.sh YourResourceGroup`
