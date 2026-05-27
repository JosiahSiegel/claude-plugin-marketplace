---
name: ml-training
description: |
  This skill should be used when the user asks to train, debug, scale, or improve ML models. PROACTIVELY activate for: (1) PyTorch, TensorFlow/Keras, JAX, Flax, Hugging Face Trainer/Accelerate training loops, (2) distributed training, DDP/FSDP/DeepSpeed, TPU/GPU setup, (3) mixed precision AMP/bf16, gradient accumulation, checkpointing, seeding, (4) overfitting, imbalance, loss functions, regularization, LR schedules, warmup, (5) memory optimization, gradient checkpointing, offloading, quantization-aware training. Provides: reproducible training best practices across deep learning and classical ML.
---

# ML Training

## Overview

Use this skill for model training across PyTorch, TensorFlow/Keras, JAX/Flax, Hugging Face Transformers/Diffusers/Accelerate/PEFT, scikit-learn, XGBoost, LightGBM, CatBoost, Spark MLlib, and Ray. Optimize for correctness first: validated data, leakage-safe splits, reproducible configuration, meaningful metrics, and a simple baseline before complex distributed or accelerator-heavy runs.

## Training Readiness Checklist

1. Define task, target, metric, baseline, and acceptance threshold.
2. Validate data schema, label quality, missingness, duplicates, class balance, and train/serving feature parity.
3. Choose split strategy: random stratified for iid classification, grouped for correlated entities, time-based for temporal data, nested CV for model-selection claims.
4. Pin environment: framework versions, CUDA/cuDNN, drivers, dataset snapshot, preprocessing code, model config, and hardware.
5. Set seeds where meaningful and record nondeterministic operations. Do not promise bitwise reproducibility across GPUs or distributed kernels unless deterministic modes are verified.
6. Start with a small overfit test on a tiny batch, then a full baseline, then tuning or scale-out.

## Training Loop Essentials

For deep learning, every training loop should make the forward pass, loss computation, backward pass, optimizer step, scheduler step, gradient zeroing, metric logging, validation, checkpointing, and early stopping explicit.

### Production-Grade PyTorch Training Loop Blueprint (with AMP, Accumulation & Clipping)

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torch.cuda.amp import autocast, GradScaler

def train_one_epoch(
    model: nn.Module, 
    dataloader: DataLoader, 
    optimizer: torch.optim.Optimizer, 
    criterion: nn.Module, 
    device: torch.device,
    scaler: GradScaler,
    scheduler = None,
    grad_accum_steps: int = 1,
    max_grad_norm: float = 1.0
):
    model.train()
    optimizer.zero_grad(set_to_none=True)
    total_loss = 0.0
    
    for step, (inputs, targets) in enumerate(dataloader):
        inputs, targets = inputs.to(device, non_blocking=True), targets.to(device, non_blocking=True)
        
        # Mixed precision forward pass
        with autocast(dtype=torch.float16): # or torch.bfloat16 if hardware supports it
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            # Scale loss for gradient accumulation
            loss = loss / grad_accum_steps
            
        # Scaled backpropagation
        scaler.scale(loss).backward()
        
        if (step + 1) % grad_accum_steps == 0 or (step + 1) == len(dataloader):
            # Unscales gradients before clipping
            scaler.unscale_(optimizer)
            # Gradient clipping to prevent exploding gradients
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_grad_norm)
            
            # Step optimizer and update scale factor
            scaler.step(optimizer)
            scaler.update()
            optimizer.zero_grad(set_to_none=True)
            
            if scheduler is not None:
                scheduler.step()
                
        total_loss += loss.item() * grad_accum_steps
        
    return total_loss / len(dataloader)

@torch.inference_mode()
def validate(model: nn.Module, dataloader: DataLoader, criterion: nn.Module, device: torch.device):
    model.eval()
    total_loss = 0.0
    correct = 0
    total = 0
    
    for inputs, targets in dataloader:
        inputs, targets = inputs.to(device, non_blocking=True), targets.to(device, non_blocking=True)
        outputs = model(inputs)
        loss = criterion(outputs, targets)
        total_loss += loss.item()
        
        _, predicted = outputs.max(1)
        total += targets.size(0)
        correct += predicted.eq(targets).sum().item()
        
    return total_loss / len(dataloader), correct / total
