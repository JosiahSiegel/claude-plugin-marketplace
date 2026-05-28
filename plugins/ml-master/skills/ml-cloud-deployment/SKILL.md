---
name: ml-cloud-deployment
description: |
  This skill should be used when the user asks to deploy, scale, or cost-optimize ML workloads on cloud platforms. PROACTIVELY activate for: (1) AWS SageMaker Studio, Training, Processing, Pipelines, Endpoints, Model Monitor, Feature Store, Clarify, Ground Truth, EC2 GPUs, EKS, Lambda, Inferentia, Trainium, (2) GCP Vertex AI Training, Pipelines, Endpoints, Feature Store, Model Monitoring, AutoML, Matching Engine, TPU, GKE, Cloud Run, (3) Azure ML workspaces, pipelines, managed endpoints, AutoML, Responsible ML, AKS/ACI, (4) Databricks, Modal, Replicate, RunPod, Lambda Labs, Anyscale. Provides: cloud ML architecture, autoscaling, hardware, security, and cost guidance.
---

# ML Cloud Deployment

## Overview

Use this skill for deploying ML workloads to managed platforms, Kubernetes, serverless systems, GPU/TPU providers, and lakehouse environments. Start from workload requirements: training or inference, batch or online, latency SLO, throughput, model size, data gravity, compliance, region, hardware, team expertise, and budget.

## Platform Selection

| Requirement | Strong choices |
|---|---|
| AWS-native managed lifecycle | SageMaker Studio, Training, Processing, Pipelines, Model Registry, Endpoints, Feature Store, Clarify, Model Monitor |
| GCP-native managed lifecycle | Vertex AI Training, Pipelines, Endpoints, Feature Store, Model Monitoring, AutoML, Matching Engine, TPUs |
| Azure-native managed lifecycle | Azure ML workspaces, compute clusters, pipelines, registries, managed online/batch endpoints, AutoML, Responsible ML |
| Lakehouse/Spark-centric ML | Databricks on AWS/Azure/GCP with MLflow, Delta, Feature Store, Workflows |
| Kubernetes control | EKS/GKE/AKS with Kubeflow, KServe, Seldon, Ray, Triton, custom operators |
| Serverless or fast GPU apps | Modal, Replicate, Cloud Run with GPU where available, Lambda for small CPU inference |
| Flexible GPU rental | Lambda Labs, RunPod, self-managed cloud GPU VMs |
| Ray-native scale-out | Anyscale or Ray clusters on Kubernetes/cloud VMs |

Prefer managed services when governance, observability, and team velocity matter more than runtime customization. Prefer Kubernetes or VMs when custom networking, specialized runtimes, or cost/performance tuning dominate.

## AWS Patterns

SageMaker handles managed training jobs, feature stores, and real-time or serverless endpoints. The AWS CLI (`aws sagemaker` and `aws sagemaker-runtime`) is used to orchestrate these systems programmatically.

### AWS SageMaker Endpoint Variant Configuration (`endpoint_config.json`)
```json
{
  "EndpointConfigName": "production-llm-classifier-v1-cfg",
  "ProductionVariants": [
    {
      "VariantName": "AllTraffic",
      "ModelName": "llm-classifier-model-v1",
      "InitialInstanceCount": 2,
      "InstanceType": "ml.g5.2xlarge",
      "InitialVariantWeight": 1.0,
      "VolumeSizeInGB": 50,
      "ManagedInstanceScaling": {
        "MinInstanceCount": 2,
        "MaxInstanceCount": 10,
        "Status": "ENABLED"
      },
      "RoutingConfig": {
        "RoutingStrategy": "LEAST_OUTSTANDING_REQUESTS"
      }
    }
  ]
}
```

### AWS CLI SageMaker Lifecycle Management

