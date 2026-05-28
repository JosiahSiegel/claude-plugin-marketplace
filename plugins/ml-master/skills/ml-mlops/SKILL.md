---
name: ml-mlops
description: |
  This skill should be used when the user asks to productionize, track, version, govern, monitor, or automate ML systems. PROACTIVELY activate for: (1) MLflow, Weights & Biases, Neptune, Comet, ClearML experiment tracking, (2) model registry, model versioning, artifact lineage, reproducibility, (3) Kubeflow, SageMaker Pipelines, Vertex AI Pipelines, Azure ML pipelines, Databricks workflows, (4) CI/CD, continuous training/evaluation, A/B tests, canary/shadow deployments, (5) drift detection, model monitoring, data validation, responsible AI governance. Provides: end-to-end MLOps architecture and operational safeguards.
---

# ML MLOps

## Overview

Use this skill for operational machine learning: experiment tracking, reproducibility, orchestration, registries, CI/CD, model deployment governance, monitoring, drift response, and retraining. MLOps turns notebooks and scripts into auditable, repeatable systems with clear ownership and rollback.

## MLOps Invariants

Every production ML workflow should answer:
- Which data, code, config, environment, and hardware produced this model?
- Which metrics, slices, and tests justified promotion?
- Where is the model artifact stored, and how can it be rolled back?
- What validates incoming data and serving features?
- What monitors quality, drift, latency, cost, safety, and fairness?
- Who owns incidents, retraining, approvals, and deprecation?

If any answer is missing, fix the lifecycle before adding more infrastructure.

## Experiment Tracking

Track parameters, metrics, artifacts, dataset versions, code revisions, environment, random seeds, run notes, and tags. MLflow is a strong default for open model registry workflows; Weights & Biases excels for rich experiment dashboards and sweeps; Neptune, Comet, and ClearML cover similar collaboration and artifact-management needs. Choose based on governance, hosting, integrations, and team workflow rather than dashboard aesthetics alone.

Use consistent naming for experiments and runs. Log both final metrics and learning curves. Store confusion matrices, calibration plots, feature importance, validation predictions, and representative errors. Avoid logging secrets, raw PII, or proprietary examples unless the tracking backend is approved for that data class.

## Model Registry and Versioning

A registry entry should include artifact URI, model signature or schema, input/output examples, preprocessing/tokenizer references, dependency environment, training dataset identifier, evaluation report, approval state, owner, changelog, and intended use.

### Standardized Model Registry Metadata Schema (JSON)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ModelRegistryMetadata",
  "type": "object",
  "properties": {
    "model_name": { "type": "string" },
    "version": { "type": "string" },
    "artifact_uri": { "type": "string", "format": "uri" },
    "framework": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "version": { "type": "string" }
      },
      "required": ["name", "version"]
    },
    "signature": {
      "type": "object",
      "properties": {
        "inputs": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": { "type": "string" },
              "type": { "type": "string" },
              "shape": { "type": "array", "items": { "type": "integer" } }
            },
            "required": ["name", "type"]
          }
        },
        "outputs": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": { "type": "string" },
              "type": { "type": "string" },
              "shape": { "type": "array", "items": { "type": "integer" } }
            },
            "required": ["name", "type"]
          }
        }
      },
      "required": ["inputs", "outputs"]
    },
    "provenance": {
      "type": "object",
      "properties": {
        "git_commit": { "type": "string" },
        "dataset_snapshot_uri": { "type": "string" },
        "environment_lockfile_uri": { "type": "string" }
      },
      "required": ["git_commit", "dataset_snapshot_uri"]
    }
  },
  "required": ["model_name", "version", "artifact_uri", "framework", "signature", "provenance"]
}
```

Stage transitions should be controlled by automated quality gates and human approval where risk requires it. Use semantic model labels such as `candidate`, `staging`, `production`, and `archived` only if their meaning is enforced. Version datasets with tools such as DVC, lakehouse table versions, object-storage manifests, or feature-store materialization timestamps. The model version alone is not enough; the data and feature code are part of the model.

## Pipeline Orchestration

Choose orchestration by operational environment:

| Platform | Best fit |
|---|---|
| Kubeflow Pipelines | Kubernetes-native ML workflows, portable components, complex DAGs |
| SageMaker Pipelines | AWS-native training, processing, model registry, endpoints, Feature Store, Clarify, Model Monitor |
| Vertex AI Pipelines | GCP-native training, endpoints, Feature Store, Model Monitoring, AutoML integration |
| Azure ML Pipelines | Azure workspaces, managed compute, registries, managed endpoints, Responsible ML |
| Databricks Workflows | Lakehouse-centric feature engineering, MLflow registry, Spark, Delta, notebooks/jobs |
| Airflow/Prefect/Dagster | General data/ML orchestration with broad ecosystem integrations |

Keep pipelines modular: data validation, feature generation, training, evaluation, registration, deployment, and monitoring setup should be separate steps with explicit inputs and outputs. Make steps idempotent and cache-aware where safe. For Azure ML code asset registration in CI, ADF-to-Azure-ML version propagation, pointer blobs, or runtime validation of ADF WebActivity paths, load `ml-azureml-adf-automation`.

## CI/CD for ML

CI should run fast checks: code linting, unit tests for preprocessing, schema tests, deterministic small-data training smoke tests, model-loading tests, serialization tests, inference contract tests, and security scans. CD should deploy only artifacts that passed evaluation gates.

### Production GitHub Actions MLOps Workflow (`.github/workflows/mlops.yml`)
```yaml
name: MLOps CI/CD Workflow

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
        cache: 'pip'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install ruff pytest pytest-cov -r requirements.txt
    - name: Lint with Ruff
      run: ruff check src/
    - name: Run unit tests
      run: pytest tests/unit/ --cov=src --cov-report=xml
      
  model-smoke-test:
    needs: lint-and-test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    - name: Run small-scale training smoke test
      run: |
        pip install -r requirements.txt
        python src/train.py --config configs/smoke_test.yaml
    - name: Verify model serialization & load contract
      run: python src/verify_contract.py --model_path outputs/model.pt

  promote-and-deploy:
    needs: model-smoke-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Deploy model to Staging endpoint
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      run: |
        pip install awscli
        # Trigger staging endpoint update
        python scripts/deploy.py --stage staging
