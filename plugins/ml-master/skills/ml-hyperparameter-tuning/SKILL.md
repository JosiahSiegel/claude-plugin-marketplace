---
name: ml-hyperparameter-tuning
description: |
  This skill should be used when the user asks to tune hyperparameters, run sweeps, optimize search spaces, or use AutoML. PROACTIVELY activate for: (1) Optuna, Ray Tune, FLAML, AutoGluon, Hyperopt, Nevergrad, KerasTuner, W&B sweeps, (2) grid search, random search, Bayesian optimization, TPE, Gaussian processes, evolutionary search, (3) ASHA, Hyperband, successive halving, multi-fidelity optimization, population-based training, (4) learning-rate finder, batch-size search, early stopping, pruning, (5) reproducible sweep design and experiment analysis. Provides: budget-aware hyperparameter search strategy.
---

# ML Hyperparameter Tuning

## Overview

Use this skill for designing and running hyperparameter searches. Tuning should improve a valid baseline under a fixed evaluation protocol. Do not tune before data validation, leakage-safe splits, metric selection, reproducible training, and a simple baseline are in place.

## Search Strategy Selection

| Strategy | Use when | Notes |
|---|---|---|
| Manual informed search | Early debugging or very small budgets | Best when guided by learning curves and domain knowledge |
| Grid search | Few categorical/discrete parameters | Wasteful in high dimensions |
| Random search | Strong default for broad spaces | Often beats grid when only some parameters matter |
| Bayesian/TPE | Moderate budgets and expensive trials | Good for structured continuous/discrete spaces |
| Hyperband/ASHA | Many deep-learning trials with early signal | Requires comparable learning curves and sensible early-stopping metric |
| Population-based training | Schedules and nonstationary hyperparameters | More complex; useful for RL and large training budgets |
| AutoML | Need strong baseline or tabular productivity | Validate leakage, explainability, and deployment constraints |

Optuna is a flexible default for Python search. Ray Tune is strong for distributed sweeps, schedulers, and Ray Train integration. FLAML emphasizes cost-effective AutoML. AutoGluon is productive for tabular, multimodal, and time-series baselines. W&B sweeps integrate well with experiment tracking.

## Optuna Objective with Pruning (Python Blueprint)

Optuna allows pruning unpromising trials early in the training loop based on intermediate validation scores.

```python
import optuna
import torch
import torch.nn as nn
import torch.optim as optim

def train_and_validate(config, trial, model, train_loader, val_loader, device):
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=config["lr"])
    
    for epoch in range(10): # 10 Epochs max
        model.train()
        for inputs, targets in train_loader:
            inputs, targets = inputs.to(device), targets.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()
            
        # Validation epoch
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, targets in val_loader:
                inputs, targets = inputs.to(device), targets.to(device)
                outputs = model(inputs)
                val_loss += criterion(outputs, targets).item()
        val_loss /= len(val_loader)
        
        # Report intermediate value to Optuna for pruning check
        trial.report(val_loss, epoch)
        
        # Handle pruning (stop execution of this trial if criteria are met)
        if trial.should_prune():
            raise optuna.exceptions.TrialPruned()
            
    return val_loss

def objective(trial: optuna.Trial, model_class, train_loader, val_loader, device):
    # Search Space Configuration
    config = {
        "lr": trial.suggest_float("lr", 1e-5, 1e-2, log=True),
        "optimizer": trial.suggest_categorical("optimizer", ["Adam", "SGD", "RMSprop"]),
        "batch_size": trial.suggest_categorical("batch_size", [16, 32, 64]),
        "dropout_rate": trial.suggest_float("dropout_rate", 0.1, 0.5)
    }
    
    model = model_class(dropout_rate=config["dropout_rate"]).to(device)
    return train_and_validate(config, trial, model, train_loader, val_loader, device)

# Running the study
# study = optuna.create_study(direction="minimize", pruner=optuna.pruners.MedianPruner())
# study.optimize(lambda t: objective(t, MyModel, train_loader, val_loader, device), n_trials=50)
```

## Search Space Design

Use distributions that reflect scale. Learning rate, weight decay, regularization strength, and tree min child weights usually need log-uniform or categorical log grids. Depth, layers, hidden sizes, batch size, and number of estimators are discrete. Optimizer, scheduler, augmentation policy, model family, and feature set are categorical.

Avoid searching invalid combinations. Encode conditional spaces: `max_depth` only for tree models, LoRA rank only for PEFT, warmup ratio only for scheduled optimizers. Keep the first search broad and shallow; narrow around promising regions.