```bash
# 1. Setup Domain and default IAM Role/VPC settings
aws sagemaker create-domain \
  --domain-name ProdMLDomain \
  --auth-mode IAM \
  --default-user-settings ExecutionRole=arn:aws:iam::123456789012:role/SageMakerExecutionRole \
  --subnet-ids subnet-1a2b3c,subnet-4d5e6f \
  --vpc-id vpc-0abc123 \
  --app-network-access-type PublicInternetOnly

# 2. Provision and start/stop an interactive notebook instance
aws sagemaker create-notebook-instance \
  --notebook-instance-name dev-notebook-instance \
  --instance-type ml.t3.medium \
  --role-arn arn:aws:iam::123456789012:role/SageMakerExecutionRole

aws sagemaker start-notebook-instance --notebook-instance-name dev-notebook-instance
aws sagemaker stop-notebook-instance --notebook-instance-name dev-notebook-instance

# 3. Submit a managed GPU training job
aws sagemaker create-training-job \
  --training-job-name custom-pytorch-train-job \
  --algorithm-specification TrainingImage=763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-training:1.12.0-gpu-py38-cu113-ubuntu20.04,TrainingInputMode=File \
  --role-arn arn:aws:iam::123456789012:role/SageMakerExecutionRole \
  --input-data-config '[{"ChannelName": "training", "DataSource": {"S3DataSource": {"S3DataType": "S3Prefix", "S3Uri": "s3://my-ml-bucket/train-data/", "S3DataDistributionType": "FullyReplicated"}}}]' \
  --output-data-config S3OutputPath=s3://my-ml-bucket/checkpoints/ \
  --resource-config InstanceType=ml.g5.2xlarge,InstanceCount=1,VolumeSizeInGB=50 \
  --stopping-condition MaxRuntimeInSeconds=86400

# 4. Register a model in the SageMaker Model Registry
aws sagemaker create-model-package-group \
  --model-package-group-name credit-scoring-group \
  --model-package-group-description "Model registry group for credit scoring neural nets"

aws sagemaker create-model \
  --model-name credit-scoring-v1 \
  --primary-container Image=763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-inference:1.12.0-gpu-py38,ModelDataUrl=s3://my-ml-bucket/checkpoints/custom-pytorch-train-job/output/model.tar.gz \
  --execution-role-arn arn:aws:iam::123456789012:role/SageMakerExecutionRole

# 5. Create Endpoint Configuration and Deploy Endpoint
aws sagemaker create-endpoint-config \
  --endpoint-config-name credit-scoring-v1-cfg \
  --production-variants '[{"VariantName": "AllTraffic", "ModelName": "credit-scoring-v1", "InitialInstanceCount": 2, "InstanceType": "ml.m5.xlarge", "InitialVariantWeight": 1.0}]'

aws sagemaker create-endpoint \
  --endpoint-name credit-scoring-prod-endpoint \
  --endpoint-config-name credit-scoring-v1-cfg

# 6. Invoke/Test Endpoint via CLI
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name credit-scoring-prod-endpoint \
  --content-type application/json \
  --body '{"features": [0.25, 1.4, 0.9]}' \
  response_output.json
```

## GCP Patterns

Vertex AI manages training pipelines, hyperparameter tuning sweeps, custom jobs, the model registry, and predictions via `gcloud ai`.

### GCP Vertex AI TPU CustomJob Specification (`tpu_job.yaml`)
```yaml
displayName: vertex-ai-tpu-training-job
studySpec:
  metrics:
    - metricId: val_loss
      goal: MINIMIZE
  parameters:
    - parameterId: learning_rate
      doubleValueSpec:
        minValue: 1e-5
        maxValue: 1e-3
      scaleType: UNIT_LOG_SCALE
trialJobSpec:
  workerPoolSpecs:
    - machineSpec:
        machineType: n1-standard-8
      replicaCount: 1
      containerSpec:
        imageUri: gcr.io/my-project/ml-trainer:latest
    - machineSpec:
        machineType: cloud-tpu-v4-podslice
        acceleratorType: TPU_V4
        acceleratorCount: 4
      replicaCount: 1
      containerSpec:
        imageUri: gcr.io/my-project/ml-tpu-trainer:latest
        args: [
          "--data_path", "gs://my-bucket/dataset-v1",
          "--epochs", "10"
        ]
```

### GCP Vertex AI CLI Operations

```bash
# 1. Create a user-managed Jupyter Workbench instance
gcloud notebooks instances create dev-workbench-instance \
  --location=us-central1-a \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=common-gpu \
  --machine-type=n1-standard-4

# 2. Submit containerized custom training job
gcloud ai custom-jobs create \
  --region=us-central1 \
  --display-name=gpu-pytorch-training-run \
  --worker-pool-spec=replica-count=1,machine-type=n1-standard-8,accelerator-type=nvidia-tesla-t4,accelerator-count=1,container-image-uri=gcr.io/my-gcp-project/pytorch-train-custom:v1 \
  --args="--epochs=20,--data-path=gs://my-bucket/training-gold"

# 3. Upload model artifact to Model Registry
gcloud ai models upload \
  --region=us-central1 \
  --display-name=iris-classifier-v1 \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/pytorch-cpu.1-11:latest \
  --artifact-uri=gs://my-bucket/models/iris-classifier/

# 4. Provision endpoint and deploy model with 100% traffic allocation
# Note: replace <ENDPOINT-ID> and <MODEL-ID> with their UUIDs
gcloud ai endpoints create \
  --region=us-central1 \
  --display-name=production-iris-endpoint

gcloud ai endpoints deploy-model <ENDPOINT-ID> \
  --region=us-central1 \
  --model=<MODEL-ID> \
  --display-name=iris-v1-blue-deployment \
  --machine-type=n1-standard-4 \
  --min-replica-count=2 \
  --max-replica-count=10 \
  --traffic-split=0=100

# 5. Predict via Vertex AI Endpoint CLI
gcloud ai endpoints predict <ENDPOINT-ID> \
  --region=us-central1 \
  --json-request=sample_payload.json
```