```

For model serving, use blue/green, canary, shadow, or A/B deployment. Canary small traffic first, monitor guardrails, then expand. Shadow mode is useful for risk-free comparison but cannot measure user-impact metrics unless decisions are acted on. Always keep rollback simple and tested.

## Data Validation

Validate data before training and serving. Great Expectations, TFDV, and Deequ can enforce schemas and distribution expectations. 

### Great Expectations Validation Suite Setup
```python
import great_expectations as ge
from great_expectations.core.expectation_suite import ExpectationSuite

def create_ingestion_validation_suite(suite_name: str = "ingestion_suite") -> ExpectationSuite:
    context = ge.get_context()
    suite = context.create_expectation_suite(suite_name, overwrite_existing=True)
    
    # Assert column names exist
    suite.add_expectation({
        "expectation_type": "expect_table_columns_to_match_ordered_list",
        "kwargs": {
            "column_list": ["user_id", "timestamp", "feature_a", "feature_b", "label"]
        }
    })
    
    # Assert feature_a ranges
    suite.add_expectation({
        "expectation_type": "expect_column_values_to_be_between",
        "kwargs": {
            "column": "feature_a",
            "min_value": 0.0,
            "max_value": 100.0
        }
    })
    
    # Assert label is never null
    suite.add_expectation({
        "expectation_type": "expect_column_values_to_not_be_null",
        "kwargs": {
            "column": "label"
        }
    })
    
    context.save_expectation_suite(suite)
    return suite
```

Ensure time-travel joins prevent future leakage and that online feature freshness is monitored.

## Monitoring and Drift

Monitor at four layers:
1. System: availability, latency, throughput, errors, GPU/CPU/memory utilization, queue length, cost.
2. Data: schema, nulls, ranges, categorical cardinality, embedding norms, text length, image dimensions, feature distribution drift.
3. Prediction: score distribution, confidence, calibration, class distribution, threshold outcomes, refusal/safety labels.
4. Outcome: delayed labels, business metrics, fairness slices, human review rates, incidents.

### Production Monitoring Alerting Thresholds Reference

| Metric Category | Target Metric | Recommended Alert Threshold | Diagnostic Action |
|---|---|---|---|
| **System** | p99 Latency | > 200ms for 5 consecutive minutes | Inspect serving container thread pool, GPU/CPU bottlenecks, network storage |
| **System** | Error Rate | > 1.0% in any 1-minute window | Check serving backend logs for raw input validation OOMs or schema violations |
| **Data** | Feature Drift (PSI) | Population Stability Index > 0.25 | Trigger investigation: check for source data schema shifts or upstream filter changes |
| **Prediction**| Score Drift (KS) | Kolmogorov-Smirnov Test p-value < 0.01 | Alert on potential label/concept drift; compare prediction distribution with baseline |
| **Outcome** | Calibration Drift | Brier Score degradation > 15% vs baseline | Check for concept drift; flag for log collection and manual labeling queue |

Drift is a signal to investigate, not automatic proof that retraining improves outcomes.

## Governance, Security, and Compliance

Document intended use, out-of-scope use, training data constraints, model limitations, known risks, and evaluation slices. Apply least-privilege access to data, artifacts, registries, and endpoints. Scan containers and dependencies. Protect secrets in managed secret stores. Encrypt artifacts and data in transit and at rest. For sensitive systems, maintain audit logs for data access, approvals, deployments, and incidents.

## Cost Controls

Tag resources by project and owner, use autoscaling, right-size endpoints, shut down idle notebooks and clusters, prefer spot/preemptible training only with checkpoints, schedule batch inference off-peak, and evaluate serverless or CPU inference when latency permits. Track cost per training run, cost per 1,000 predictions, and cost per accepted model improvement.

## Sources

- MLflow documentation: https://mlflow.org/docs/latest/index.html
- Weights & Biases documentation: https://docs.wandb.ai/
- Kubeflow Pipelines documentation: https://www.kubeflow.org/docs/components/pipelines/
- AWS SageMaker MLOps documentation: https://docs.aws.amazon.com/sagemaker/
- Vertex AI MLOps documentation: https://cloud.google.com/vertex-ai/docs
- Azure Machine Learning documentation: https://learn.microsoft.com/azure/machine-learning/