```

In TensorFlow/Keras, prefer built-in `fit` when callbacks and distribution strategies are sufficient; use `tf.GradientTape` for custom control. In JAX/Flax, keep state explicit, use pure update functions, and separate PRNG keys for dropout, augmentation, and sampling.

For classical ML, build preprocessing inside a pipeline object so cross-validation applies transformations only on training folds.

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer
from xgboost import XGBClassifier

numeric_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='median')),
    ('scaler', StandardScaler())
])

categorical_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='most_frequent')),
    ('onehot', OneHotEncoder(handle_unknown='ignore'))
])

preprocessor = ColumnTransformer(transformers=[
    ('num', numeric_transformer, numeric_cols),
    ('cat', categorical_transformer, categorical_cols)
])

clf_pipeline = Pipeline(steps=[
    ('preprocessor', preprocessor),
    ('classifier', XGBClassifier(use_label_encoder=False, eval_metric='logloss'))
])
```

## Optimizers, Schedules, and Regularization

Use AdamW as a strong deep-learning default when weight decay should be decoupled; use SGD with momentum for some vision regimes; use Adafactor or 8-bit optimizers only when memory pressure justifies it. Exclude bias and normalization parameters from weight decay for transformer-style models unless the architecture documentation says otherwise.

Learning-rate strategy usually matters more than optimizer micro-tuning. Common defaults:
- Warmup plus cosine decay for transformers and large-batch training.
- One-cycle or cosine restarts for exploratory training.
- Reduce-on-plateau for smaller supervised tasks with noisy convergence.
- Linear warmup scaled by effective batch size when increasing global batch.

Detect overfitting with train/validation curves, not final metrics alone. Use data augmentation, dropout, label smoothing, weight decay, early stopping, mixup/cutmix, stronger validation splits, or smaller models. For underfitting, check labels, feature signal, loss scaling, optimizer learning rate, capacity, and preprocessing bugs before adding complexity.

## Batch Size, Accumulation, and Precision

Effective batch size equals per-device batch size times devices times gradient accumulation steps. Increase batch size for throughput only if validation quality remains stable. If memory is limited, use gradient accumulation, activation checkpointing, shorter sequences, smaller images, bucketing, parameter-efficient fine-tuning, optimizer state sharding, or offloading.

Use mixed precision for modern accelerators. Prefer bf16 on hardware with native bf16 support because it reduces loss-scaling issues; use fp16 AMP with dynamic loss scaling otherwise. Keep numerically sensitive operations such as some reductions, softmax/logits handling, and metric accumulation in fp32 when needed. Watch for NaNs, overflow, underflow, and unstable normalization.

## Distributed Training Patterns

Choose the simplest distribution mode that satisfies the bottleneck:

| Pattern | Use when | Caveats |
|---|---|---|
| Data parallel / DDP | Model fits on one device; need faster throughput | Needs correct global batch, sampler sharding, synchronized metrics |
| FSDP / ZeRO | Model fits only with sharded parameters/optimizer state | More checkpoint complexity; tune wrapping and offload |
| Tensor parallel | Individual layers exceed one device or need large transformer scale | Requires framework/runtime support; communication-heavy |
| Pipeline parallel | Very deep models need layer partitioning | Bubble overhead; microbatch scheduling matters |
| Expert/model parallel | Mixture-of-effects or huge models | Routing/load-balance complexity |

### PyTorch DDP / FSDP Initialization Blueprint
```python
import os
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.distributed.fsdp import FullyShardedDataParallel as FSDP

def setup_distributed():
    # Environment variables set by torchrun
    world_size = int(os.environ["WORLD_SIZE"])
    rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])
    
    dist.init_process_group(
        backend="nccl", 
        init_method="env://", 
        world_size=world_size, 
        rank=rank
    )
    torch.cuda.set_device(local_rank)
    return rank, local_rank, world_size

def cleanup():
    dist.destroy_process_group()

# Usage DDP:
# rank, local_rank, _ = setup_distributed()
# model = MyModel().to(local_rank)
# model = DDP(model, device_ids=[local_rank])

# Usage FSDP:
# rank, local_rank, _ = setup_distributed()
# model = MyModel().to(local_rank)
# model = FSDP(model)
```

