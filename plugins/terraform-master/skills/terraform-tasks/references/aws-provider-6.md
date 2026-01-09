# AWS Provider 6.0 GA Reference (2025)

## Breaking Changes

### Multi-Region Support
- Enhanced `region` attribute support for S3 resources
- `bucket_region` attribute now available on `aws_s3_bucket`
- Can specify region per-resource without multiple provider configurations

### Deprecated Services (Removed)
- **Amazon Chime**: Use `aws_chime_voice_connector` alternatives
- **Amazon Evidently**: Migrate to CloudWatch RUM
- **AWS MediaStore**: Use S3 with CloudFront

### Resource Renames
```hcl
# Old (5.x)
resource "aws_s3_bucket_acl" "example" { ... }

# New (6.0) - Same but ACLs deprecated
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  # Object ownership enforces bucket owner
  object_ownership = "BucketOwnerEnforced"
}
```

## Migration Guide

### Step 1: Check Provider Version
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

### Step 2: Update Deprecated Resources
```bash
# Find deprecated resources
grep -r "aws_chime\|aws_evidently\|aws_mediastore" *.tf
```

### Step 3: Update S3 Configurations
```hcl
# Modern S3 bucket (6.0+)
resource "aws_s3_bucket" "main" {
  bucket = "my-bucket"

  tags = {
    Environment = "production"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## New Features

### Enhanced Region Support
```hcl
# Multi-region bucket replication without multiple providers
resource "aws_s3_bucket" "source" {
  bucket = "source-bucket"
}

resource "aws_s3_bucket" "destination" {
  bucket = "destination-bucket"
  # Can now specify region directly
}
```

### New Resources (6.0)
- `aws_bedrockagent_*` - Bedrock Agent resources
- `aws_sagemaker_*` - Additional SageMaker resources
- Enhanced Lambda resources
- VPC Lattice improvements

## Compatibility Matrix

| Feature | AWS 5.x | AWS 6.0 |
|---------|---------|---------|
| Multi-region S3 | Multiple providers | Single provider |
| Chime resources | Supported | Removed |
| Evidently | Supported | Removed |
| MediaStore | Supported | Removed |
| Bedrock Agent | Limited | Full support |
