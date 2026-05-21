# SQL Server 2025 New Features (Detailed)

Full catalogue of SQL Server 2025 new features: native vector database (DiskANN indexing for AI workloads), JSON enhancements, regular expressions, fuzzy search, change event streaming, security/sensitivity classification, performance / Intelligent Query Processing additions, T-SQL improvements, and Always Encrypted updates. SKILL.md keeps tooling versions (SqlPackage 170.x, ScriptDom, Microsoft.Build.Sql 2.0), deployment workflow, CI/CD, and Fabric DW support; this reference holds the engine-feature deep dive.

## Features Catalogue

## Vector Database for AI

**Native Enterprise Vector Store** with built-in security, compliance, and DiskANN indexing technology.

**Key Capabilities:**
- **Up to 3,996 dimensions** per vector (half-precision 2-byte floating-point)
- **DiskANN indexing** - Disk-based approximate nearest neighbor for efficient large-scale vector search
- **Hybrid AI vector search** - Combine vectors with SQL data for semantic + keyword search
- **Built-in security & compliance** - Enterprise-grade data protection

**Vector Embedding & Text Chunking:**
```sql
-- Create table with vector column
CREATE TABLE Documents (
    Id INT PRIMARY KEY IDENTITY,
    Title NVARCHAR(200),
    Content NVARCHAR(MAX),
    -- Half-precision vectors support up to 3,996 dimensions
    ContentVector VECTOR(1536)  -- OpenAI ada-002: 1,536 dims
    -- ContentVector VECTOR(3072)  -- OpenAI text-embedding-3-large: 3,072 dims
    -- ContentVector VECTOR(3996)  -- Maximum: 3,996 dims
);

-- Insert vectors (T-SQL built-in embedding generation)
INSERT INTO Documents (Title, Content, ContentVector)
VALUES (
    'AI Documentation',
    'Azure AI services...',
    CAST('[0.1, 0.2, 0.3, ...]' AS VECTOR(1536))
);

-- Semantic similarity search with DiskANN
DECLARE @QueryVector VECTOR(1536) = CAST('[0.15, 0.25, ...]' AS VECTOR(1536));

SELECT TOP 10
    Id,
    Title,
    Content,
    VECTOR_DISTANCE('cosine', ContentVector, @QueryVector) AS Similarity
FROM Documents
ORDER BY Similarity;

-- Create DiskANN vector index for performance
CREATE INDEX IX_Documents_Vector
ON Documents(ContentVector)
USING VECTOR_INDEX
WITH (
    DISTANCE_METRIC = 'cosine',  -- or 'euclidean', 'dot_product'
    VECTOR_SIZE = 1536
);

-- Hybrid search: Combine vector similarity with traditional filtering
SELECT TOP 10
    Id,
    Title,
    VECTOR_DISTANCE('cosine', ContentVector, @QueryVector) AS Similarity
FROM Documents
WHERE Title LIKE '%Azure%'  -- Traditional keyword filter
ORDER BY Similarity;
```

## AI Model Integration

**Built into T-SQL** - Seamlessly integrate AI services with model definitions directly in the database.

**Supported AI Services:**
- Azure AI Foundry
- Azure OpenAI Service
- OpenAI
- Ollama (local/self-hosted models)
- Custom REST APIs

**Developer Frameworks:**
- LangChain integration
- Semantic Kernel integration
- Entity Framework Core support
- **GraphQL via Data API Builder (DAB)** - Expose SQL Server data through GraphQL endpoints

**External Models (ONNX):**
```sql
-- Create external model from ONNX file
CREATE EXTERNAL MODEL AIModel
FROM 'https://storage.account.blob.core.windows.net/models/model.onnx'
WITH (
    TYPE = 'ONNX',
    INPUT_DATA_FORMAT = 'JSON',
    OUTPUT_DATA_FORMAT = 'JSON'
);

-- Use model for predictions
DECLARE @Input NVARCHAR(MAX) = '{"text": "Hello world"}';
SELECT PREDICT(MODEL = AIModel, DATA = @Input) AS Prediction;

-- Grant model permissions (new SQL Server 2025 permission)
GRANT CREATE ANY EXTERNAL MODEL TO [ModelAdmin];
GRANT ALTER ANY EXTERNAL MODEL TO [ModelAdmin];
GRANT EXECUTE ON EXTERNAL MODEL::AIModel TO [AppUser];
```

