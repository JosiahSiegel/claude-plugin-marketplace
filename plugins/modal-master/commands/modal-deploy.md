# Modal Deploy Command

Deploy a Modal application with environment configuration and CI/CD setup.

## Task

Help deploy a Modal application to production with:

1. **Pre-deployment Checks**
   - Verify app runs locally with `modal run`
   - Check all secrets are configured
   - Verify volumes exist
   - Review resource configuration (GPU, memory, timeout)

2. **Environment Configuration**
   - Set up Modal environments (dev, staging, prod)
   - Configure environment-specific secrets
   - Set appropriate concurrency limits

3. **Deployment Execution**
   - Deploy using `modal deploy`
   - Verify deployment success
   - Test deployed endpoints

4. **CI/CD Setup (Optional)**
   - GitHub Actions workflow
   - Environment variables for tokens
   - Branch-based deployments

## Deployment Commands

```bash
# Test locally first
modal run app.py

# Deploy to default environment
modal deploy app.py

# Deploy to specific environment
MODAL_ENVIRONMENT=prod modal deploy app.py

# Deploy specific module
modal deploy -m mypackage.module

# List deployments
modal app list

# View logs
modal app logs my-app
```

## GitHub Actions Workflow

```yaml
name: Deploy to Modal

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install modal
          pip install -r requirements.txt

      - name: Deploy to Modal
        run: modal deploy app.py
        env:
          MODAL_TOKEN_ID: ${{ secrets.MODAL_TOKEN_ID }}
          MODAL_TOKEN_SECRET: ${{ secrets.MODAL_TOKEN_SECRET }}
          MODAL_ENVIRONMENT: ${{ github.ref == 'refs/heads/main' && 'prod' || 'staging' }}
```

## Environment Setup

```bash
# Create environments
modal environment create dev
modal environment create staging
modal environment create prod

# Create environment-specific secrets
MODAL_ENVIRONMENT=prod modal secret create api-keys \
  OPENAI_API_KEY=sk-prod-xxx \
  DATABASE_URL=postgres://prod...

MODAL_ENVIRONMENT=staging modal secret create api-keys \
  OPENAI_API_KEY=sk-staging-xxx \
  DATABASE_URL=postgres://staging...
```

## Pre-deployment Checklist

- [ ] App runs successfully with `modal run`
- [ ] All secrets created in Modal dashboard
- [ ] Volumes created and accessible
- [ ] Appropriate GPU/memory configured
- [ ] Timeout values set appropriately
- [ ] Concurrency limits configured
- [ ] Environment variables set
- [ ] CI/CD tokens stored as GitHub secrets

## Post-deployment Verification

```bash
# Check deployment status
modal app list

# View app details
modal app show my-app

# Test web endpoint
curl https://your-app--endpoint.modal.run/

# Check logs for errors
modal app logs my-app --follow
```

## Rollback (Team Plan Required)

```bash
# List deployment history
modal app history my-app

# Rollback to previous version
modal app rollback my-app --version <version-id>
```

## Troubleshooting

1. **Deployment fails**: Check `modal run` works locally first
2. **Secrets not found**: Verify secrets exist in correct environment
3. **GPU not available**: Add GPU fallbacks `gpu=["H100", "A100", "any"]`
4. **Timeout errors**: Increase `timeout` parameter
5. **Out of memory**: Increase `memory` parameter
