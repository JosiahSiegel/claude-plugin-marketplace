# Complete Guide: Containerizing Azure Infrastructure for Local Development

## Overview

This guide shows you how to extract existing Azure infrastructure (Web Apps, SQL Databases, etc.) and run them locally using Docker Compose with a single `docker-compose up` command.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Extracting Azure Infrastructure Configurations](#extracting-azure-infrastructure-configurations)
3. [Exporting Azure SQL Databases](#exporting-azure-sql-databases)
4. [Converting Azure App Services to Docker Containers](#converting-azure-app-services-to-docker-containers)
5. [Creating Docker Compose Configuration](#creating-docker-compose-configuration)
6. [Data Migration Strategies](#data-migration-strategies)
7. [Environment Variables and Secrets Management](#environment-variables-and-secrets-management)
8. [Complete Working Example](#complete-working-example)
9. [Automation Scripts](#automation-scripts)
10. [Gotchas and Limitations](#gotchas-and-limitations)

---

## Prerequisites

```bash
# Install required tools
az login
az account set --subscription <subscription-id>

# Ensure Docker and Docker Compose are installed
docker --version
docker-compose --version

# Install sqlpackage (for database exports)
# Windows: Download from https://aka.ms/sqlpackage-windows
# Linux: Download from https://aka.ms/sqlpackage-linux
# macOS: Download from https://aka.ms/sqlpackage-macos
```

---

## 1. Extracting Azure Infrastructure Configurations

### Method 1: Export ARM Templates (Infrastructure as Code)

```bash
# Export resource group as ARM template
az group export \
  --name MyResourceGroup \
  --output json > azure-infrastructure.json

# Export specific resources
az resource show \
  --ids /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{app-name} \
  --output json > webapp-config.json

az sql db show \
  --resource-group MyResourceGroup \
  --server myserver \
  --name mydb \
  --output json > database-config.json
```

### Method 2: Use Azure Resource Graph for Discovery

```bash
# Query all resources in a resource group
az graph query -q "Resources | where resourceGroup == 'MyResourceGroup' | project name, type, location, properties"

# Get all web apps
az webapp list --resource-group MyResourceGroup --output table

# Get all SQL databases
az sql db list --resource-group MyResourceGroup --server myserver --output table
```

### Method 3: Automated Discovery Script

Create `scripts/discover-azure-resources.sh`:

```bash
#!/bin/bash

RESOURCE_GROUP=$1
OUTPUT_DIR="./azure-export"

if [ -z "$RESOURCE_GROUP" ]; then
    echo "Usage: $0 <resource-group-name>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Discovering resources in $RESOURCE_GROUP..."

# Export Web Apps
echo "Exporting Web Apps..."
az webapp list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/webapps.json"

# Export App Service Plans
echo "Exporting App Service Plans..."
az appservice plan list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/app-service-plans.json"

# Export SQL Servers
echo "Exporting SQL Servers..."
az sql server list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/sql-servers.json"

# Export SQL Databases
SQL_SERVERS=$(az sql server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv)
for server in $SQL_SERVERS; do
    echo "Exporting databases for server: $server"
    az sql db list --resource-group "$RESOURCE_GROUP" --server "$server" --output json > "$OUTPUT_DIR/databases-$server.json"
done

# Export Storage Accounts
echo "Exporting Storage Accounts..."
az storage account list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/storage-accounts.json"

# Export Key Vaults
echo "Exporting Key Vaults..."
az keyvault list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/keyvaults.json"

# Export Redis Cache
echo "Exporting Redis Cache..."
az redis list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/redis-cache.json"

# Export entire resource group
echo "Exporting complete ARM template..."
az group export --name "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/arm-template.json"

echo "Discovery complete! Files saved to $OUTPUT_DIR"
```

---

## 2. Exporting Azure SQL Databases

### Method 1: Using SqlPackage (Recommended)

```bash
# Export BACPAC (schema + data)
sqlpackage /Action:Export \
  /SourceServerName:myserver.database.windows.net \
  /SourceDatabaseName:mydb \
  /SourceUser:myadmin \
  /SourcePassword:'MyP@ssw0rd' \
  /TargetFile:./data/mydb.bacpac \
  /p:VerifyExtraction=True

# Export DACPAC (schema only)
sqlpackage /Action:Extract \
  /SourceServerName:myserver.database.windows.net \
  /SourceDatabaseName:mydb \
  /SourceUser:myadmin \
  /SourcePassword:'MyP@ssw0rd' \
  /TargetFile:./data/mydb.dacpac
```

### Method 2: Using Azure Portal Export

```bash
# Trigger export via CLI
az sql db export \
  --resource-group MyResourceGroup \
  --server myserver \
  --name mydb \
  --admin-user myadmin \
  --admin-password 'MyP@ssw0rd' \
  --storage-key-type StorageAccessKey \
  --storage-key '<storage-account-key>' \
  --storage-uri 'https://mystorageaccount.blob.core.windows.net/backups/mydb.bacpac'

# Download the BACPAC file
az storage blob download \
  --account-name mystorageaccount \
  --container-name backups \
  --name mydb.bacpac \
  --file ./data/mydb.bacpac
```

### Method 3: Scripted Database Export

Create `scripts/export-azure-sql.sh`:

```bash
#!/bin/bash

SERVER=$1
DATABASE=$2
USERNAME=$3
PASSWORD=$4
OUTPUT_FILE=$5

if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="./data/${DATABASE}.bacpac"
fi

mkdir -p ./data

echo "Exporting Azure SQL Database: $DATABASE from $SERVER..."

sqlpackage /Action:Export \
  /SourceServerName:"${SERVER}.database.windows.net" \
  /SourceDatabaseName:"$DATABASE" \
  /SourceUser:"$USERNAME" \
  /SourcePassword:"$PASSWORD" \
  /TargetFile:"$OUTPUT_FILE" \
  /p:VerifyExtraction=True \
  /p:Storage=File

if [ $? -eq 0 ]; then
    echo "Export successful: $OUTPUT_FILE"
    echo "File size: $(du -h $OUTPUT_FILE | cut -f1)"
else
    echo "Export failed!"
    exit 1
fi
```

### Method 4: Generate SQL Scripts (Alternative)

```bash
# Use mssql-scripter to generate SQL scripts
pip install mssql-scripter

mssql-scripter \
  -S myserver.database.windows.net \
  -d mydb \
  -U myadmin \
  -P 'MyP@ssw0rd' \
  --schema-and-data \
  --target-server-version AzureDB \
  --file-per-object \
  --output-folder ./sql-scripts
```

---

## 3. Converting Azure App Services to Docker Containers

### Step 1: Download Application Code

```bash
# For Git-based deployments
WEBAPP_NAME="mywebapp"
RESOURCE_GROUP="MyResourceGroup"

# Get deployment source
az webapp deployment source show \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP

# Download via FTP
az webapp deployment list-publishing-credentials \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --output json > credentials.json

# Or use Kudu API to download
WEBAPP_URL="https://${WEBAPP_NAME}.scm.azurewebsites.net"
az webapp deployment source download \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --output-path ./app-source.zip

unzip app-source.zip -d ./app
```

### Step 2: Extract Runtime Configuration

Create `scripts/extract-webapp-config.sh`:

```bash
#!/bin/bash

WEBAPP_NAME=$1
RESOURCE_GROUP=$2
OUTPUT_DIR="./webapp-config"

mkdir -p "$OUTPUT_DIR"

echo "Extracting configuration for: $WEBAPP_NAME"

# Get runtime stack
az webapp show \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "siteConfig.linuxFxVersion" -o tsv > "$OUTPUT_DIR/runtime.txt"

# Get app settings
az webapp config appsettings list \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output json > "$OUTPUT_DIR/appsettings.json"

# Get connection strings
az webapp config connection-string list \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output json > "$OUTPUT_DIR/connection-strings.json"

# Get environment variables as .env format
az webapp config appsettings list \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name, value:value}" -o tsv | \
  awk '{print $1"="$2}' > "$OUTPUT_DIR/.env"

echo "Configuration extracted to $OUTPUT_DIR"
```

### Step 3: Create Dockerfile Based on Runtime

Create `scripts/generate-dockerfile.sh`:

```bash
#!/bin/bash

RUNTIME=$1
APP_DIR=$2

case $RUNTIME in
  "NODE|18-lts"|"NODE|20-lts")
    cat > Dockerfile <<'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 8080
CMD ["npm", "start"]
EOF
    ;;

  "DOTNETCORE|8.0"|"DOTNET|8.0")
    cat > Dockerfile <<'EOF'
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["*.csproj", "./"]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "YourApp.dll"]
EOF
    ;;

  "PYTHON|3.11"|"PYTHON|3.12")
    cat > Dockerfile <<'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
EOF
    ;;

  "JAVA|11"|"JAVA|17")
    cat > Dockerfile <<'EOF'
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
    ;;

  *)
    echo "Unknown runtime: $RUNTIME"
    echo "Please create Dockerfile manually"
    exit 1
    ;;
esac

echo "Dockerfile generated for runtime: $RUNTIME"
```

---

## 4. Creating Docker Compose Configuration

### Basic Docker Compose Template

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # SQL Server (replacing Azure SQL Database)
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    container_name: local-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./data:/docker-entrypoint-initdb.d
      - ./scripts/init-db.sh:/init-db.sh
    networks:
      - app-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 5s
      retries: 5

  # Web Application (replacing Azure App Service)
  webapp:
    build:
      context: ./app
      dockerfile: Dockerfile
    container_name: local-webapp
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=development
      - DATABASE_HOST=sqlserver
      - DATABASE_PORT=1433
      - DATABASE_NAME=mydb
      - DATABASE_USER=sa
      - DATABASE_PASSWORD=YourStrong@Passw0rd
    env_file:
      - .env.local
    volumes:
      - ./app:/app
      - /app/node_modules
    depends_on:
      sqlserver:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis (replacing Azure Redis Cache)
  redis:
    image: redis:7.4-alpine
    container_name: local-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network
    command: redis-server --appendonly yes

  # Blob Storage Emulator (Azurite)
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: local-azurite
    ports:
      - "10000:10000"  # Blob service
      - "10001:10001"  # Queue service
      - "10002:10002"  # Table service
    volumes:
      - azurite-data:/data
    networks:
      - app-network
    command: azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0

  # Nginx (replacing Azure Application Gateway)
  nginx:
    image: nginx:alpine
    container_name: local-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - webapp
    networks:
      - app-network

volumes:
  sqlserver-data:
  redis-data:
  azurite-data:

networks:
  app-network:
    driver: bridge
```

### Advanced Multi-Service Example

Create `docker-compose.advanced.yml`:

```yaml
version: '3.8'

services:
  # Primary Web App
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - NODE_ENV=development
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://backend:8080
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend
      - redis
    networks:
      - app-network

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=Server=sqlserver;Database=mydb;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - REDIS_URL=redis://redis:6379
      - STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
      - KEY_VAULT_URL=http://keyvault-emulator:8200
    env_file:
      - .env.local
    volumes:
      - ./backend:/app
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-network

  # SQL Server
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./database/backups:/backups
      - ./database/scripts:/scripts
    networks:
      - app-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 5s
      retries: 5

  # Database initialization container
  db-init:
    image: mcr.microsoft.com/mssql-tools
    depends_on:
      sqlserver:
        condition: service_healthy
    volumes:
      - ./database/init:/init
    networks:
      - app-network
    entrypoint: ["/bin/bash", "/init/restore-database.sh"]

  # Redis
  redis:
    image: redis:7.4-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network

  # Azurite (Storage Emulator)
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"
    volumes:
      - azurite-data:/data
    networks:
      - app-network

  # Cosmos DB Emulator (Linux)
  cosmosdb:
    image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator
    ports:
      - "8081:8081"
      - "10251-10254:10251-10254"
    environment:
      - AZURE_COSMOS_EMULATOR_PARTITION_COUNT=10
      - AZURE_COSMOS_EMULATOR_ENABLE_DATA_PERSISTENCE=true
    volumes:
      - cosmosdb-data:/tmp/cosmos/appdata
    networks:
      - app-network

  # Service Bus Emulator (using Azure Service Bus Emulator)
  servicebus:
    image: mcr.microsoft.com/azure-messaging/servicebus-emulator:latest
    ports:
      - "5672:5672"
    environment:
      - ACCEPT_EULA=Y
    networks:
      - app-network

  # Application Insights Local (using OpenTelemetry Collector)
  otel-collector:
    image: otel/opentelemetry-collector:latest
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "8888:8888"  # Metrics
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    command: ["--config=/etc/otel-collector-config.yaml"]
    networks:
      - app-network

  # Jaeger (for distributed tracing)
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # UI
      - "14268:14268"  # Collector
    networks:
      - app-network

volumes:
  sqlserver-data:
  redis-data:
  azurite-data:
  cosmosdb-data:

networks:
  app-network:
    driver: bridge
```

---

## 5. Data Migration Strategies

### Strategy 1: BACPAC Restore on Container Startup

Create `scripts/init-db.sh`:

```bash
#!/bin/bash

echo "Waiting for SQL Server to be ready..."
sleep 30

echo "Restoring database from BACPAC..."

/opt/mssql-tools/bin/sqlpackage /Action:Import \
  /SourceFile:/backups/mydb.bacpac \
  /TargetServerName:localhost \
  /TargetDatabaseName:mydb \
  /TargetUser:sa \
  /TargetPassword:YourStrong@Passw0rd \
  /TargetTrustServerCertificate:True

if [ $? -eq 0 ]; then
    echo "Database restore completed successfully"
else
    echo "Database restore failed"
    exit 1
fi
```

### Strategy 2: SQL Scripts Execution

Create `database/init/01-create-schema.sql`:

```sql
-- Create database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'mydb')
BEGIN
    CREATE DATABASE mydb;
END
GO

USE mydb;
GO

-- Create tables
CREATE TABLE Users (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes
CREATE INDEX IX_Users_Email ON Users(Email);
GO
```

Create `database/init/02-seed-data.sql`:

```sql
USE mydb;
GO

-- Insert sample data
INSERT INTO Users (Username, Email) VALUES
('john.doe', 'john@example.com'),
('jane.smith', 'jane@example.com');
GO
```

Create `database/init/restore-database.sh`:

```bash
#!/bin/bash

echo "Waiting for SQL Server..."
until /opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P YourStrong@Passw0rd -Q "SELECT 1" > /dev/null 2>&1; do
    echo "SQL Server not ready, waiting..."
    sleep 5
done

echo "SQL Server is ready!"

if [ -f "/backups/mydb.bacpac" ]; then
    echo "Restoring from BACPAC..."
    sqlpackage /Action:Import \
        /SourceFile:/backups/mydb.bacpac \
        /TargetServerName:sqlserver \
        /TargetDatabaseName:mydb \
        /TargetUser:sa \
        /TargetPassword:YourStrong@Passw0rd \
        /TargetTrustServerCertificate:True
else
    echo "Running SQL scripts..."
    for script in /init/*.sql; do
        echo "Executing $script..."
        /opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P YourStrong@Passw0rd -i "$script"
    done
fi

echo "Database initialization complete!"
```

### Strategy 3: Automated Data Sync

Create `scripts/sync-data-from-azure.sh`:

```bash
#!/bin/bash

# Configuration
AZURE_SERVER="myserver.database.windows.net"
AZURE_DB="mydb"
AZURE_USER="myadmin"
AZURE_PASSWORD="MyP@ssw0rd"
LOCAL_SERVER="localhost"
LOCAL_PASSWORD="YourStrong@Passw0rd"

BACKUP_FILE="./data/${AZURE_DB}-$(date +%Y%m%d-%H%M%S).bacpac"

echo "Exporting from Azure SQL Database..."
sqlpackage /Action:Export \
  /SourceServerName:"$AZURE_SERVER" \
  /SourceDatabaseName:"$AZURE_DB" \
  /SourceUser:"$AZURE_USER" \
  /SourcePassword:"$AZURE_PASSWORD" \
  /TargetFile:"$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "Export failed!"
    exit 1
fi

echo "Import to local SQL Server..."
docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlpackage /Action:Import \
  /SourceFile:"/backups/$(basename $BACKUP_FILE)" \
  /TargetServerName:localhost \
  /TargetDatabaseName:"$AZURE_DB" \
  /TargetUser:sa \
  /TargetPassword:"$LOCAL_PASSWORD" \
  /TargetTrustServerCertificate:True

echo "Data sync complete!"
```

---

## 6. Environment Variables and Secrets Management

### Method 1: Environment File Hierarchy

Create `.env.template`:

```bash
# Database Configuration
DATABASE_HOST=sqlserver
DATABASE_PORT=1433
DATABASE_NAME=mydb
DATABASE_USER=sa
DATABASE_PASSWORD=YourStrong@Passw0rd

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# Azure Storage (Azurite)
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;

# Application Settings
APP_ENV=development
APP_PORT=8080
LOG_LEVEL=debug

# Feature Flags
FEATURE_NEW_UI=true
FEATURE_ANALYTICS=false

# API Keys (use dummy values for local)
SENDGRID_API_KEY=SG.dummy-key-for-local-dev
STRIPE_SECRET_KEY=sk_test_dummy-key
```

Create `.env.local` (gitignored):

```bash
# Local developer overrides
DATABASE_PASSWORD=MyLocalPassword123!

# Real API keys for testing (never commit!)
SENDGRID_API_KEY=SG.real-key-here
```

### Method 2: Convert Azure App Settings to Docker Compose

Create `scripts/azure-to-env.sh`:

```bash
#!/bin/bash

WEBAPP_NAME=$1
RESOURCE_GROUP=$2
OUTPUT_FILE=".env.azure"

echo "Extracting environment variables from Azure Web App: $WEBAPP_NAME"

# Get app settings
az webapp config appsettings list \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name, value:value}" -o tsv | \
  while IFS=$'\t' read -r name value; do
    # Convert Azure-specific values to local equivalents
    case $name in
      "SQLAZURECONNSTR_"*)
        echo "# Original Azure connection string: $name"
        echo "DATABASE_CONNECTION_STRING=\"$value\""
        ;;
      "APPINSIGHTS_INSTRUMENTATIONKEY")
        echo "# Application Insights (disabled locally)"
        echo "APPINSIGHTS_INSTRUMENTATIONKEY=\"\""
        ;;
      *)
        echo "$name=\"$value\""
        ;;
    esac
  done > "$OUTPUT_FILE"

echo "Environment variables exported to $OUTPUT_FILE"
echo "Please review and update for local development!"
```

### Method 3: Docker Secrets (Production-like)

Create `docker-compose.secrets.yml`:

```yaml
version: '3.8'

services:
  webapp:
    build: ./app
    secrets:
      - db_password
      - api_key
    environment:
      - DATABASE_PASSWORD_FILE=/run/secrets/db_password
      - API_KEY_FILE=/run/secrets/api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

### Method 4: Azure Key Vault to Local Mapping

Create `scripts/fetch-keyvault-secrets.sh`:

```bash
#!/bin/bash

KEYVAULT_NAME=$1
OUTPUT_FILE=".env.secrets"

if [ -z "$KEYVAULT_NAME" ]; then
    echo "Usage: $0 <keyvault-name>"
    exit 1
fi

echo "Fetching secrets from Key Vault: $KEYVAULT_NAME"
echo "# Secrets from Azure Key Vault: $KEYVAULT_NAME" > "$OUTPUT_FILE"
echo "# Generated on $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Get all secret names
SECRET_NAMES=$(az keyvault secret list --vault-name "$KEYVAULT_NAME" --query "[].name" -o tsv)

for secret_name in $SECRET_NAMES; do
    echo "Fetching secret: $secret_name"
    secret_value=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret_name" --query "value" -o tsv)

    # Convert kebab-case to UPPER_SNAKE_CASE
    env_name=$(echo "$secret_name" | tr '-' '_' | tr '[:lower:]' '[:upper:]')

    echo "${env_name}=\"${secret_value}\"" >> "$OUTPUT_FILE"
done

echo ""
echo "Secrets exported to $OUTPUT_FILE"
echo "IMPORTANT: This file contains sensitive data. Ensure it's in .gitignore!"
```

---

## 7. Complete Working Example

### Project Structure

```text
my-azure-project/
├── docker-compose.yml
├── docker-compose.override.yml
├── .env.template
├── .env.local
├── .gitignore
├── Makefile
│
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│
├── backend/
│   ├── Dockerfile
│   ├── appsettings.json
│   └── Program.cs
│
├── database/
│   ├── backups/
│   │   └── mydb.bacpac
│   ├── init/
│   │   ├── 01-create-schema.sql
│   │   ├── 02-seed-data.sql
│   │   └── restore-database.sh
│   └── scripts/
│
├── nginx/
│   ├── nginx.conf
│   └── ssl/
│
└── scripts/
    ├── discover-azure-resources.sh
    ├── export-azure-sql.sh
    ├── extract-webapp-config.sh
    ├── azure-to-env.sh
    ├── fetch-keyvault-secrets.sh
    └── sync-data-from-azure.sh
```

### Makefile for Easy Commands

Create `Makefile`:

```makefile
.PHONY: help setup up down logs clean export-azure sync-db

help:
	@echo "Available commands:"
	@echo "  make setup        - Initial setup and configuration"
	@echo "  make up           - Start all services"
	@echo "  make down         - Stop all services"
	@echo "  make logs         - View logs from all services"
	@echo "  make clean        - Remove all containers and volumes"
	@echo "  make export-azure - Export Azure infrastructure"
	@echo "  make sync-db      - Sync database from Azure"

setup:
	@echo "Setting up local development environment..."
	@cp .env.template .env.local
	@echo "Please edit .env.local with your configuration"
	@mkdir -p database/backups database/init database/scripts
	@mkdir -p nginx/ssl
	@chmod +x scripts/*.sh

up:
	@echo "Starting all services..."
	docker-compose up -d
	@echo "Services started! Access the application at http://localhost"

down:
	@echo "Stopping all services..."
	docker-compose down

logs:
	docker-compose logs -f

clean:
	@echo "Removing all containers, volumes, and data..."
	docker-compose down -v
	@echo "Cleanup complete!"

export-azure:
	@read -p "Enter Azure Resource Group name: " rg; \
	./scripts/discover-azure-resources.sh $$rg

sync-db:
	@read -p "Enter Azure SQL Server name: " server; \
	read -p "Enter database name: " db; \
	read -p "Enter username: " user; \
	read -sp "Enter password: " pass; \
	echo ""; \
	./scripts/export-azure-sql.sh $$server $$db $$user $$pass

build:
	@echo "Building all images..."
	docker-compose build

restart:
	@echo "Restarting all services..."
	docker-compose restart

ps:
	docker-compose ps

shell-db:
	docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd

shell-webapp:
	docker-compose exec webapp /bin/bash
```

### Complete docker-compose.yml

```yaml
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    container_name: local-sqlserver
    hostname: sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${DB_SA_PASSWORD:-YourStrong@Passw0rd}
      - MSSQL_PID=Developer
    ports:
      - "${DB_PORT:-1433}:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./database/backups:/backups
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - app-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${DB_SA_PASSWORD:-YourStrong@Passw0rd} -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    restart: unless-stopped

  db-init:
    image: mcr.microsoft.com/mssql/server:2025-latest
    depends_on:
      sqlserver:
        condition: service_healthy
    volumes:
      - ./database/backups:/backups
      - ./database/init:/init
    networks:
      - app-network
    environment:
      - SA_PASSWORD=${DB_SA_PASSWORD:-YourStrong@Passw0rd}
    entrypoint: ["/bin/bash", "/init/restore-database.sh"]
    restart: "no"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        - BUILD_CONFIGURATION=Debug
    container_name: local-backend
    ports:
      - "${BACKEND_PORT:-8080}:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=${DB_NAME:-mydb};User Id=sa;Password=${DB_SA_PASSWORD:-YourStrong@Passw0rd};TrustServerCertificate=True;
      - Redis__ConnectionString=redis:6379
      - AzureStorage__ConnectionString=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
    env_file:
      - .env.local
    volumes:
      - ./backend:/app
      - /app/bin
      - /app/obj
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_started
      azurite:
        condition: service_started
    networks:
      - app-network
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: development
    container_name: local-frontend
    ports:
      - "${FRONTEND_PORT:-3000}:3000"
    environment:
      - NODE_ENV=development
      - REACT_APP_API_URL=http://localhost:${BACKEND_PORT:-8080}
      - CHOKIDAR_USEPOLLING=true
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend
    networks:
      - app-network
    restart: unless-stopped

  redis:
    image: redis:7.4-alpine
    container_name: local-redis
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:latest
    container_name: local-azurite
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"
    volumes:
      - azurite-data:/data
    networks:
      - app-network
    command: azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0 --loose
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: local-nginx
    ports:
      - "${NGINX_HTTP_PORT:-80}:80"
      - "${NGINX_HTTPS_PORT:-443}:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
    networks:
      - app-network
    restart: unless-stopped

volumes:
  sqlserver-data:
    driver: local
  redis-data:
    driver: local
  azurite-data:
    driver: local

networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

---

## 8. Automation Scripts

### All-in-One Conversion Script

Create `scripts/azure-to-docker-compose.sh`:

```bash
#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP=$1
OUTPUT_DIR="./azure-migration"

if [ -z "$RESOURCE_GROUP" ]; then
    echo "Usage: $0 <resource-group-name>"
    exit 1
fi

echo "============================================"
echo "Azure to Docker Compose Migration Tool"
echo "============================================"
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"/{database,webapp-configs,scripts}

# Step 1: Discover resources
echo "Step 1: Discovering Azure resources..."
az webapp list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/webapps.json"
az sql server list --resource-group "$RESOURCE_GROUP" --output json > "$OUTPUT_DIR/sql-servers.json"

# Step 2: Export web apps
echo "Step 2: Exporting web app configurations..."
WEBAPPS=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv)

for webapp in $WEBAPPS; do
    echo "  Exporting: $webapp"

    # Get runtime
    RUNTIME=$(az webapp show --name "$webapp" --resource-group "$RESOURCE_GROUP" --query "siteConfig.linuxFxVersion" -o tsv)
    echo "$RUNTIME" > "$OUTPUT_DIR/webapp-configs/$webapp-runtime.txt"

    # Get app settings
    az webapp config appsettings list \
        --name "$webapp" \
        --resource-group "$RESOURCE_GROUP" \
        --output json > "$OUTPUT_DIR/webapp-configs/$webapp-appsettings.json"

    # Convert to .env format
    az webapp config appsettings list \
        --name "$webapp" \
        --resource-group "$RESOURCE_GROUP" \
        --query "[].{name:name, value:value}" -o tsv | \
        awk '{print $1"="$2}' > "$OUTPUT_DIR/webapp-configs/$webapp.env"
done

# Step 3: Export databases
echo "Step 3: Exporting SQL databases..."
SQL_SERVERS=$(az sql server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv)

for server in $SQL_SERVERS; do
    echo "  Server: $server"
    DATABASES=$(az sql db list --resource-group "$RESOURCE_GROUP" --server "$server" --query "[?name!='master'].name" -o tsv)

    for db in $DATABASES; do
        echo "    Database: $db"

        read -p "    Export database $db? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "    Enter SQL admin username: " sql_user
            read -sp "    Enter SQL admin password: " sql_pass
            echo ""

            # Export database
            sqlpackage /Action:Export \
                /SourceServerName:"${server}.database.windows.net" \
                /SourceDatabaseName:"$db" \
                /SourceUser:"$sql_user" \
                /SourcePassword:"$sql_pass" \
                /TargetFile:"$OUTPUT_DIR/database/${db}.bacpac" \
                /p:VerifyExtraction=True

            if [ $? -eq 0 ]; then
                echo "    Export successful!"
            else
                echo "    Export failed!"
            fi
        fi
    done
done

# Step 4: Generate docker-compose.yml
echo "Step 4: Generating docker-compose.yml..."

cat > "$OUTPUT_DIR/docker-compose.yml" <<'COMPOSE_EOF'
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./database:/backups
    networks:
      - app-network

  redis:
    image: redis:7.4-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network

  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"
    volumes:
      - azurite-data:/data
    networks:
      - app-network

volumes:
  sqlserver-data:
  redis-data:
  azurite-data:

networks:
  app-network:
    driver: bridge
COMPOSE_EOF

# Add web apps to docker-compose.yml
for webapp in $WEBAPPS; do
    RUNTIME=$(cat "$OUTPUT_DIR/webapp-configs/$webapp-runtime.txt")

    cat >> "$OUTPUT_DIR/docker-compose.yml" <<WEBAPP_EOF

  $webapp:
    build:
      context: ./$webapp
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    env_file:
      - ./webapp-configs/$webapp.env
    depends_on:
      - sqlserver
      - redis
    networks:
      - app-network
WEBAPP_EOF
done

# Step 5: Generate Makefile
echo "Step 5: Generating Makefile..."

cat > "$OUTPUT_DIR/Makefile" <<'MAKEFILE_EOF'
.PHONY: help up down logs clean shell-db

help:
	@echo "Available commands:"
	@echo "  make up        - Start all services"
	@echo "  make down      - Stop all services"
	@echo "  make logs      - View logs"
	@echo "  make clean     - Remove all containers and volumes"
	@echo "  make shell-db  - Connect to SQL Server"

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	docker-compose down -v

shell-db:
	docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd
MAKEFILE_EOF

# Step 6: Create README
echo "Step 6: Creating README..."

cat > "$OUTPUT_DIR/README.md" <<'README_EOF'
# Azure to Docker Compose Migration

This directory contains the migrated Azure infrastructure running locally with Docker Compose.

## Quick Start

1. Review and update environment variables in `webapp-configs/*.env`
2. Start all services:
   ```bash
   make up
   ```
3. Access your application at http://localhost:8080

## Database Restoration

To restore databases:

```bash
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlpackage /Action:Import \
  /SourceFile:/backups/mydb.bacpac \
  /TargetServerName:localhost \
  /TargetDatabaseName:mydb \
  /TargetUser:sa \
  /TargetPassword:YourStrong@Passw0rd \
  /TargetTrustServerCertificate:True
```

## Available Services

- SQL Server: localhost:1433
- Redis: localhost:6379
- Azurite (Storage): localhost:10000

## Useful Commands

- `make logs` - View logs from all services
- `make down` - Stop all services
- `make clean` - Remove all data and start fresh
- `make shell-db` - Connect to SQL Server CLI

README_EOF

echo ""
echo "============================================"
echo "Migration Complete!"
echo "============================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. cd $OUTPUT_DIR"
echo "2. Review docker-compose.yml"
echo "3. Update environment variables"
echo "4. Run: make up"
echo ""
```bash

Make it executable:

```bash
chmod +x scripts/azure-to-docker-compose.sh
```

---

## 9. Gotchas and Limitations

### Database Limitations

**Issue**: Azure SQL Database features not in SQL Server
- **Affected**: Serverless compute, auto-pause, built-in backups
- **Solution**: Use SQL Server Developer Edition locally, accept feature differences
- **Workaround**: Document Azure-specific features in README

**Issue**: Managed Instance features
- **Affected**: SQL Agent jobs, cross-database queries, CLR
- **Solution**: SQL Server 2022 supports most features
- **Workaround**: Use docker-compose to run SQL Agent separately

### Storage Limitations

**Issue**: Azure Blob Storage features
- **Affected**: Geo-redundancy, lifecycle management, immutable blobs
- **Solution**: Use Azurite for local development
- **Limitation**: Azurite doesn't support all Azure Storage features

```yaml
# Use Azurite with limitations documented
azurite:
  image: mcr.microsoft.com/azure-storage/azurite
  # NOTE: Does not support:
  # - Geo-replication
  # - Archive tier
  # - WORM (Write Once, Read Many)
```

### Networking Limitations

**Issue**: Azure VNET, Private Endpoints
- **Affected**: Service-to-service private connectivity
- **Solution**: Use Docker networks
- **Note**: Behavior differs from Azure networking

**Issue**: Application Gateway WAF
- **Affected**: Web Application Firewall rules
- **Solution**: Use nginx with ModSecurity
- **Alternative**: Skip WAF in local development

### Authentication Limitations

**Issue**: Managed Identity not available locally
- **Affected**: Passwordless authentication to Azure services
- **Solution**: Use connection strings with credentials locally

```csharp
// Code adaptation for local development
if (builder.Environment.IsDevelopment())
{
    // Use connection string
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
}
else
{
    // Use Managed Identity in Azure
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseSqlServer(connectionString, sqlOptions =>
            sqlOptions.EnableRetryOnFailure()));
}
```

**Issue**: Azure AD authentication
- **Affected**: Azure AD B2C, Enterprise Apps
- **Solution**: Use local identity server (IdentityServer4, Keycloak)
- **Alternative**: Mock authentication in development

### Cosmos DB Limitations

**Issue**: Cosmos DB Emulator is Windows-only (official)
- **Affected**: Linux/macOS developers
- **Solution**: Use Linux emulator (experimental) or Azure Cosmos DB free tier
- **Alternative**: Use MongoDB locally and Cosmos DB Mongo API in Azure

```yaml
# Linux Cosmos DB Emulator (experimental)
cosmosdb:
  image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator
  # Known issues:
  # - Performance slower than Windows emulator
  # - Some features unsupported
  # - SSL certificate issues
```

### Service Bus Limitations

**Issue**: No official Service Bus emulator
- **Affected**: Queue/Topic messaging
- **Solution**: Use RabbitMQ or Azure Service Bus Emulator (community)
- **Alternative**: Use actual Azure Service Bus with free tier

### Application Insights Limitations

**Issue**: No local Application Insights
- **Affected**: Telemetry, distributed tracing
- **Solution**: Use OpenTelemetry with Jaeger
- **Alternative**: Use actual Application Insights with separate resource

```yaml
# OpenTelemetry stack for local observability
otel-collector:
  image: otel/opentelemetry-collector
jaeger:
  image: jaegertracing/all-in-one
prometheus:
  image: prom/prometheus
grafana:
  image: grafana/grafana
```

### Performance Differences

**Issue**: Performance characteristics differ
- **Affected**: Query performance, latency, throughput
- **Solution**: Document differences, use Azure for performance testing
- **Note**: Local SSD vs Azure Storage has different IOPS

### Data Size Limitations

**Issue**: Large databases are slow to export/import
- **Affected**: Databases > 10GB
- **Solution**:
  - Use subset of data for local development
  - Create seed scripts instead of full exports
  - Use database snapshots for quick restore

```bash
# Export subset of data
sqlpackage /Action:Export \
  /SourceServerName:myserver.database.windows.net \
  /SourceDatabaseName:mydb \
  /TargetFile:mydb-subset.bacpac \
  /p:TableData=dbo.Users \
  /p:TableData=dbo.Products
```

### Environment Parity Issues

**Issue**: "Works on my machine" syndrome
- **Affected**: Dependency versions, OS differences
- **Solution**: Document all dependencies in Dockerfile
- **Best Practice**: Use multi-stage builds

```dockerfile
# Pin all versions explicitly
FROM node:18.17.1-alpine AS build
FROM mcr.microsoft.com/dotnet/sdk:8.0.100 AS build
FROM mcr.microsoft.com/mssql/server:2022-CU10-ubuntu-22.04
```

### Configuration Drift

**Issue**: Local config differs from Azure over time
- **Affected**: All services
- **Solution**: Regularly sync configurations from Azure
- **Automation**: Create scheduled job to check for drift

```bash
# Add to crontab or CI/CD
0 0 * * 1 /scripts/sync-azure-config.sh
```

### Resource Limits

**Issue**: Docker resource constraints
- **Affected**: Memory, CPU limits
- **Solution**: Configure Docker Desktop resources

```yaml
# Document resource requirements
# Minimum requirements:
# - 16GB RAM
# - 4 CPU cores
# - 50GB disk space
services:
  sqlserver:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          memory: 2G
```

### Windows-Specific Issues

**Issue**: Windows file paths and line endings
- **Affected**: Shell scripts, git
- **Solution**: Use Git with core.autocrlf=false, use LF line endings

```bash
# Configure git
git config --global core.autocrlf false

# Convert files
dos2unix scripts/*.sh
```

### SSL/TLS Certificate Issues

**Issue**: Self-signed certificates not trusted
- **Affected**: HTTPS, SQL Server encryption
- **Solution**: Trust container certificates or disable validation in dev

```csharp
// Allow untrusted certificates in development
if (builder.Environment.IsDevelopment())
{
    options.UseSqlServer(connectionString, sqlOptions =>
        sqlOptions.EnableRetryOnFailure());
}
```

---

## Summary

This guide provides a complete pathway from Azure to local Docker Compose:

1. **Discovery**: Extract configurations from Azure
2. **Export**: Download databases and application code
3. **Conversion**: Create Dockerfiles and docker-compose.yml
4. **Migration**: Import data into local containers
5. **Configuration**: Manage environment variables and secrets
6. **Automation**: Use scripts and Makefile for common tasks

### Quick Start Commands

```bash
# 1. Export from Azure
./scripts/azure-to-docker-compose.sh MyResourceGroup

# 2. Navigate to output
cd azure-migration

# 3. Start everything
make up

# 4. Check status
docker-compose ps

# 5. View logs
make logs

# 6. Access services
# - Web App: http://localhost:8080
# - SQL Server: localhost:1433
# - Redis: localhost:6379
```

### Best Practices

1. **Version Control**: Commit docker-compose.yml, never commit .env files with secrets
2. **Documentation**: Document all Azure-specific features and local equivalents
3. **Regular Syncs**: Sync configurations from Azure weekly
4. **Data Subsets**: Use minimal data for local development
5. **Resource Monitoring**: Monitor Docker resource usage
6. **Security**: Use different passwords/keys for local vs Azure

### Recommended Tools

- **SqlPackage**: Database export/import
- **Azure CLI**: Resource discovery and configuration
- **Docker Desktop**: Container runtime
- **VS Code**: Development with Docker/Azure extensions
- **Azure Storage Explorer**: Blob storage management
- **Azure Data Studio**: Database management

This approach enables your team to develop entirely locally while maintaining parity with Azure production infrastructure.
