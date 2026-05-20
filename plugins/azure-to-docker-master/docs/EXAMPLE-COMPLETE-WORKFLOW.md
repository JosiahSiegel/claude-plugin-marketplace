# Complete Example: Azure to Docker Migration

This is a real-world example showing how to extract an Azure infrastructure and create a local Docker environment.

## Scenario

**Existing Azure Infrastructure:**
- Resource Group: `production-ecommerce-rg`
- Web App: `ecommerce-api` (Node.js 18)
- Web App: `ecommerce-frontend` (React/Node.js 18)
- SQL Server: `ecommerce-sql` with database `products-db`
- Redis Cache: `ecommerce-cache`
- Storage Account: `ecommercestore`
- Key Vault: `ecommerce-secrets`
- Application Insights: `ecommerce-insights`

**Goal:** Create a local Docker development environment that mirrors the Azure setup.

---

## Step-by-Step Walkthrough

### Phase 1: Azure CLI Setup and Extraction

#### 1. Login and Verify Access

```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "Production-Subscription"

# Verify resource group exists
az group exists --name production-ecommerce-rg
# Output: true

# List resources to see what we're working with
az resource list \
    --resource-group production-ecommerce-rg \
    --output table

# Output:
# Name                    ResourceGroup              Location    Type
# ----------------------  -------------------------  ----------  ----------------------------------------
# ecommerce-api           production-ecommerce-rg    eastus      Microsoft.Web/sites
# ecommerce-frontend      production-ecommerce-rg    eastus      Microsoft.Web/sites
# ecommerce-sql           production-ecommerce-rg    eastus      Microsoft.Sql/servers
# ecommerce-cache         production-ecommerce-rg    eastus      Microsoft.Cache/Redis
# ecommercestore          production-ecommerce-rg    eastus      Microsoft.Storage/storageAccounts
# ecommerce-secrets       production-ecommerce-rg    eastus      Microsoft.KeyVault/vaults
# ecommerce-insights      production-ecommerce-rg    eastus      Microsoft.Insights/components
```

#### 2. Run Infrastructure Extraction

```bash
# Make extraction script executable
chmod +x azure-infrastructure-extractor.sh

# Run extraction
./azure-infrastructure-extractor.sh production-ecommerce-rg ./ecommerce-local

# Output:
# ========================================
# Azure Infrastructure Extractor
# Docker Compose Migration Tool
# ========================================
#
# [INFO] Validating prerequisites...
# [SUCCESS] Prerequisites validated
# [INFO] Setting up directory structure...
# [SUCCESS] Directory structure created at: ./ecommerce-local/production-ecommerce-rg_20251025_143022
# [INFO] Extracting all resources from 'production-ecommerce-rg'...
# [SUCCESS] Resource list exported
# [INFO] Extracting App Service Plans...
# [INFO]   Extracting plan: ecommerce-plan
# [SUCCESS] App Service Plans extracted
# [INFO] Extracting Web Apps...
# [INFO]   Extracting webapp: ecommerce-api
# [INFO]   Extracting webapp: ecommerce-frontend
# [SUCCESS] Web Apps extracted
# [INFO] Extracting SQL Databases...
# [INFO]   Extracting SQL Server: ecommerce-sql
# [INFO]     Extracting database: products-db
# [SUCCESS] SQL Databases extracted
# ...
# [SUCCESS] Extraction Complete!
```

#### 3. Review Extracted Data

```bash
cd ecommerce-local/production-ecommerce-rg_20251025_143022

# Check what was extracted
cat resource-summary.txt

# Output:
# Name                    Type                                      Location
# ----------------------  ----------------------------------------  ----------
# ecommerce-api           Microsoft.Web/sites                       eastus
# ecommerce-frontend      Microsoft.Web/sites                       eastus
# ecommerce-sql           Microsoft.Sql/servers                     eastus
# products-db             Microsoft.Sql/servers/databases           eastus
# ecommerce-cache         Microsoft.Cache/Redis                     eastus
# ecommercestore          Microsoft.Storage/storageAccounts         eastus
# ecommerce-secrets       Microsoft.KeyVault/vaults                 eastus
# ecommerce-insights      Microsoft.Insights/components             eastus

# Check API runtime
cat webapps/ecommerce-api/runtime.json | jq

# Output:
# {
#   "runtime": "NODE|18-lts",
#   "nodeVersion": "18",
#   "pythonVersion": null,
#   "phpVersion": null,
#   "netFrameworkVersion": null,
#   "javaVersion": null
# }

# Check environment variables
head webapps/ecommerce-api/.env

# Output:
# NODE_ENV=production
# PORT=8080
# DATABASE_CONNECTION_STRING=Server=tcp:ecommerce-sql.database.windows.net,1433;Initial Catalog=products-db;...
# REDIS_CONNECTION_STRING=ecommerce-cache.redis.cache.windows.net:6380,password=***,ssl=True...
# STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=ecommercestore;...
# API_KEY=***
# EXTERNAL_PAYMENT_API=https://api.payment-provider.com
```