**AI Service Integration:**
```sql
-- Example: Azure OpenAI integration
-- Model definitions built directly into T-SQL
-- Access through REST APIs with built-in authentication
```

## Optimized Locking (Performance Enhancement)

**Key Innovation**: Dramatically reduces lock memory consumption and minimizes blocking for concurrent transactions.

**Two Primary Components**:

1. **Transaction ID (TID) Locking**:
   - Each row labeled with last TID (Transaction ID) that modified it
   - Single lock on TID instead of many row locks
   - Locks released as soon as row is updated
   - Only one TID lock held until transaction ends
   - **Example**: Updating 1,000 rows requires 1,000 X row locks, but each is released immediately, and only one TID lock is held until commit

2. **Lock After Qualification (LAQ)**:
   - Evaluates query predicates using latest committed version WITHOUT acquiring lock
   - Requires READ COMMITTED SNAPSHOT ISOLATION (RCSI)
   - Predicates checked optimistically on committed data
   - X row lock taken only if predicate satisfied
   - Lock released immediately after row update

**Benefits**:
- Reduced lock memory usage
- Increased concurrency and scale
- Minimized lock escalation
- Enhanced application uptime
- Better performance for high-concurrency workloads

**Enabling Optimized Locking**:
```sql
-- Enable RCSI (required for LAQ)
ALTER DATABASE MyDatabase
SET READ_COMMITTED_SNAPSHOT ON;

-- Optimized locking is automatically enabled at database level
-- No additional configuration needed for SQL Server 2025

-- Verify optimized locking status
SELECT name, is_read_committed_snapshot_on
FROM sys.databases
WHERE name = 'MyDatabase';

-- Monitor optimized locking performance
SELECT *
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;
```

## Microsoft Fabric Mirroring (Zero-ETL Analytics)

**Integration**: Near real-time replication of SQL Server databases to Microsoft Fabric OneLake for analytics.

**Key Capabilities**:
- **Zero-ETL Experience**: No complex ETL pipelines required
- **SQL Server 2025-Specific**: Uses new change feed technology (vs CDC in SQL Server 2016-2022)
- **Azure Arc Required**: SQL Server 2025 requires Azure Arc-enabled server for Fabric communication
- **Real-Time Analytics**: Offload analytic workloads to Fabric without impacting production

**Supported Scenarios**:
- SQL Server 2025 on-premises (Windows)
- NOT supported: Azure VM or Linux instances (yet)

**How It Works**:
```sql
-- SQL Server 2025 uses change feed (automatic)
-- Azure Arc agent handles replication to Fabric OneLake

-- Traditional SQL Server 2016-2022 approach (CDC):
-- EXEC sys.sp_cdc_enable_db;
-- EXEC sys.sp_cdc_enable_table ...

-- SQL Server 2025: Change feed is built-in, no CDC setup needed
```

**Benefits**:
- Free Fabric compute for replication
- Free OneLake storage (based on capacity size)
- Near real-time data availability
- BI and analytics without production load
- Integration with Power BI, Synapse, Azure ML

**Configuration**:
1. Enable Azure Arc on SQL Server 2025 instance
2. Configure Fabric workspace and OneLake
3. Enable mirroring in Fabric portal
4. Select database and tables to mirror
5. Data automatically replicated with change feed

**Monitoring**:
```sql
-- Monitor replication lag
SELECT
    database_name,
    table_name,
    last_sync_time,
    rows_replicated,
    replication_lag_seconds
FROM sys.dm_fabric_replication_status;
```

## Native JSON Support Enhancements

**New JSON Data Type**: Native JSON data type for Azure SQL Database (coming to SQL Server 2025).