## Azure Patterns

Azure AI Foundry / Azure Machine Learning Workspace orchestrates the entire ML lifecycle. Workspace, computes, environments, data assets, training jobs, models, and endpoints can be managed natively using the Azure CLI `ml` extension. For Azure ML code asset registration from CI, ADF orchestration, ADF WebActivity networking, `result.version` propagation, pointer blobs, or private storage firewall handling, load `ml-azureml-adf-automation`.

### Azure ML v2 CLI Online Endpoint & Deployment YAML (`azure_deploy.yaml`)
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: credit-risk-endpoint
auth_mode: key
---
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: credit-risk-blue
endpoint_name: credit-risk-endpoint
model: azureml:credit-risk-model:1
code_configuration:
  code: ./src
  scoring_script: score.py
environment: azureml:credit-risk-env:1
instance_type: Standard_DS3_v2
instance_count: 2
request_settings:
  request_timeout_ms: 3000
  max_concurrent_requests_per_instance: 10
scale_settings:
  type: default
```

### Azure AI Foundry / Azure ML Workspace CLI Management (`az ml`)

```bash
# Add/update the Machine Learning CLI extension
az extension add -n ml -y
az login

# 1. Create a Resource Group and Azure ML Workspace (Azure AI Foundry Hub)
az group create --name my-ml-rg --location eastus
az ml workspace create --name my-ml-workspace --resource-group my-ml-rg --location eastus

# 2. Provision Computes (Instance, Training Cluster, CPU cluster)
az ml compute create --name dev-compute-ci --type ComputeInstance --size Standard_DS3_v2 -g my-ml-rg -w my-ml-workspace
az ml compute create --name gpu-train-cluster --type AmlCompute --size Standard_NC6s_v3 --min-instances 0 --max-instances 4 -g my-ml-rg -w my-ml-workspace
az ml compute create --name cpu-proc-cluster --type AmlCompute --size Standard_DS12_v2 --min-instances 0 --max-instances 8 -g my-ml-rg -w my-ml-workspace

# 3. Create a URI Data Asset
az ml data create --file data.yaml -g my-ml-rg -w my-ml-workspace

# 4. Create an Environment definition
az ml environment create --file env.yaml -g my-ml-rg -w my-ml-workspace

# 5. Submit, Monitor, and Stream a Command Job
az ml job create --file job.yaml -g my-ml-rg -w my-ml-workspace --web --stream

# View, list and monitor jobs
az ml job list -g my-ml-rg -w my-ml-workspace --output table
az ml job stream --name <job-id> -g my-ml-rg -w my-ml-workspace
az ml job download --name <job-id> --download-path ./outputs -g my-ml-rg -w my-ml-workspace

# 6. Register a Model
az ml model create --file model.yaml -g my-ml-rg -w my-ml-workspace

# 7. Create Endpoint, Deploy, Test, and Cleanup
az ml online-endpoint create --file endpoint.yaml -g my-ml-rg -w my-ml-workspace
az ml online-deployment create --file deployment.yaml --all-traffic -g my-ml-rg -w my-ml-workspace

# List and monitor endpoints:
az ml online-endpoint show --name credit-risk-endpoint -g my-ml-rg -w my-ml-workspace

# Test endpoint with a sample payload file:
az ml online-endpoint invoke --name credit-risk-endpoint --request-file ./sample_request.json -g my-ml-rg -w my-ml-workspace

# Delete endpoint:
az ml online-endpoint delete --name credit-risk-endpoint --yes -g my-ml-rg -w my-ml-workspace
```

## Local & Hybrid Providers (MLflow & Kubernetes/KServe)

For local development or custom multi-cloud Kubernetes clusters, MLflow and KServe provide standardization.

### MLflow Local CLI Management

```bash
# 1. Start a local tracking and model registry server
mlflow server \
  --host 127.0.0.1 \
  --port 5000 \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root ./mlflow_artifacts_store

# 2. Run a packaged local MLflow Project with runtime parameters
mlflow run . -P alpha=0.1 -P l1_ratio=0.2 --experiment-name iris-training

# 3. Serve a registered model locally
mlflow models serve \
  --model-uri models:/iris-classifier/Production \
  --port 5001 \
  --no-conda

# 4. Invoke the local serving endpoint
curl -X POST -H "Content-Type: application/json" \
  -d '{"dataframe_split": {"columns": ["sepal_len", "sepal_wid"], "data": [[5.1, 3.5]]}}' \
  http://127.0.0.1:5001/invocations