### Phase 2: Database Export

#### 1. Export SQL Database Schema and Data

```bash
cd databases/sql-ecommerce-sql/products-db

# First, let's see what we need
cat connection-string.txt

# Output:
# Server=tcp:ecommerce-sql.database.windows.net,1433;Initial Catalog=products-db;Persist Security Info=False;User ID=<username>;Password=<password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;

# Get database credentials from Key Vault (more secure)
SQL_USER=$(az keyvault secret show --vault-name ecommerce-secrets --name sql-admin-username --query value -o tsv)
SQL_PASS=$(az keyvault secret show --vault-name ecommerce-secrets --name sql-admin-password --query value -o tsv)

# Export using SqlPackage
sqlpackage /Action:Export \
    /SourceServerName:ecommerce-sql.database.windows.net \
    /SourceDatabaseName:products-db \
    /SourceUser:$SQL_USER \
    /SourcePassword:$SQL_PASS \
    /SourceEncryptConnection:True \
    /TargetFile:products-db.bacpac

# Output:
# Exporting database 'products-db' from server 'ecommerce-sql.database.windows.net'.
# Exporting table '[dbo].[Products]'... 10000 rows exported
# Exporting table '[dbo].[Categories]'... 50 rows exported
# Exporting table '[dbo].[Orders]'... 25000 rows exported
# Exporting table '[dbo].[OrderItems]'... 75000 rows exported
# Successfully exported 110050 rows.
```

#### 2. Verify Export

```bash
ls -lh products-db.bacpac

# Output:
# -rw-r--r-- 1 user user 45M Oct 25 14:35 products-db.bacpac

# Good! We have a 45MB database export
```

### Phase 3: Secrets Extraction

#### 1. Extract Key Vault Secrets

```bash
cd ../../keyvault/ecommerce-secrets

# Review what secrets exist
cat secret-names.json | jq -r '.[].name'

# Output:
# sql-admin-username
# sql-admin-password
# redis-password
# storage-account-key
# api-key-stripe
# api-key-sendgrid
# jwt-secret

# Extract all secrets (SECURE THIS!)
../../scripts/extract-keyvault-secrets.sh

# Output:
# Extracting Key Vault secrets...
# WARNING: This will export sensitive data to .env files
# Continue? (yes/no): yes
# Processing vault: ecommerce-secrets
#   Fetching: sql-admin-username
#   Fetching: sql-admin-password
#   Fetching: redis-password
#   Fetching: storage-account-key
#   Fetching: api-key-stripe
#   Fetching: api-key-sendgrid
#   Fetching: jwt-secret
#   Secrets saved to: .env
# Done! Remember to keep .env files secure and add them to .gitignore

# Review (be careful - contains real secrets!)
cat .env

# Output:
# sql-admin-username=sqladmin
# sql-admin-password=P@ssw0rd123!SecurePassword
# redis-password=verySecureRedisPassword123
# storage-account-key=Hj7x...
# api-key-stripe=sk_live_...
# api-key-sendgrid=SG.x...
# jwt-secret=super-secret-jwt-key-12345

# IMMEDIATELY secure this
chmod 600 .env
```

### Phase 4: Docker Environment Setup

#### 1. Generate Docker Compose

```bash
cd ../..  # Back to root of extracted data

./scripts/generate-docker-compose.sh

# Output:
# Generating docker-compose.yml from extracted Azure resources...
# Generated: ./docker-compose-generated.yml
#
# Next steps:
# 1. Review and customize docker-compose-generated.yml
# 2. Add your application services
# 3. Configure environment variables
# 4. Run: docker-compose -f docker-compose-generated.yml up -d

# Review generated file
cat docker-compose-generated.yml

# Output shows SQL Server, Redis, and Azurite services configured
```

