---
name: ml-evaluation
description: |
  This skill should be used when the user asks to evaluate, validate, compare, explain, or debug model performance. PROACTIVELY activate for: (1) metrics selection for classification, regression, ranking, NLP, CV, recommender, forecasting, and generative AI, (2) train/validation/test splits, cross-validation, grouped or time-series validation, (3) confusion matrices, ROC/PR curves, calibration, thresholds, error analysis, (4) ablation studies, statistical significance, confidence intervals, bootstrap tests, (5) bias, fairness, explainability, robustness, leakage detection. Provides: rigorous evaluation methodology and production-readiness checks.
---

# ML Evaluation

## Overview

Use this skill for evaluating machine learning systems before, during, and after deployment. A valid evaluation answers: what decision will use the model, what data distribution matters, what failure costs exist, which metric encodes those costs, and whether the measured improvement is real rather than leakage, variance, or overfitting to validation.

## Evaluation Design Checklist

1. Define the unit of prediction and the unit of independence. Split by user, account, patient, device, document, session, or time when examples are correlated.
2. Establish baseline performance using a simple heuristic, prior model, or linear/tree baseline.
3. Pick metrics aligned to the decision, not just convenient defaults.
4. Freeze test data until final assessment; use validation data for tuning.
5. Evaluate slices: labels, geography, device, language, demographic groups when appropriate, data source, time period, and known hard cases.
6. Report uncertainty with confidence intervals or repeated CV when sample size is limited.
7. Perform qualitative error analysis before scaling model complexity.

## Split Strategies

Use random stratified splits only for iid data where examples are independent. Use grouped splits when multiple rows share an entity. Use time-based splits for forecasting, recommendation, fraud, logs, and any deployment where future data differs from past data. Use nested cross-validation when both hyperparameters and performance estimates must be unbiased. For small datasets, repeated stratified CV can reduce variance, but keep a final untouched test set when stakes are high.

### Comprehensive Data Leakage Prevention Checklist
*   **Split Before Fit**: Apply `scaler.fit()`, `imputer.fit()`, and encoder fits **only** on the training subset. Never fit on the entire dataset.
*   **Temporal Monotonicity**: Ensure that for time-series splits, the validation/test indices are chronologically strictly after the training indices.
*   **Grouped Isolations**: Verify that data points sharing common grouping factors (e.g., patient IDs, company IDs, session IDs) do not span both the training and testing sets.
*   **Target Leakage**: Check for columns representing events downstream of the prediction time (e.g., "refunded_date" in a churn model).
*   **No Pre-split Augmentation**: Apply minority class oversampling (e.g., SMOTE) or data augmentations **after** splitting. Oversampling before splitting places synthetic twins across the boundary.

## Metric Selection

| Task | Prefer | Watch for |
|---|---|---|
| Balanced classification | Accuracy, macro F1, log loss | Accuracy hides calibration and minority errors |
| Imbalanced classification | PR-AUC, recall at precision, F-beta, cost utility | ROC-AUC can look strong despite poor positive precision |
| Probabilistic classification | Log loss, Brier score, calibration curves | Threshold metrics ignore probability quality |
| Regression | MAE, RMSE, RMSLE, pinball loss, R2 | RMSE overweights outliers; MAPE fails near zero |
| Ranking/retrieval | NDCG, MAP, MRR, recall@k, precision@k | Offline negatives may not match production candidates |
| Forecasting | sMAPE, MASE, pinball loss, coverage | Random splits leak future patterns |
| Generation | Task-specific human/eval model rubrics plus automated checks | BLEU/ROUGE alone often miss usefulness and safety |
| Embeddings/RAG | Recall@k, MRR, answer faithfulness, groundedness, latency | Retrieval and generation failures must be separated |

For high-stakes decisions, evaluate operating thresholds with confusion matrices and cost curves. Optimize thresholds on validation, then report locked-threshold performance on test. Calibrate probabilities when decisions consume probabilities.

## Statistical Comparisons

Do not treat a simple metric difference as proof. Use paired comparisons when models are evaluated on the same examples.

### Bootstrap Confidence Intervals (Python Recipe)
```python
import numpy as np
from sklearn.metrics import f1_score

def bootstrap_metric_ci(
    y_true: np.ndarray, 
    y_pred: np.ndarray, 
    metric_fn = f1_score,
    n_bootstrap: int = 1000, 
    confidence_level: float = 0.95
):
    bootstrapped_scores = []
    rng = np.random.default_rng(seed=42)
    n_samples = len(y_true)
    
    for _ in range(n_bootstrap):
        # Sample with replacement
        indices = rng.choice(n_samples, size=n_samples, replace=True)
        score = metric_fn(y_true[indices], y_pred[indices])
        bootstrapped_scores.append(score)
        
    sorted_scores = np.sort(bootstrapped_scores)
    alpha = 1.0 - confidence_level
    lower_idx = int(np.floor(alpha / 2.0 * n_bootstrap))
    upper_idx = int(np.ceil((1.0 - alpha / 2.0) * n_bootstrap))
    
    return sorted_scores[lower_idx], sorted_scores[upper_idx]
```

