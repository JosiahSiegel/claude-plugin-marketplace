---
name: cloudflare-deploy
description: Deploy a Cloudflare Worker with environment configuration and secrets
arguments:
  - name: environment
    description: "Target environment: production, staging, or preview"
    required: false
  - name: dry-run
    description: "Preview deployment without executing"
    required: false
---

# Deploy Cloudflare Worker

Deploy the current Worker project to Cloudflare with proper environment configuration.

## Instructions

1. **Validate project structure**:
   - Check for `wrangler.jsonc` or `wrangler.toml`
   - Verify `src/index.ts` or main entry exists
   - Check for `package.json`

2. **Determine environment**:
   - `production` (default) - Main deployment
   - `staging` - Test environment
   - `preview` - Temporary preview URL

3. **Pre-deployment checks**:
   ```bash
   # Type check
   npx tsc --noEmit

   # Run tests if present
   npm test --if-present

   # Validate wrangler config
   npx wrangler deploy --dry-run
   ```

4. **Execute deployment**:
   ```bash
   # Production
   npx wrangler deploy

   # Staging
   npx wrangler deploy --env staging

   # Preview (returns temporary URL)
   npx wrangler deploy --env preview
   ```

5. **Post-deployment verification**:
   - Check deployment URL
   - Verify bindings are connected
   - Test basic endpoint

## Environment Configuration

### wrangler.jsonc environments

```jsonc
{
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2024-01-01",

  // Production (default)
  "vars": {
    "ENVIRONMENT": "production"
  },

  // Staging environment
  "env": {
    "staging": {
      "name": "my-worker-staging",
      "vars": {
        "ENVIRONMENT": "staging"
      },
      "kv_namespaces": [
        {
          "binding": "CACHE",
          "id": "staging-kv-id"
        }
      ]
    },
    "preview": {
      "name": "my-worker-preview",
      "vars": {
        "ENVIRONMENT": "preview"
      }
    }
  }
}
```

## Secrets Management

```bash
# Set secret for production
npx wrangler secret put API_KEY

# Set secret for specific environment
npx wrangler secret put API_KEY --env staging

# List secrets
npx wrangler secret list

# Delete secret
npx wrangler secret delete API_KEY
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy Worker

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Type check
        run: npx tsc --noEmit

      - name: Deploy to Cloudflare
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          # For PR previews
          command: deploy --env ${{ github.event_name == 'pull_request' && 'preview' || 'production' }}
```

## Deployment Output

After successful deployment:

```
✨ Successfully deployed my-worker
   https://my-worker.username.workers.dev

Bindings:
  - KV Namespace: CACHE
  - D1 Database: DB
  - R2 Bucket: STORAGE

Metrics:
  - Bundle size: 45.2 KB (gzip: 12.1 KB)
  - Compatibility date: 2024-01-01
```

## Rollback

```bash
# List recent deployments
npx wrangler deployments list

# Rollback to previous version
npx wrangler rollback

# Rollback to specific version
npx wrangler rollback --version <version-id>
```

## Troubleshooting

### Common Issues

1. **Authentication error**:
   ```bash
   npx wrangler login
   ```

2. **Binding not found**:
   - Verify binding IDs in wrangler.jsonc
   - Check namespace/database exists

3. **Bundle too large**:
   - Check for unnecessary dependencies
   - Use dynamic imports
   - Consider splitting into multiple Workers