#### 2. Generate Dockerfiles for Applications

```bash
# API Dockerfile
../dockerfile-generator.sh webapps/ecommerce-api ./api-docker

# Output:
# [INFO] Generating Dockerfile for: ecommerce-api
# [INFO] Detected runtime: NODE|18-lts
# [SUCCESS] Node.js Dockerfile created
# [SUCCESS] Dockerfile generation complete!
#
# Generated files in: ./api-docker
#   - Dockerfile
#   - .dockerignore
#   - docker-compose-service.yml
#   - build.sh
#   - run.sh

# Frontend Dockerfile
../dockerfile-generator.sh webapps/ecommerce-frontend ./frontend-docker

# Similar output for frontend
```

#### 3. Create Project Structure

```bash
# Create project directory
mkdir -p ~/ecommerce-local-dev
cd ~/ecommerce-local-dev

# Copy extracted configurations
cp -r ~/ecommerce-local/production-ecommerce-rg_*/. ./config/

# Create app directories
mkdir -p api frontend

# Copy Dockerfiles
cp config/api-docker/Dockerfile api/
cp config/api-docker/.dockerignore api/
cp config/frontend-docker/Dockerfile frontend/
cp config/frontend-docker/.dockerignore frontend/

# TODO: Get application source code
# Option 1: Clone from Git (if configured)
# Option 2: Download from Azure using deployment credentials
# Option 3: Use Kudu API to download site content
```

#### 4. Customize docker-compose.yml

```bash
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  # SQL Server Database
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2025-latest
    container_name: ecommerce-sqlserver
    environment:
      ACCEPT_EULA: "Y"
      SA_PASSWORD: "LocalDev@Pass123"
      MSSQL_PID: "Developer"
    ports:
      - "1433:1433"
    volumes:
      - sqldata:/var/opt/mssql
      - ./config/databases/sql-ecommerce-sql/products-db:/docker-entrypoint-initdb.d
    networks:
      - ecommerce-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "LocalDev@Pass123" -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 30s

  # Redis Cache
  redis:
    image: redis:7.4-alpine
    container_name: ecommerce-redis
    command: redis-server --requirepass "localRedisPass123"
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data
    networks:
      - ecommerce-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # Azurite (Azure Storage)
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: ecommerce-azurite
    ports:
      - "10000:10000"  # Blob
      - "10001:10001"  # Queue
      - "10002:10002"  # Table
    volumes:
      - azuritedata:/data
    networks:
      - ecommerce-network
    command: azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0 --loose

  # API Service
  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    container_name: ecommerce-api
    ports:
      - "3000:8080"
    environment:
      NODE_ENV: development
      PORT: 8080
      # Local connection strings
      DATABASE_CONNECTION_STRING: "Server=sqlserver;Database=products-db;User Id=sa;Password=LocalDev@Pass123;TrustServerCertificate=True;"
      REDIS_CONNECTION_STRING: "redis://:localRedisPass123@redis:6379"
      STORAGE_CONNECTION_STRING: "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;"
      # From Key Vault
      JWT_SECRET: "super-secret-jwt-key-12345"
      API_KEY_STRIPE: "sk_test_local_development"
      # Disable App Insights for local
      APPLICATIONINSIGHTS_CONNECTION_STRING: ""
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_healthy
      azurite:
        condition: service_started
    networks:
      - ecommerce-network
    volumes:
      - ./api:/app
      - /app/node_modules
    restart: unless-stopped

  # Frontend Service
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: ecommerce-frontend
    ports:
      - "8080:8080"
    environment:
      NODE_ENV: development
      PORT: 8080
      API_URL: "http://api:8080"
      APPLICATIONINSIGHTS_CONNECTION_STRING: ""
    depends_on:
      - api
    networks:
      - ecommerce-network
    volumes:
      - ./frontend:/app
      - /app/node_modules
    restart: unless-stopped

volumes:
  sqldata:
  redisdata:
  azuritedata:

networks:
  ecommerce-network:
    driver: bridge
EOF
```

### Phase 5: Database Import

