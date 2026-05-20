# Complete Guide: Azure Infrastructure to Docker Compose

A comprehensive guide for extracting Azure infrastructure and creating a local Docker development environment.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Workflow](#detailed-workflow)
- [Service Mappings](#service-mappings)
- [Database Migration](#database-migration)
- [Configuration Management](#configuration-management)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

This toolkit allows you to:
1. **Extract** all Azure infrastructure configurations
2. **Export** database schemas and data
3. **Generate** Dockerfiles automatically
4. **Create** docker-compose.yml for local development
5. **Migrate** applications to containerized environment

### What Gets Extracted

- ✅ Web Apps (App Services) - runtime, settings, connection strings
- ✅ SQL Databases - schemas, connection details, firewall rules
- ✅ PostgreSQL/MySQL - configuration, parameters
- ✅ Cosmos DB - connection strings, databases
- ✅ Storage Accounts - containers, queues, tables, keys
- ✅ Redis Cache - configuration, connection details
- ✅ Key Vault - secret names, access policies
- ✅ Application Insights - instrumentation keys
- ✅ Networking - VNet, NSG configurations
- ✅ App Service Plans - SKU, tier, capacity

---

## Prerequisites

### Required Tools

```bash
# Azure CLI (required)
curl -sL https://aka.ms/InstallAzureCLI | sudo bash

# Verify installation
az --version

# Docker and Docker Compose (required)
# Install from: https://docs.docker.com/get-docker/
docker --version
docker compose version

# jq (JSON processor, required)
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (Git Bash)
# Download from: https://stedolan.github.io/jq/download/

# Optional but recommended
# SqlPackage (for SQL Server database export)
# Download from: https://aka.ms/sqlpackage

# PostgreSQL client tools (for PostgreSQL export)
sudo apt-get install postgresql-client

# MySQL client tools (for MySQL export)
sudo apt-get install mysql-client
```

### Azure Permissions

Required Azure RBAC roles:
- **Reader** - Minimum required to read configurations
- **Contributor** - Recommended for full access
- **Key Vault Reader** - For Key Vault secrets (if applicable)

Verify your permissions:
```bash
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

---

## Quick Start

### 1. Login to Azure
```bash
az login
az account set --subscription "Your-Subscription-Name"
```

### 2. Extract Infrastructure
```bash
# Using Bash script (Linux/macOS/Git Bash)
chmod +x azure-infrastructure-extractor.sh
./azure-infrastructure-extractor.sh <resource-group-name>

# Using PowerShell (Windows)
.\azure-infrastructure-extractor.ps1 -ResourceGroupName <resource-group-name>

# Example
./azure-infrastructure-extractor.sh my-production-rg
```

### 3. Navigate to Output
```bash
cd azure-export/<resource-group-name>_<timestamp>
```

### 4. Generate Docker Compose
```bash
./scripts/generate-docker-compose.sh
```

### 5. Review and Customize
```bash
# Review the generated docker-compose
cat docker-compose-generated.yml

# Check extracted configurations
ls -la webapps/
ls -la databases/
```

### 6. Start Local Environment
```bash
docker compose -f docker-compose-generated.yml up -d
```

---

## Detailed Workflow

### Phase 1: Infrastructure Extraction

#### Step 1: Run Extraction Script
```bash
./azure-infrastructure-extractor.sh my-rg ./my-export
```

**Output Structure:**
```text
my-export/my-rg_20251025_143022/
├── README.md
├── SERVICE-MAPPING.md
├── docker-compose.yml
├── all-resources.json
├── resource-summary.txt
├── webapps/
│   └── myapp/
│       ├── config.json
│       ├── runtime.json
│       ├── appsettings.json
│       ├── .env                    # Ready to use!
│       ├── connection-strings.json
│       └── ...
├── databases/
│   └── sql-myserver/
│       ├── server-config.json
│       └── mydb/
│           ├── config.json
│           ├── tier.json
│           ├── connection-string.txt
│           └── export-data.sh
├── storage/
├── redis/
├── keyvault/
└── scripts/
    ├── extract-keyvault-secrets.sh
    └── generate-docker-compose.sh
```

#### Step 2: Review Extracted Data
```bash
cd my-export/my-rg_<timestamp>

# View all resources
cat resource-summary.txt

# Check web app configurations
for webapp in webapps/*; do
    echo "=== $(basename $webapp) ==="
    cat "$webapp/runtime.json" | jq '.runtime'
done
```

### Phase 2: Database Migration

#### SQL Server Database Export

**Option 1: Using SqlPackage (Recommended)**
```bash
cd databases/sql-myserver/mydb

# Edit export-data.sh with your credentials
nano export-data.sh

# Run export
./export-data.sh

# This creates mydb.bacpac
```

**Option 2: Using Azure CLI**
```bash
# First, create a storage account for backup
az storage account create \
    --name mybackupstorage \
    --resource-group my-rg \
    --location eastus \
    --sku Standard_LRS

# Get storage key
STORAGE_KEY=$(az storage account keys list \
    --account-name mybackupstorage \
    --resource-group my-rg \
    --query "[0].value" -o tsv)

# Export database
az sql db export \
    --name mydb \
    --server myserver \
    --resource-group my-rg \
    --admin-user sqladmin \
    --admin-password 'YourPassword' \
    --storage-key-type StorageAccessKey \
    --storage-key "$STORAGE_KEY" \
    --storage-uri https://mybackupstorage.blob.core.windows.net/backups/mydb.bacpac

# Download BACPAC
az storage blob download \
    --account-name mybackupstorage \
    --container-name backups \
    --name mydb.bacpac \
    --file ./mydb.bacpac \
    --account-key "$STORAGE_KEY"
```

**Import to Local SQL Server Container:**
```bash
# Start SQL Server container
docker run -d \
    --name local-sqlserver \
    -e 'ACCEPT_EULA=Y' \
    -e 'SA_PASSWORD=YourStrong@Passw0rd' \
    -p 1433:1433 \
    mcr.microsoft.com/mssql/server:2025-latest

# Wait for SQL Server to start
sleep 30

# Import BACPAC
sqlpackage /Action:Import \
    /SourceFile:mydb.bacpac \
    /TargetServerName:localhost \
    /TargetDatabaseName:mydb \
    /TargetUser:sa \
    /TargetPassword:YourStrong@Passw0rd \
    /TargetTrustServerCertificate:True
```

#### PostgreSQL Database Export

```bash
cd databases/postgres-myserver

# Set password
export PGPASSWORD='your-password'

# Get server FQDN from config
SERVER=$(jq -r '.fullyQualifiedDomainName' server-config.json)

# Export database
pg_dump -h "$SERVER" \
    -U myadmin@myserver \
    -d mydb \
    -F c \
    -f mydb.dump

# Or as SQL script
pg_dump -h "$SERVER" \
    -U myadmin@myserver \
    -d mydb \
    --no-owner --no-acl \
    -f mydb.sql
```

**Import to Local PostgreSQL:**
```bash
# Start PostgreSQL container
docker run -d \
    --name local-postgres \
    -e POSTGRES_PASSWORD=localpassword \
    -e POSTGRES_DB=mydb \
    -p 5432:5432 \
    postgres:16.6-alpine

# Wait for startup
sleep 10

# Import from dump
pg_restore -h localhost \
    -U postgres \
    -d mydb \
    mydb.dump

# Or from SQL script
psql -h localhost -U postgres -d mydb -f mydb.sql
```

#### MySQL Database Export

```bash
cd databases/mysql-myserver

# Get server FQDN
SERVER=$(jq -r '.fullyQualifiedDomainName' server-config.json)

# Export database
mysqldump -h "$SERVER" \
    -u myadmin@myserver \
    -p \
    --ssl-mode=REQUIRED \
    --databases mydb \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    > mydb.sql
```

**Import to Local MySQL:**
```bash
# Start MySQL container
docker run -d \
    --name local-mysql \
    -e MYSQL_ROOT_PASSWORD=rootpassword \
    -e MYSQL_DATABASE=mydb \
    -p 3306:3306 \
    mysql:9.2

# Wait for startup
sleep 30

# Import
mysql -h 127.0.0.1 -u root -prootpassword mydb < mydb.sql
```

### Phase 3: Secrets Management

#### Extract Key Vault Secrets

**Option 1: Manual Export**
```bash
cd keyvault/myvault

# List all secrets
az keyvault secret list --vault-name myvault --query "[].name" -o tsv

# Export specific secret
az keyvault secret show \
    --vault-name myvault \
    --name ConnectionString \
    --query value -o tsv

# Create .env file
cat > .env <<EOF
DATABASE_URL=$(az keyvault secret show --vault-name myvault --name DATABASE_URL --query value -o tsv)
API_KEY=$(az keyvault secret show --vault-name myvault --name API_KEY --query value -o tsv)
EOF
```

**Option 2: Automated Export (USE WITH CAUTION)**
```bash
cd keyvault/myvault

# Run the extraction script
../../scripts/extract-keyvault-secrets.sh

# Review the generated .env file
cat .env
```

**Security Best Practices:**
```bash
# IMMEDIATELY add .env to .gitignore
cat >> .gitignore <<EOF
# Sensitive files
.env
*.env
!.env.example
**/*keys.json
**/*connection-string.json
EOF

# Set restrictive permissions
chmod 600 .env
```

### Phase 4: Dockerfile Generation

#### Auto-Generate Dockerfiles

```bash
cd webapps/myapp

# Generate Dockerfile based on runtime
../../dockerfile-generator.sh . ./app-docker

cd app-docker

# Review generated Dockerfile
cat Dockerfile

# Customize as needed
nano Dockerfile
```

#### Manual Dockerfile Creation

**Node.js Example:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

USER node

EXPOSE 8080
ENV PORT=8080

CMD ["node", "server.js"]
```

**Python Example:**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
ENV PORT=8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

**.NET Example:**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### Phase 5: Docker Compose Configuration

#### Generate Base Configuration

```bash
./scripts/generate-docker-compose.sh
```

#### Customize docker-compose.yml

**Complete Example:**
```yaml
version: '3.8'

services:
  # SQL Server Database
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    container_name: local-sqlserver
    environment:
      ACCEPT_EULA: "Y"
      SA_PASSWORD: "YourStrong@Passw0rd123"
      MSSQL_PID: "Developer"
    ports:
      - "1433:1433"
    volumes:
      - sqldata:/var/opt/mssql
      - ./databases/sql-init:/docker-entrypoint-initdb.d
    networks:
      - app-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd123" -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 30s

  # Redis Cache
  redis:
    image: redis:7.4-alpine
    container_name: local-redis
    command: redis-server --requirepass localredispass
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # Azurite (Azure Storage Emulator)
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: local-azurite
    ports:
      - "10000:10000"  # Blob
      - "10001:10001"  # Queue
      - "10002:10002"  # Table
    volumes:
      - azuritedata:/data
    networks:
      - app-network
    command: azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0 --loose

  # Web Application
  webapp:
    build:
      context: ./app
      dockerfile: Dockerfile
    container_name: local-webapp
    ports:
      - "8080:8080"
    environment:
      NODE_ENV: development
      PORT: 8080
    env_file:
      - ./webapps/myapp/.env
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_healthy
      azurite:
        condition: service_started
    networks:
      - app-network
    volumes:
      - ./app:/app
      - /app/node_modules
    restart: unless-stopped

volumes:
  sqldata:
  redisdata:
  azuritedata:

networks:
  app-network:
    driver: bridge
```

#### Connection String Mapping

**Update .env files with local connection strings:**

```bash
# Original Azure connection strings (from extraction)
# SERVER=myserver.database.windows.net,1433;Database=mydb;User ID=admin;Password=***

# Local Docker connection strings
cat > webapps/myapp/.env <<EOF
# Database
DATABASE_URL=Server=sqlserver;Database=mydb;User Id=sa;Password=YourStrong@Passw0rd123;TrustServerCertificate=True;

# Redis
REDIS_URL=redis://:localredispass@redis:6379

# Storage (Azurite)
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;

# API Keys (from Key Vault)
API_KEY=your-api-key-here
EXTERNAL_SERVICE_URL=https://api.example.com

# Disable Application Insights for local
APPLICATIONINSIGHTS_CONNECTION_STRING=
EOF
```

### Phase 6: Testing and Validation

#### Start the Environment

```bash
# Build all images
docker compose build

# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service health
docker compose ps
```

#### Verify Each Service

**SQL Server:**
```bash
# Connect using Azure Data Studio or:
docker exec -it local-sqlserver /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P 'YourStrong@Passw0rd123'

# Run query
SELECT name FROM sys.databases;
GO
```

**Redis:**
```bash
docker exec -it local-redis redis-cli -a localredispass ping
```

**Azurite:**
```bash
# Install Azure Storage Explorer or use az CLI
az storage blob list \
    --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;" \
    --container-name mycontainer
```

**Web Application:**
```bash
# Test endpoint
curl http://localhost:8080/health

# View logs
docker compose logs -f webapp
```

---

## Service Mappings

### Azure Service → Docker Container

| Azure Service | Docker Image | Port | Notes |
|--------------|--------------|------|-------|
| **Azure SQL Database** | `mcr.microsoft.com/mssql/server:2025-latest` | 1433 | Use Developer edition for local |
| **Azure PostgreSQL** | `postgres:16.6-alpine` | 5432 | Match major version |
| **Azure MySQL** | `mysql:9.2` | 3306 | Match major version |
| **Cosmos DB (SQL API)** | `mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator` | 8081 | Linux emulator available |
| **Cosmos DB (MongoDB API)** | `mongo:6` | 27017 | Use MongoDB |
| **Azure Redis Cache** | `redis:7.4-alpine` | 6379 | Match major version |
| **Azure Blob Storage** | `mcr.microsoft.com/azure-storage/azurite` | 10000-10002 | Official emulator |
| **App Service (Node.js)** | `node:18-alpine` | 8080 | Match Node version |
| **App Service (Python)** | `python:3.11-slim` | 8000 | Match Python version |
| **App Service (.NET)** | `mcr.microsoft.com/dotnet/aspnet:8.0` | 8080 | Match .NET version |
| **App Service (PHP)** | `php:8.2-apache` | 80 | Match PHP version |
| **App Service (Java)** | `openjdk:17-jdk-slim` | 8080 | Match Java version |

### Connection String Transformations

**SQL Server:**
```bash
# Azure
Server=tcp:myserver.database.windows.net,1433;Database=mydb;User ID=admin;Password=***;Encrypt=True;

# Docker
Server=sqlserver,1433;Database=mydb;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;
```

**PostgreSQL:**
```bash
# Azure
postgresql://admin@myserver:password@myserver.postgres.database.azure.com:5432/mydb?sslmode=require

# Docker
postgresql://postgres:localpassword@postgres:5432/mydb
```

**Redis:**
```bash
# Azure
mycache.redis.cache.windows.net:6380,password=***,ssl=True,abortConnect=False

# Docker
redis://:localpassword@redis:6379
```

**Storage:**
```bash
# Azure
DefaultEndpointsProtocol=https;AccountName=myaccount;AccountKey=***;EndpointSuffix=core.windows.net

# Docker (Azurite)
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
```

---

## Configuration Management

### Environment Variable Hierarchy

1. **Azure App Settings** → Extract to `.env`
2. **Azure Key Vault** → Extract secrets to `.env`
3. **Connection Strings** → Transform for Docker and add to `.env`
4. **Docker Compose env_file** → Load `.env` into containers

### .env File Structure

```bash
# Database Configuration
DATABASE_HOST=sqlserver
DATABASE_PORT=1433
DATABASE_NAME=mydb
DATABASE_USER=sa
DATABASE_PASSWORD=YourStrong@Passw0rd123
DATABASE_URL=Server=sqlserver;Database=mydb;User Id=sa;Password=YourStrong@Passw0rd123;

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=localredispass
REDIS_URL=redis://:localredispass@redis:6379

# Storage Configuration
STORAGE_ACCOUNT_NAME=devstoreaccount1
STORAGE_ACCOUNT_KEY=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;

# Application Configuration
NODE_ENV=development
PORT=8080
LOG_LEVEL=debug

# External Services
API_KEY=your-api-key
EXTERNAL_API_URL=https://api.example.com

# Monitoring (disable for local)
APPLICATIONINSIGHTS_CONNECTION_STRING=
APPLICATIONINSIGHTS_INSTRUMENTATION_KEY=
```

### .gitignore Configuration

```bash
# Sensitive files - NEVER COMMIT THESE
.env
*.env
!.env.example
**/*keys.json
**/*connection-string*.json
**/secrets*.json
**/secrets*.env

# Docker
.dockerignore

# Database exports
*.bacpac
*.dump
*.sql
!schema.sql

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db
```

---

## Troubleshooting

### Common Issues

#### Issue: Cannot connect to SQL Server container
```bash
# Check if container is running
docker compose ps sqlserver

# View logs
docker compose logs sqlserver

# Verify health check
docker inspect local-sqlserver --format='{{.State.Health.Status}}'

# Test connection
docker exec -it local-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd123' -Q "SELECT @@VERSION"

# Common fixes:
# 1. Ensure password meets complexity requirements (8+ chars, upper, lower, number, special)
# 2. Wait for container to be healthy (can take 30+ seconds)
# 3. Check port conflicts: netstat -an | grep 1433
```

#### Issue: App can't resolve service names
```bash
# Ensure all services are on the same network
docker network ls
docker network inspect <network-name>

# All services should show in "Containers" section

# Fix: Add network to all services in docker-compose.yml
services:
  myapp:
    networks:
      - app-network
  sqlserver:
    networks:
      - app-network
```

#### Issue: Environment variables not loading
```bash
# Check .env file exists
ls -la .env

# Verify env_file path in docker-compose.yml
cat docker-compose.yml | grep env_file

# Check environment inside container
docker exec -it local-webapp env

# Fix: Ensure path is relative to docker-compose.yml location
```

#### Issue: Database connection refused
```bash
# Check database is healthy
docker compose ps

# Ensure depends_on with condition
depends_on:
  sqlserver:
    condition: service_healthy

# Add healthcheck to database service
healthcheck:
  test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "password" -Q "SELECT 1"
  interval: 10s
  retries: 10
  start_period: 30s
```

#### Issue: Azurite connection errors
```bash
# Ensure using the well-known connection string
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;

# Create containers if they don't exist
az storage container create --name mycontainer --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

# Use --loose mode for Azurite (less strict)
command: azurite --loose --blobHost 0.0.0.0
```

---

## Best Practices

### Security
1. **Never commit secrets** - Use .gitignore
2. **Use strong passwords** for local databases
3. **Restrict file permissions** - `chmod 600 .env`
4. **Rotate credentials** regularly
5. **Use service principals** with minimum required permissions

### Development
1. **Use volumes** for development (hot reload)
2. **Use multi-stage builds** for production images
3. **Implement health checks** for all services
4. **Use specific image tags** (not `latest`)
5. **Document customizations** in README

### Performance
1. **Use .dockerignore** to reduce build context
2. **Leverage build cache** - COPY dependencies first
3. **Use alpine images** where possible
4. **Minimize layers** in Dockerfile
5. **Use networks wisely** - don't expose all ports

### Maintenance
1. **Keep images updated** - `docker compose pull`
2. **Clean up regularly** - `docker system prune`
3. **Monitor logs** - `docker compose logs -f`
4. **Backup data volumes** regularly
5. **Document environment-specific** configurations

---

## Additional Resources

### Official Documentation
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Azurite Documentation](https://github.com/Azure/Azurite)

### Database Tools
- [SqlPackage](https://docs.microsoft.com/sql/tools/sqlpackage/)
- [Azure Data Studio](https://docs.microsoft.com/sql/azure-data-studio/)
- [pgAdmin](https://www.pgadmin.org/)
- [MySQL Workbench](https://www.mysql.com/products/workbench/)

### Container Registries
- [Docker Hub](https://hub.docker.com/)
- [Microsoft Container Registry](https://mcr.microsoft.com/)
- [Azure Container Registry](https://azure.microsoft.com/services/container-registry/)

---

## Summary Checklist

- [ ] Azure CLI installed and authenticated
- [ ] Docker and Docker Compose installed
- [ ] Run infrastructure extraction script
- [ ] Export database schemas and data
- [ ] Extract Key Vault secrets to .env files
- [ ] Generate Dockerfiles for applications
- [ ] Create/customize docker-compose.yml
- [ ] Update connection strings for local services
- [ ] Add sensitive files to .gitignore
- [ ] Build Docker images
- [ ] Start docker-compose stack
- [ ] Verify all services are healthy
- [ ] Test application functionality
- [ ] Document any custom configurations

---

**Author**: Azure CLI Expert Agent
**Version**: 1.0
**Last Updated**: 2025-10-25
