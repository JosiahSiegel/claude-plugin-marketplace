---
name: competition-workflows
description: |
  Kaggle competition notebook workflows and submissions. PROACTIVELY activate for: (1) submitting notebook outputs to competitions, (2) `kaggle competitions submit -k`, (3) downloading competition data, (4) validating submission.csv format, (5) leakage review, (6) cross-validation split design, (7) public leaderboard overfitting concerns, (8) competition rule compliance, (9) reproducible top-to-bottom notebook execution, (10) fold-aware preprocessing for ML pipelines. Provides: submission commands, validation checklist, leakage controls, and competition-ready notebook guidance.
---

# Competition Workflows

## Overview

Use this skill for Kaggle competition workflows from data access through notebook execution and submission. Prioritize reproducibility, rule compliance, and leakage prevention over leaderboard-chasing shortcuts.

## Submission from Notebook Output

Use the notebook-kernel submission form when submitting an output file produced by a notebook version:

```bash
kaggle competitions submit <competition> -k <owner/slug> -f <file> -v <version> -m "<message>"
```

Before submission, confirm the notebook run completed successfully, the output file exists, and the version number matches the intended run. Use `notebook-lifecycle` for status, logs, files, and output download commands.

## Competition Data Access

Use Kaggle CLI or kagglehub for competition downloads. Attach competition sources in `kernel-metadata.json` when the notebook must run on Kaggle. Confirm users accepted competition rules before assuming downloads or submissions will work.

## Submission Validation Checklist

- Assert required columns, order, row count, and ID coverage.
- Check for nulls, infinities, invalid labels, and out-of-range predictions.
- Save outputs under `/kaggle/working` during Kaggle runs.
- Verify the submitted filename exactly matches the generated artifact.
- Include a concise submission message that identifies model/run changes without exposing secrets.

## Leakage and Validation Review

Use group/time/stratified splits that match the competition structure. Apply preprocessing inside folds to avoid fitting transforms on validation data. Avoid using public leaderboard feedback as a validation set; repeated leaderboard probing can overfit. Confirm external data, pretrained models, internet access, and ensemble sources comply with rules.

## Reproducibility Standards

Notebook should execute top-to-bottom from a clean Kaggle session. Set seeds for Python, NumPy, framework libraries, and splitters where applicable. Pin package versions when environment drift could affect results. Use a `DEBUG` flag to run small samples locally or during fast checks without changing final-run logic.

## Common Failure Modes

| Symptom | Check |
|---|---|
| Submission rejected | Filename, columns, rows, competition slug, accepted rules |
| Score impossible | Leakage, target contamination, ID mismatch, train/test merge mistake |
| Notebook output missing | Save location, run failure, timeout, file pattern |
| Local score diverges | Split mismatch, fold leakage, random seeds, preprocessing outside folds |

## Safety and Limits

Do not bypass competition rules or suggest hidden test reconstruction, private data scraping, or external data not allowed by rules. Warn before long GPU/TPU training runs. If secrets are needed, advise Kaggle Secrets through the UI; do not claim public API support for secrets administration.

## Sources

- Kaggle API docs: https://www.kaggle.com/docs/api
- Kaggle notebooks docs: https://www.kaggle.com/docs/notebooks
- Kaggle kernels CLI: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels.md