#### 1. Start SQL Server Container

```bash
# Start just the database first
docker compose up -d sqlserver

# Wait for healthy status
docker compose ps

# Output:
# NAME                   STATUS                    PORTS
# ecommerce-sqlserver    Up (healthy)              0.0.0.0:1433->1433/tcp
```

#### 2. Import Database

```bash
# Import the BACPAC file
sqlpackage /Action:Import \
    /SourceFile:./config/databases/sql-ecommerce-sql/products-db/products-db.bacpac \
    /TargetServerName:localhost \
    /TargetDatabaseName:products-db \
    /TargetUser:sa \
    /TargetPassword:LocalDev@Pass123 \
    /TargetTrustServerCertificate:True

# Output:
# Importing to database 'products-db' on server 'localhost'.
# Creating table '[dbo].[Products]'
# Creating table '[dbo].[Categories]'
# Creating table '[dbo].[Orders]'
# Creating table '[dbo].[OrderItems]'
# Importing data into '[dbo].[Products]'... 10000 rows imported
# Importing data into '[dbo].[Categories]'... 50 rows imported
# Importing data into '[dbo].[Orders]'... 25000 rows imported
# Importing data into '[dbo].[OrderItems]'... 75000 rows imported
# Successfully imported 110050 rows.
```

#### 3. Verify Import

```bash
# Connect and verify
docker exec -it ecommerce-sqlserver /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P 'LocalDev@Pass123'

# Run queries
1> SELECT COUNT(*) as ProductCount FROM [products-db].dbo.Products;
2> GO

# Output:
# ProductCount
# -----------
# 10000
#
# (1 rows affected)

1> SELECT TOP 5 ProductName, Price FROM [products-db].dbo.Products;
2> GO

# Output shows first 5 products with prices
```

### Phase 6: Application Code Setup

#### 1. Download Application Code (Example using Kudu)

```bash
# Get publishing credentials
API_CREDS=$(az webapp deployment list-publishing-credentials \
    --name ecommerce-api \
    --resource-group production-ecommerce-rg \
    --query "{username:publishingUserName, password:publishingPassword}" -o json)

# Extract credentials
API_USER=$(echo $API_CREDS | jq -r '.username')
API_PASS=$(echo $API_CREDS | jq -r '.password')

# Download using Kudu ZIP API
curl -u "$API_USER:$API_PASS" \
    https://ecommerce-api.scm.azurewebsites.net/api/zip/site/wwwroot/ \
    --output api-code.zip

# Extract
unzip api-code.zip -d ./api/

# Similar for frontend
# ...

# Or if you have Git integration, just clone
# git clone <your-repo-url> ./api
```

#### 2. Update Application Configuration

```bash
# Update API to use local connection strings
cat > api/.env.local <<'EOF'
NODE_ENV=development
PORT=8080
DATABASE_CONNECTION_STRING=Server=sqlserver;Database=products-db;User Id=sa;Password=LocalDev@Pass123;TrustServerCertificate=True;
REDIS_CONNECTION_STRING=redis://:localRedisPass123@redis:6379
STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
JWT_SECRET=super-secret-jwt-key-12345
API_KEY_STRIPE=sk_test_local
APPLICATIONINSIGHTS_CONNECTION_STRING=
EOF

# Update frontend
cat > frontend/.env.local <<'EOF'
NODE_ENV=development
PORT=8080
REACT_APP_API_URL=http://localhost:3000
APPLICATIONINSIGHTS_CONNECTION_STRING=
EOF
```

### Phase 7: Start and Test

#### 1. Build and Start All Services

```bash
# Build all images
docker compose build

# Output shows builds for api and frontend

# Start everything
docker compose up -d

# Check status
docker compose ps

# Output:
# NAME                   STATUS                    PORTS
# ecommerce-sqlserver    Up (healthy)              0.0.0.0:1433->1433/tcp
# ecommerce-redis        Up (healthy)              0.0.0.0:6379->6379/tcp
# ecommerce-azurite      Up                        0.0.0.0:10000-10002->10000-10002/tcp
# ecommerce-api          Up                        0.0.0.0:3000->8080/tcp
# ecommerce-frontend     Up                        0.0.0.0:8080->8080/tcp
```

#### 2. Test Each Service