### McNemar's Test for Comparing Paired Classifiers
McNemar's test assesses if two models disagree significantly.
```python
import numpy as np
from scipy.stats import chi2_contingency

def mcnemar_test(y_true: np.ndarray, pred_model_a: np.ndarray, pred_model_b: np.ndarray):
    # Contingency Table:
    #                 Model B Correct    Model B Incorrect
    # Model A Correct       n00                n01
    # Model A Incorrect     n10                n11
    
    correct_a = (pred_model_a == y_true)
    correct_b = (pred_model_b == y_true)
    
    n01 = np.sum(correct_a & ~correct_b) # A correct, B incorrect
    n10 = np.sum(~correct_a & correct_b) # A incorrect, B correct
    
    # Calculate chi-squared with continuity correction
    if n01 + n10 == 0:
        return 1.0 # Perfect agreement
        
    statistic = (abs(n01 - n10) - 1)**2 / (n01 + n10)
    # 1 degree of freedom
    from scipy.stats import chi2
    p_value = 1 - chi2.cdf(statistic, df=1)
    
    return p_value
```

### Temperature Scaling for Logits Calibration (PyTorch)
```python
import torch
import torch.nn as nn
import torch.optim as optim

class TemperatureScaler(nn.Module):
    def __init__(self):
        super().__init__()
        # Initial temperature parameter of 1.0 (no scaling)
        self.temperature = nn.Parameter(torch.ones(1))

    def forward(self, logits: torch.Tensor):
        return logits / self.temperature

    def fit(self, val_logits: torch.Tensor, val_labels: torch.Tensor, max_iter: int = 50):
        # Optimizes temperature parameter on validation set
        nll_criterion = nn.CrossEntropyLoss()
        optimizer = optim.LBFGS([self.temperature], lr=0.01, max_iter=max_iter)
        
        def eval_loss():
            optimizer.zero_grad()
            loss = nll_criterion(self.forward(val_logits), val_labels)
            loss.backward()
            return loss
            
        optimizer.step(eval_loss)
        return self.temperature.item()
```

## Error Analysis

Create a structured error taxonomy rather than scanning random failures. Segment false positives, false negatives, high-confidence errors, low-confidence correct cases, out-of-distribution examples, missing values, rare labels, long-tail entities, prompt categories, and latency/timeouts.

Error analysis should feed concrete remediation: collect data, relabel, change split, alter loss, add features, improve retrieval, calibrate threshold, simplify model, or adjust serving pipeline.

## Responsible AI and Robustness

Evaluate model behavior across relevant demographic, geographic, linguistic, accessibility, and operational slices. Choose fairness metrics that match the domain: demographic parity, equalized odds, equal opportunity, calibration by group, or counterfactual consistency. Explain trade-offs; fairness metrics can conflict. Use interpretable models or explainability tools when users need reasons, but validate explanations for stability and plausibility.

Test robustness to missing fields, schema changes, adversarial or noisy inputs, prompt injection for LLM/RAG systems, image corruptions, text typos, distribution shift, and low-resource slices. Do not deploy without a monitoring plan for data drift, performance drift, calibration drift, and safety incidents.

## Production Evaluation

Offline metrics are necessary but not sufficient. Before launch, run shadow evaluation, backtests, batch replay, or canaries where feasible. Compare training/serving preprocessing outputs on the same examples. Define rollback thresholds, alert destinations, retraining criteria, and owners. For A/B tests, include guardrail metrics such as latency, cost, user harm, fairness slices, business constraints, and support burden.

## Common Evaluation Failures

- Great validation, poor production: leakage, distribution shift, serving skew, threshold mismatch, or non-representative validation.
- Strong ROC-AUC, poor user value: wrong metric for imbalance or thresholded decision.
- Improving mean metric, harming key users: missing slice evaluation.
- Test set repeatedly reused: hidden overfitting to benchmark.
- LLM evaluation looks good but answers hallucinate: automated lexical metrics not measuring groundedness, citation quality, or refusal behavior.

## Sources

- scikit-learn model evaluation: https://scikit-learn.org/stable/modules/model_evaluation.html
- TensorFlow Model Analysis: https://www.tensorflow.org/tfx/model_analysis
- Google ML crash course evaluation guidance: https://developers.google.com/machine-learning/crash-course/classification
- Fairlearn documentation: https://fairlearn.org/
- Evidently AI ML monitoring and evaluation concepts: https://docs.evidentlyai.com/
