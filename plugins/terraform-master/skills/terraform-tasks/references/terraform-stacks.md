# Terraform Stacks Reference (GA 2025)

## Overview

Terraform Stacks enable deploying consistent infrastructure across multiple deployments (environments, regions, accounts) with a single action.

## Key Concepts

### Stack Definition
```hcl
# stack.tfstack - Infrastructure template
stack {
  name        = "multi-region-app"
  description = "Production application infrastructure"
}

# Component definitions
component "networking" {
  source = "./modules/networking"

  inputs = {
    environment = var.environment
    region      = var.region
    cidr_block  = var.vpc_cidr
  }
}

component "compute" {
  source = "./modules/compute"

  inputs = {
    environment   = var.environment
    subnet_ids    = component.networking.private_subnet_ids
    instance_type = var.instance_type
  }
}

component "database" {
  source = "./modules/database"

  inputs = {
    environment = var.environment
    subnet_ids  = component.networking.database_subnet_ids
    vpc_id      = component.networking.vpc_id
  }
}
```

### Deployment Configuration
```hcl
# deployments.tfdeploy.hcl - Multiple deployments

deployment "prod-us-east" {
  inputs = {
    environment   = "production"
    region        = "us-east-1"
    vpc_cidr      = "10.0.0.0/16"
    instance_type = "m5.xlarge"
  }
}

deployment "prod-us-west" {
  inputs = {
    environment   = "production"
    region        = "us-west-2"
    vpc_cidr      = "10.1.0.0/16"
    instance_type = "m5.xlarge"
  }
}

deployment "prod-eu-west" {
  inputs = {
    environment   = "production"
    region        = "eu-west-1"
    vpc_cidr      = "10.2.0.0/16"
    instance_type = "m5.large"
  }
}

deployment "staging" {
  inputs = {
    environment   = "staging"
    region        = "us-east-1"
    vpc_cidr      = "10.100.0.0/16"
    instance_type = "t3.medium"
  }
}
```

## Linked Stacks (2025)

Cross-stack dependency management with automatic triggers:

```hcl
# platform-stack.tfstack
stack {
  name = "platform"
}

component "shared-services" {
  source = "./modules/shared"
}

output "vpc_id" {
  value = component.shared-services.vpc_id
}
```

```hcl
# application-stack.tfstack
stack {
  name = "application"

  # Link to platform stack
  depends_on = [stack.platform]
}

component "app" {
  source = "./modules/app"

  inputs = {
    vpc_id = stack.platform.outputs.vpc_id
  }
}
```

## 2025 Features

### Self-Hosted Agents
Execute stacks behind firewalls or in air-gapped environments.

### Custom Deployment Groups
Auto-approve checks for HCP Terraform Premium:
```hcl
deployment "auto-deploy" {
  auto_approve = true  # Requires Premium

  inputs = {
    environment = "dev"
  }
}
```

### Deferred Changes
Partial plans when too many unknown values:
```hcl
# Stack handles deferred changes automatically
component "app" {
  source = "./modules/app"

  # Even with unknown values, stack can create partial plan
  inputs = {
    config = component.config.output  # May be unknown
  }
}
```

### VCS Support
- GitHub
- GitLab
- Azure DevOps
- Bitbucket

## Limits

- Maximum 20 deployments per stack
- Available in HCP Terraform only
- Requires Terraform 1.9+ for CLI compatibility

## Use Cases

### Multi-Region Deployment
Deploy same infrastructure pattern across multiple AWS regions.

### Multi-Account Architecture
Deploy to multiple AWS accounts (dev, staging, prod) from single definition.

### Multi-Tenant SaaS
Deploy isolated environments for each customer.

### Disaster Recovery
Maintain synchronized infrastructure across primary and DR regions.

## CLI Commands

```bash
# Initialize stack
terraform stack init

# Plan all deployments
terraform stack plan

# Apply specific deployment
terraform stack apply -target=deployment.prod-us-east

# Apply all deployments
terraform stack apply
```

## Best Practices

1. **Keep components modular**: Each component should be self-contained
2. **Use variables for differences**: Environment-specific values through inputs
3. **Test with staging first**: Include staging deployment for validation
4. **Monitor deployment order**: Use depends_on for ordering
5. **Limit deployment count**: Stay within 20 deployment limit