```bash
# Test API health endpoint
curl http://localhost:3000/health

# Output:
# {"status":"healthy","database":"connected","redis":"connected","timestamp":"2025-10-25T14:45:00.000Z"}

# Test API endpoint
curl http://localhost:3000/api/products?limit=5

# Output: JSON array of 5 products

# Test Frontend
curl -I http://localhost:8080

# Output:
# HTTP/1.1 200 OK
# Content-Type: text/html
# ...

# Open in browser
# http://localhost:8080
```

#### 3. View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api

# Check for any errors
docker compose logs | grep -i error
```

### Phase 8: Verification and Cleanup

#### 1. Create Test Data

```bash
# Test product creation
curl -X POST http://localhost:3000/api/products \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test Product",
        "price": 29.99,
        "category": "Electronics",
        "description": "A test product"
    }'

# Output:
# {"id":10001,"name":"Test Product","price":29.99,"category":"Electronics","status":"created"}

# Verify in database
docker exec -it ecommerce-sqlserver /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P 'LocalDev@Pass123' \
    -Q "SELECT TOP 1 * FROM [products-db].dbo.Products ORDER BY ProductId DESC"
```

#### 2. Test Redis Caching

```bash
# Check Redis for cached data
docker exec -it ecommerce-redis redis-cli -a localRedisPass123

# In Redis CLI
127.0.0.1:6379> KEYS *
# Shows cached keys

127.0.0.1:6379> GET product:10001
# Shows cached product data
```

#### 3. Test Storage

```bash
# Upload test file to Azurite
az storage blob upload \
    --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;" \
    --container-name images \
    --name test-image.jpg \
    --file ./test-image.jpg

# List blobs
az storage blob list \
    --connection-string "..." \
    --container-name images \
    --output table
```

---

## Final Project Structure

```text
~/ecommerce-local-dev/
├── docker-compose.yml              # Main compose file
├── .gitignore                      # Sensitive files excluded
├── README.md                       # Project documentation
├── api/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .env.local
│   ├── package.json
│   ├── src/
│   └── ...
├── frontend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .env.local
│   ├── package.json
│   ├── public/
│   ├── src/
│   └── ...
└── config/                         # Extracted Azure configs
    ├── databases/
    │   └── sql-ecommerce-sql/
    │       └── products-db/
    │           └── products-db.bacpac
    ├── webapps/
    │   ├── ecommerce-api/
    │   └── ecommerce-frontend/
    ├── keyvault/
    │   └── ecommerce-secrets/
    │       └── .env
    └── ...
```

---

## Common Commands

```bash
# Start everything
docker compose up -d

# Stop everything
docker compose down

# Rebuild after code changes
docker compose build api
docker compose up -d api

# View logs
docker compose logs -f

# Connect to SQL Server
docker exec -it ecommerce-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'LocalDev@Pass123'

# Connect to Redis
docker exec -it ecommerce-redis redis-cli -a localRedisPass123

# Backup database
docker exec ecommerce-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'LocalDev@Pass123' -Q "BACKUP DATABASE [products-db] TO DISK = '/var/opt/mssql/backup/products-db.bak'"

# Restore database
docker exec ecommerce-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'LocalDev@Pass123' -Q "RESTORE DATABASE [products-db] FROM DISK = '/var/opt/mssql/backup/products-db.bak' WITH REPLACE"

# Clean up
docker compose down -v  # WARNING: Removes volumes!
docker system prune -a
```

---

## Success Metrics

✅ All services start successfully
✅ Database contains 110,050 rows
✅ API responds to health checks
✅ Frontend loads in browser
✅ Can create/read/update/delete products
✅ Redis caching works
✅ Storage uploads/downloads work
✅ No errors in logs
✅ Environment matches Azure (minus scale)

---

## Next Steps

1. **Development Workflow**
   - Set up hot reload for both services
   - Configure debugger
   - Add testing containers

2. **CI/CD**
   - Add GitHub Actions for local testing
   - Automated database migrations
   - Integration tests

3. **Team Onboarding**
   - Document setup process
   - Create setup scripts
   - Share with team

4. **Production Parity**
   - Add missing services
   - Match Azure versions exactly
   - Test edge cases

---

This complete example shows how to go from Azure infrastructure to a fully functional local Docker development environment in about 30 minutes!