## Weights & Biases (W&B) Sweep YAML Blueprint (`sweep.yaml`)
W&B Sweeps run hyperparameter searches across multiple distributed agents.
```yaml
program: train.py
method: bayes # Search algorithm: bayes, random, grid
metric:
  name: val_loss
  goal: minimize
parameters:
  learning_rate:
    distribution: log_uniform_values
    min: 1e-5
    max: 1e-2
  batch_size:
    values: [16, 32, 64]
  epochs:
    value: 20
  dropout:
    distribution: uniform
    min: 0.1
    max: 0.5
  optimizer:
    values: ["adam", "adamw", "sgd"]
early_terminate:
  type: hyperband
  min_iter: 3
  eta: 2
```

## Ray Tune Distributed Sweeps with ASHA Scheduler

Ray Tune easily distributes sweeps across a cluster, managing hyperparameter tuning at scale.

```python
from ray import tune
from ray.tune.schedulers import ASHAScheduler

def train_fn(config):
    # Training routine pulling from config e.g., config["lr"]
    for epoch in range(100):
        # ... training step ...
        val_loss = run_validation()
        # Report intermediate score back to Ray
        tune.report(loss=val_loss, epoch=epoch)

# Define Async Successive Halving (ASHA) scheduler
asha_scheduler = ASHAScheduler(
    time_attr="epoch",
    metric="loss",
    mode="min",
    max_t=100,
    grace_period=5,
    reduction_factor=2
)

# Run distributed sweep
# analysis = tune.run(
#     train_fn,
#     resources_per_trial={"cpu": 2, "gpu": 0.5}, # Run two trials per GPU
#     config={
#         "lr": tune.loguniform(1e-5, 1e-2),
#         "batch_size": tune.choice([16, 32, 64])
#     },
#     num_samples=30,
#     scheduler=asha_scheduler
# )
```

## Parameters Worth Tuning

Deep learning:
- Learning rate, warmup, scheduler, optimizer, weight decay.
- Batch size or effective batch size, gradient accumulation.
- Dropout, label smoothing, augmentation strength.
- Architecture width/depth, sequence length, image resolution.
- Loss parameters, class weights, focal loss gamma.
- PEFT rank/alpha/dropout and target modules for fine-tuning.

Tree/tabular models:
- Learning rate, number of estimators/iterations, max depth/leaves.
- Subsample, column sample, min child samples/weight.
- L1/L2 regularization, min split gain.
- Categorical handling and monotonic constraints where supported.

RAG and embedding systems:
- Chunk size/overlap, embedding model, top-k, hybrid weights, reranker, prompt template, context budget, score thresholds.

## Early Stopping and Pruning

Early stopping prevents wasted compute but can bias toward fast-starting configurations. Use patience and minimum resource thresholds. ASHA and Hyperband need a monotonically meaningful metric and comparable training curves. For noisy metrics, smooth or require multiple evaluations. Always run promising configurations to full budget before final selection.

## Learning-Rate Finder

A learning-rate range test can quickly find a useful LR interval for neural networks. Increase LR over a short run, plot loss, choose a value below divergence and often below the steepest descent point. Re-run proper training afterward; LR finder output is a guide, not a final experiment.

## Reproducibility

Log every trial's parameters, random seed, code version, data version, hardware, dependencies, metric, artifacts, and failure reason. Use deterministic trial IDs. Save top-k configs, not only the best. For distributed sweeps, make sure failed or preempted trials are marked correctly and that resumed trials do not duplicate results.

## Analyzing Results

After a sweep, inspect parameter importance, parallel coordinate plots, metric distributions, and learning curves. Look for unstable regions, overfitting to validation, invalid trials, and interactions. Confirm the winning configuration on an untouched test set or repeated seeds. If the improvement is within noise, prefer the simpler or cheaper model.

## Common Tuning Mistakes

- Tuning on the test set or public leaderboard.
- Searching too many parameters with too few trials.
- Using linear sampling for log-scale parameters.
- Ignoring failed trials that indicate unstable regions.
- Letting AutoML leak target-derived features through preprocessing.
- Selecting best validation score without retraining or test confirmation.
- Comparing trials with different data snapshots or preprocessing code.

## Sources

- Optuna documentation: https://optuna.readthedocs.io/
- Ray Tune documentation: https://docs.ray.io/en/latest/tune/
- FLAML documentation: https://microsoft.github.io/FLAML/
- AutoGluon documentation: https://auto.gluon.ai/
- scikit-learn hyperparameter tuning docs: https://scikit-learn.org/stable/modules/grid_search.html
- W&B Sweeps documentation: https://docs.wandb.ai/guides/sweeps/