### DeepSpeed JSON Config Blueprint (`deepspeed_config.json`)
```json
{
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto",
  "gradient_accumulation_steps": "auto",
  "zero_optimization": {
    "stage": 2,
    "allgather_partitions": true,
    "allgather_bucket_size": 5e8,
    "overlap_comm": true,
    "reduce_scatter": true,
    "reduce_bucket_size": 5e8,
    "contiguous_gradients": true,
    "cpu_offload": false
  },
  "fp16": {
    "enabled": true,
    "loss_scale": 0,
    "loss_scale_window": 1000,
    "initial_scale_power": 16,
    "hysteresis": 2,
    "min_loss_scale": 1
  },
  "optimizer": {
    "type": "AdamW",
    "params": {
      "lr": "auto",
      "betas": [0.9, 0.999],
      "eps": 1e-8,
      "weight_decay": "auto"
    }
  }
}
```

## Checkpointing and Fault Tolerance

A recoverable checkpoint includes model weights, optimizer state, scheduler state, scaler state, epoch/step, RNG states where feasible, tokenizer/preprocessor, label mapping, config, metrics history, and code or commit identifier. Save best-by-validation and last checkpoints separately. Test resume before long training. Store artifacts in durable storage rather than ephemeral worker disks.

### PyTorch Robust Save and Load Checkpoint
```python
def save_checkpoint(state, is_best, checkpoint_dir="checkpoints"):
    os.makedirs(checkpoint_dir, exist_ok=True)
    filepath = os.path.join(checkpoint_dir, "last_checkpoint.pt")
    torch.save(state, filepath)
    if is_best:
        shutil.copyfile(filepath, os.path.join(checkpoint_dir, "best_model.pt"))

def load_checkpoint(filepath, model, optimizer=None, scheduler=None, scaler=None):
    checkpoint = torch.load(filepath, map_location="cpu")
    model.load_state_dict(checkpoint["state_dict"])
    if optimizer is not None and "optimizer" in checkpoint:
        optimizer.load_state_dict(checkpoint["optimizer"])
    if scheduler is not None and "scheduler" in checkpoint:
        scheduler.load_state_dict(checkpoint["scheduler"])
    if scaler is not None and "scaler" in checkpoint:
        scaler.load_state_dict(checkpoint["scaler"])
    return checkpoint.get("epoch", 0), checkpoint.get("best_metric", float("inf"))
```

## Imbalanced and Noisy Data

For class imbalance, first choose metrics that reflect the objective: PR-AUC, F1 variants, balanced accuracy, recall at precision, cost-weighted utility, or calibration. Use class weights, focal loss, balanced sampling, threshold tuning, or data collection. Avoid oversampling before splitting. For label noise, inspect high-loss examples, use robust loss functions, relabel critical samples, and report uncertainty.

## Scaling and Advanced Training

Apply scaling laws pragmatically: estimate whether quality is data-limited, model-limited, or compute-limited before scaling. Track loss versus compute, data size, and parameter count. For large models, consider curriculum learning, data quality filtering, deduplication, sequence packing, token budget accounting, and compute-optimal trade-offs. For RLHF or reinforcement learning, verify reward quality, offline evaluation, safety constraints, and distribution shift before online optimization.

## Common Failure Diagnosis

- Training loss does not decrease: wrong labels, frozen parameters, bad LR, loss/activation mismatch, dtype overflow, missing `train()` mode, broken input pipeline.
- Validation much worse than train: leakage-free split may reveal overfitting, distribution shift, augmentation mismatch, or regularization gap.
- NaNs: LR too high, fp16 overflow, invalid inputs, unstable loss, divide by zero, exploding gradients.
- Slow training: data loader bottleneck, small batch, CPU transforms, excessive logging, synchronization, unoptimized precision, network storage.
- Irreproducible results: unpinned data/env, nondeterministic kernels, random augmentations, distributed sampler differences, hidden preprocessing state.

## Sources

- PyTorch distributed and AMP documentation: https://pytorch.org/docs/stable/
- TensorFlow training and distribution guides: https://www.tensorflow.org/guide
- JAX and Flax documentation: https://jax.readthedocs.io/ and https://flax.readthedocs.io/
- Hugging Face Transformers, Accelerate, and PEFT docs: https://huggingface.co/docs
- scikit-learn model evaluation and pipeline docs: https://scikit-learn.org/stable/user_guide.html
