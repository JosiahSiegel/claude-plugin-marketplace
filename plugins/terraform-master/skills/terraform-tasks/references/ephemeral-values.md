# Ephemeral Values Reference (Terraform 1.10+)

## Overview

Ephemeral values are a security feature introduced in Terraform 1.10 that allows secrets to be used without persisting them in state or plan files.

## Ephemeral Input Variables

```hcl
variable "db_password" {
  description = "Database password - never stored in state"
  type        = string
  sensitive   = true
  ephemeral   = true  # Key: Never persisted
}

variable "api_key" {
  description = "External API key"
  type        = string
  sensitive   = true
  ephemeral   = true
}
```

## Ephemeral Resources

### AWS Secrets Manager
```hcl
ephemeral "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "prod/database/credentials"
}

resource "aws_db_instance" "main" {
  identifier     = "mydb"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  username = "admin"
  password = ephemeral.aws_secretsmanager_secret_version.db_creds.secret_string
}
```

### AWS SSM Parameter
```hcl
ephemeral "aws_ssm_parameter" "api_key" {
  name = "/prod/api-key"
}

resource "aws_lambda_function" "main" {
  function_name = "my-function"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      API_KEY = ephemeral.aws_ssm_parameter.api_key.value
    }
  }
}
```

### Azure Key Vault
```hcl
ephemeral "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "mypostgres"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login    = "psqladmin"
  administrator_password = ephemeral.azurerm_key_vault_secret.db_password.value
}
```

### Google Secret Manager
```hcl
ephemeral "google_secret_manager_secret_version" "db_password" {
  secret = "projects/my-project/secrets/db-password"
}

resource "google_sql_database_instance" "main" {
  name             = "myinstance"
  database_version = "POSTGRES_15"
  region           = "us-central1"

  root_password = ephemeral.google_secret_manager_secret_version.db_password.secret_data
}
```

## Write-Only Arguments (1.11+)

```hcl
# Arguments marked as write-only accept ephemeral values
# and are never stored in state
resource "aws_db_instance" "main" {
  identifier     = "mydb"
  engine         = "postgres"
  instance_class = "db.t3.micro"

  # Write-only argument - accepts ephemeral value
  password = var.db_password
}
```

## Ephemeral Outputs

```hcl
output "db_connection_string" {
  description = "Database connection string"
  value       = "postgres://admin:${var.db_password}@${aws_db_instance.main.endpoint}/mydb"
  sensitive   = true
  ephemeral   = true  # Never stored in state
}
```

## How Ephemeral Values Work

1. **Fresh on every run**: Retrieved during plan/apply, not stored
2. **No state persistence**: Never written to terraform.tfstate
3. **No plan persistence**: Never written to plan files
4. **Re-evaluation**: Fetched again during apply if needed
5. **Garbage collection**: Cleaned up after use

## Provider Support (2025)

| Provider | Ephemeral Resources |
|----------|---------------------|
| AWS | `aws_secretsmanager_secret_version`, `aws_ssm_parameter` |
| Azure | `azurerm_key_vault_secret`, `azurerm_key_vault_certificate` |
| Google | `google_secret_manager_secret_version` |
| Kubernetes | `kubernetes_secret` |
| Vault | `vault_generic_secret` |

## Migration from Data Sources

```hcl
# OLD (1.9 and earlier) - Secrets in state!
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "prod/database/credentials"
}

# NEW (1.10+) - Secrets NOT in state
ephemeral "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "prod/database/credentials"
}
```

## Requirements

- Terraform >= 1.10 for ephemeral variables
- Terraform >= 1.11 for write-only arguments
- Provider support for ephemeral resource types