```

### Kubernetes Native Serving CLI (KServe)

```yaml
# kserve-inference.yaml
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "sklearn-iris"
  namespace: "ml-serving"
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"
      resources:
        limits:
          cpu: "1"
          memory: 2Gi
        requests:
          cpu: "500m"
          memory: 1Gi
```

```bash
# 1. Apply inference manifests via kubectl
kubectl apply -f kserve-inference.yaml -n ml-serving

# 2. Monitor status and readiness of inference service
kubectl get inferenceservice sklearn-iris -n ml-serving

# 3. Port forward or direct payload query through Istio ingress gateway
SERVICE_HOSTNAME=$(kubectl get inferenceservice sklearn-iris -n ml-serving -o jsonpath='{.status.url}' | cut -d/ -f3)
INGRESS_IP=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

curl -v -H "Host: ${SERVICE_HOSTNAME}" \
  http://${INGRESS_IP}:${INGRESS_PORT}/v1/models/sklearn-iris:predict \
  -d @sample_payload.json
```


## Serverless GPU serving (Modal Pattern)

For serverless deployments on isolated GPUs with zero-cold-start optimization, use Modal.

```python
import modal

app = modal.App("serverless-image-classifier")

# Pre-packaged CUDA image with dependencies
image = (
    modal.Image.debian_slim()
    .pip_install("torch", "torchvision", "transformers")
)

@app.cls(gpu="A10G", image=image)
class ImageClassifier:
    @modal.enter()
    def load_model(self):
        import torch
        from transformers import ViTForImageClassification, ViTImageProcessor
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.processor = ViTImageProcessor.from_pretrained("google/vit-base-patch16-224")
        self.model = ViTForImageClassification.from_pretrained("google/vit-base-patch16-224").to(self.device)

    @modal.method()
    def predict(self, image_bytes: bytes):
        from PIL import Image
        import io
        image = Image.open(io.BytesIO(image_bytes))
        inputs = self.processor(images=image, return_tensors="pt").to(self.device)
        outputs = self.model(**inputs)
        logits = outputs.logits
        predicted_class_idx = logits.argmax(-1).item()
        return self.model.config.id2label[predicted_class_idx]
```

## Hardware Selection

Match hardware to bottleneck:
- CPU: classical ML, preprocessing, small models, latency-insensitive batch jobs.
- T4/L4/A10-class GPUs: cost-effective inference, fine-tuning smaller models, notebooks.
- A100/H100/H200/B200-class GPUs: large model training, high-throughput inference, memory-heavy workloads.
- TPUs: supported dense tensor workloads at scale, especially JAX/TensorFlow ecosystems.
- Inferentia/Trainium: AWS cost/performance if model operators and framework support are mature.

Estimate memory before launching: model weights, optimizer states, gradients, activations, KV cache, batch size, sequence length, and runtime overhead. For inference, benchmark p50/p95/p99 latency under realistic concurrency and payload sizes.

## Endpoint Design

Define request schema, response schema, timeout, max payload, auth, rate limits, autoscaling policy, health checks, logging, and rollback. Use canary or blue/green releases for production. For GPU endpoints, tune dynamic batching and concurrency carefully; too much concurrency can increase tail latency or cause OOM. For multi-region deployments, replicate artifacts, keep model versions consistent, and plan data residency and failover.

## Security and Compliance

Use private networking when models access sensitive data. Store secrets in cloud secret managers. Use least-privilege IAM/service accounts/managed identities. Encrypt data and artifacts. Log access and deployment events. Scan containers. Avoid baking credentials into images. For public endpoints, apply auth, input validation, abuse controls, rate limits, and prompt-injection defenses for LLM/RAG systems.

## Cost Optimization

Use spot/preemptible instances for checkpointed training and stateless batch jobs. Use autoscaling endpoints with scale-to-zero when acceptable. Prefer batch inference for non-real-time workloads. Quantize or distill models before scaling replicas. Right-size GPU memory, not just GPU count. Use reserved/committed capacity only after workload shape is stable. Track cost per run, per model version, and per 1,000 predictions.

## Deployment Readiness Checklist

- Model artifact, preprocessing, tokenizer, and config are versioned together.
- Input schema is validated and compatible with training features.
- Evaluation report includes relevant slices and latency/cost benchmarks.
- Endpoint has health checks, autoscaling, logs, metrics, alerts, and rollback.
- Security controls cover identity, secrets, network, encryption, and audit.
- Monitoring captures drift, data quality, prediction distribution, outcomes, and incidents.

## Sources

- AWS SageMaker documentation: https://docs.aws.amazon.com/sagemaker/
- Google Vertex AI documentation: https://cloud.google.com/vertex-ai/docs
- Azure Machine Learning documentation: https://learn.microsoft.com/azure/machine-learning/
- Databricks Machine Learning documentation: https://docs.databricks.com/machine-learning/
- Ray and Anyscale documentation: https://docs.ray.io/ and https://docs.anyscale.com/
