# OpenTofu 1.11 Features Reference (Beta)

## Ephemeral Resources

Work with confidential data without persisting to state:

```hcl
# Ephemeral AWS Secret
ephemeral "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "prod/api-key"
}

# Use in resource (never stored in state)
resource "aws_lambda_function" "main" {
  function_name = "my-function"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      API_KEY = ephemeral.aws_secretsmanager_secret_version.api_key.secret_string
    }
  }
}
```

### Conditional Ephemeral Resources
```hcl
ephemeral "aws_secretsmanager_secret_version" "optional_secret" {
  secret_id = "prod/optional-key"

  lifecycle {
    enabled = var.use_secrets  # Only create if needed
  }
}
```

## Enabled Meta-Argument

Conditional resource deployment without count hacks:

```hcl
# Traditional count approach (awkward)
resource "aws_instance" "web" {
  count = var.deploy_web_server ? 1 : 0
  # ...
}

# OpenTofu 1.11 approach (cleaner)
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  lifecycle {
    enabled = var.deploy_web_server
  }
}
```

### Complex Conditions
```hcl
variable "environment" {
  type = string
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  lifecycle {
    # Only create in production with monitoring enabled
    enabled = var.environment == "prod" && var.enable_monitoring
  }
}
```

### With Modules
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  lifecycle {
    enabled = var.enable_monitoring
  }
}
```

## Ephemeral vs Enabled Comparison

| Feature | Ephemeral | Enabled |
|---------|-----------|---------|
| Purpose | Secret handling | Conditional creation |
| State storage | Never | Normal (when enabled) |
| Use case | Passwords, keys | Feature flags |
| Terraform equivalent | 1.10+ ephemeral | count = var ? 1 : 0 |

## Combined Usage

```hcl
variable "deploy_database" {
  type    = bool
  default = true
}

variable "use_secrets_manager" {
  type    = bool
  default = true
}

# Ephemeral secret (only when database deployed)
ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db-password"

  lifecycle {
    enabled = var.deploy_database && var.use_secrets_manager
  }
}

# Database (conditionally deployed)
resource "aws_db_instance" "main" {
  identifier     = "mydb"
  engine         = "postgres"
  instance_class = "db.t3.micro"

  password = var.use_secrets_manager ? ephemeral.aws_secretsmanager_secret_version.db_password.secret_string : var.db_password_fallback

  lifecycle {
    enabled = var.deploy_database
  }
}
```

## Migration from Count

```hcl
# Before (Terraform/OpenTofu 1.10)
resource "aws_instance" "optional" {
  count = var.create_instance ? 1 : 0

  ami           = "ami-12345678"
  instance_type = "t3.micro"
}

# After (OpenTofu 1.11)
resource "aws_instance" "optional" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  lifecycle {
    enabled = var.create_instance
  }
}

# Benefits:
# - No [0] indexing needed
# - Cleaner references
# - Better error messages
```

## Installation

```bash
# Install beta version
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --version 1.11.0-beta1

# Or via Homebrew
brew install opentofu --HEAD
```

## Caveats (Beta)

1. **Beta status**: Features may change before GA
2. **State format**: May require migration for beta features
3. **Provider support**: Not all providers support ephemeral resources yet
4. **Testing**: Limited production testing

## When to Use OpenTofu 1.11

- Need ephemeral resources for secrets (like Terraform 1.10+)
- Want cleaner conditional logic (enabled meta-argument)
- Prefer open-source alternative to Terraform
- Already using OpenTofu 1.10
