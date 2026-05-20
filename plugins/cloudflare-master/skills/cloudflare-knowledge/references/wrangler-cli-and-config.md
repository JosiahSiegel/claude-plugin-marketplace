# Wrangler CLI and Configuration Reference

Complete Wrangler CLI command reference and `wrangler.jsonc` configuration schema.

## Project Setup

```bash
# Create new project
npm create cloudflare@latest my-worker

# Initialize in existing directory
npx wrangler init

# Login
npx wrangler login
npx wrangler whoami
```

## Development

```bash
# Local development
npx wrangler dev
npx wrangler dev --remote    # Use remote bindings
npx wrangler dev --local     # Fully local

# Test cron trigger locally
curl "http://localhost:8787/__scheduled?cron=*+*+*+*+*"
```

## Deployment

```bash
# Deploy to production
npx wrangler deploy

# Deploy to environment
npx wrangler deploy --env staging

# List versions
npx wrangler versions list

# Rollback
npx wrangler rollback
```

## D1 Database

```bash
# Create database
npx wrangler d1 create my-database

# Execute SQL
npx wrangler d1 execute my-database --local --file=schema.sql
npx wrangler d1 execute my-database --remote --command="SELECT * FROM users"

# Interactive shell
npx wrangler d1 execute my-database --local --command=".tables"

# Export
npx wrangler d1 export my-database --remote --output=backup.sql
```

## R2 Buckets

```bash
# Create bucket
npx wrangler r2 bucket create my-bucket

# List buckets
npx wrangler r2 bucket list

# Upload/download
npx wrangler r2 object put my-bucket/file.txt --file=local.txt
npx wrangler r2 object get my-bucket/file.txt --file=download.txt

# Delete
npx wrangler r2 object delete my-bucket/file.txt
```

## KV Namespaces

```bash
# Create namespace
npx wrangler kv namespace create MY_KV
npx wrangler kv namespace create MY_KV --preview  # Preview namespace

# List namespaces
npx wrangler kv namespace list

# Key operations
npx wrangler kv key put --binding MY_KV key "value"
npx wrangler kv key get --binding MY_KV key
npx wrangler kv key list --binding MY_KV
npx wrangler kv key delete --binding MY_KV key

# Bulk upload
npx wrangler kv bulk put --binding MY_KV data.json
```

## Secrets

```bash
# Set secret
npx wrangler secret put API_KEY
# (prompts for value)

# List secrets
npx wrangler secret list

# Delete secret
npx wrangler secret delete API_KEY
```

## Queues

```bash
# Create queue
npx wrangler queues create my-queue

# List queues
npx wrangler queues list
```

## Hyperdrive

```bash
# Create Hyperdrive config
npx wrangler hyperdrive create my-hyperdrive --connection-string="postgres://..."

# List configs
npx wrangler hyperdrive list

# Update
npx wrangler hyperdrive update my-hyperdrive --connection-string="postgres://..."
```

## Wrangler Configuration (wrangler.jsonc)

Complete configuration reference:

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2024-01-01",
  "compatibility_flags": ["nodejs_compat"],

  // Account settings
  "account_id": "<optional-account-id>",

  // Build settings
  "minify": true,
  "node_compat": true,

  // Environment variables
  "vars": {
    "API_URL": "https://api.example.com"
  },

  // KV Namespaces
  "kv_namespaces": [
    {
      "binding": "MY_KV",
      "id": "<namespace-id>",
      "preview_id": "<preview-namespace-id>"
    }
  ],

  // R2 Buckets
  "r2_buckets": [
    {
      "binding": "MY_BUCKET",
      "bucket_name": "my-bucket",
      "preview_bucket_name": "my-bucket-preview",
      "jurisdiction": "eu"
    }
  ],

  // D1 Databases
  "d1_databases": [
    {
      "binding": "DB",
      "database_id": "<database-id>",
      "database_name": "my-database"
    }
  ],

  // Durable Objects
  "durable_objects": {
    "bindings": [
      {
        "name": "MY_DO",
        "class_name": "MyDurableObject"
      }
    ]
  },
  "migrations": [
    {
      "tag": "v1",
      "new_classes": ["MyDurableObject"]
    },
    {
      "tag": "v2",
      "new_sqlite_classes": ["MyDurableObjectWithSQL"]
    }
  ],

  // Queues
  "queues": {
    "producers": [
      {
        "binding": "MY_QUEUE",
        "queue": "my-queue"
      }
    ],
    "consumers": [
      {
        "queue": "my-queue",
        "max_batch_size": 10,
        "max_batch_timeout": 30,
        "max_retries": 3,
        "dead_letter_queue": "my-dlq"
      }
    ]
  },

  // Hyperdrive
  "hyperdrive": [
    {
      "binding": "MY_DB_POOL",
      "id": "<hyperdrive-config-id>"
    }
  ],

  // Workers AI
  "ai": {
    "binding": "AI"
  },

  // Vectorize
  "vectorize": [
    {
      "binding": "MY_VECTORS",
      "index_name": "my-index"
    }
  ],

  // Browser Rendering
  "browser": {
    "binding": "BROWSER"
  },

  // Service Bindings (Worker-to-Worker)
  "services": [
    {
      "binding": "OTHER_WORKER",
      "service": "other-worker-name"
    }
  ],

  // Cron Triggers
  "triggers": {
    "crons": ["0 * * * *", "0 6 * * *"]
  },

  // Routes
  "routes": [
    {
      "pattern": "example.com/*",
      "zone_name": "example.com"
    }
  ],

  // Observability
  "observability": {
    "logs": {
      "enabled": true,
      "invocation_logs": true,
      "head_sampling_rate": 1
    }
  },

  // Environments
  "env": {
    "staging": {
      "name": "my-worker-staging",
      "vars": {
        "API_URL": "https://staging-api.example.com"
      }
    },
    "production": {
      "name": "my-worker-production",
      "routes": [
        {
          "pattern": "api.example.com/*",
          "zone_name": "example.com"
        }
      ]
    }
  }
}
```

## CI/CD

### GitHub Actions

```yaml
name: Deploy Worker

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Deploy to Cloudflare
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

### Workers Builds (Native Git Integration)

1. Connect GitHub/GitLab in Cloudflare dashboard
2. Select repository and branch
3. Configure build command (optional)
4. Automatic deployment on push
5. Preview URLs for pull requests