```sql
-- New JSON data type
CREATE TABLE Products (
    Id INT PRIMARY KEY,
    Name NVARCHAR(100),
    Metadata JSON  -- Native JSON type
);

-- JSON functions enhanced
INSERT INTO Products (Id, Name, Metadata)
VALUES (1, 'Laptop', JSON('{"brand": "Dell", "ram": 16, "ssd": 512}'));

-- Query JSON with improved performance
SELECT
    Id,
    Name,
    JSON_VALUE(Metadata, '$.brand') AS Brand,
    JSON_VALUE(Metadata, '$.ram') AS RAM
FROM Products;
```

## Regular Expression (RegEx) Support

**T-SQL RegEx Functions**: Validate, search, and manipulate strings with regular expressions.

```sql
-- RegEx matching
SELECT REGEXP_LIKE('test@example.com', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') AS IsValidEmail;

-- RegEx replace
SELECT REGEXP_REPLACE('Phone: 555-1234', '\d+', 'XXX') AS MaskedPhone;

-- RegEx extract
SELECT REGEXP_SUBSTR('Order #12345', '\d+') AS OrderNumber;
```

## REST API Integration

**Built-in REST Capabilities**: Call external REST APIs directly from T-SQL.

```sql
-- Call REST API from T-SQL
DECLARE @Response NVARCHAR(MAX);

EXEC sp_invoke_external_rest_endpoint
    @url = 'https://api.example.com/data',
    @method = 'GET',
    @headers = '{"Authorization": "Bearer token123"}',
    @response = @Response OUTPUT;

SELECT @Response AS APIResponse;

-- Enrich database data with external APIs
UPDATE Customers
SET EnrichedData = (
    SELECT JSON_VALUE(response, '$.data')
    FROM OPENROWSET(REST, 'https://api.example.com/customer/' + CustomerId)
)
WHERE CustomerId = 12345;
```

## Optional Parameter Plan Optimization (OPPO)

**Performance Enhancement**: SQL Server 2025 introduces OPPO to enable optimal execution plan selection based on customer-provided runtime parameter values.

**Key Benefits:**
- Solves parameter sniffing issues
- Optimizes plans for specific runtime parameters
- Improves query performance with parameter-sensitive workloads
- Reduces need for query hints or plan guides

**Enabling OPPO:**
```sql
-- Enable at database level
ALTER DATABASE MyDatabase
SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = ON;

-- Check status
SELECT name, is_parameter_sensitive_plan_optimization_on
FROM sys.databases
WHERE name = 'MyDatabase';

-- Monitor OPPO usage
SELECT
    query_plan_hash,
    parameter_values,
    execution_count,
    avg_duration_ms
FROM sys.dm_exec_query_stats
WHERE is_parameter_sensitive = 1;
```

## Microsoft Entra Managed Identities

**Security Enhancement**: SQL Server 2025 adds support for Microsoft Entra managed identities for improved credential management.

**Key Benefits:**
- Eliminates hardcoded credentials
- Reduces security vulnerabilities
- Provides compliance and auditing capabilities
- Simplifies credential rotation

**Configuration:**
```sql
-- Create login with managed identity
CREATE LOGIN [managed-identity-name] FROM EXTERNAL PROVIDER;

-- Grant permissions
CREATE USER [managed-identity-name] FOR LOGIN [managed-identity-name];
GRANT CONTROL ON DATABASE::MyDatabase TO [managed-identity-name];

-- Use in connection strings
-- Connection string: Server=myserver;Database=mydb;Authentication=Active Directory Managed Identity;
```

## Enhanced Information Protection

Sensitivity classification and encryption:

```sql
-- Classify sensitive columns
ADD SENSITIVITY CLASSIFICATION TO
    Customers.Email,
    Customers.CreditCard
WITH (
    LABEL = 'Confidential',
    INFORMATION_TYPE = 'Financial'
);

-- Query classification
SELECT
    schema_name(o.schema_id) AS SchemaName,
    o.name AS TableName,
    c.name AS ColumnName,
    s.label AS SensitivityLabel,
    s.information_type AS InformationType
FROM sys.sensitivity_classifications s
INNER JOIN sys.objects o ON s.major_id = o.object_id
INNER JOIN sys.columns c ON s.major_id = c.object_id AND s.minor_id = c.column_id;
```

