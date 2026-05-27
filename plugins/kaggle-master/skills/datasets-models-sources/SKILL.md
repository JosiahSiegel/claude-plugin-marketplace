---
name: datasets-models-sources
description: |
  Kaggle datasets, models, sources, and kagglehub workflows. PROACTIVELY activate for: (1) downloading datasets with kagglehub, (2) uploading datasets, (3) downloading or uploading Kaggle models, (4) competition_download, (5) notebook_output_download, (6) choosing Kaggle CLI vs kagglehub, (7) attaching dataset_sources, competition_sources, kernel_sources, or model_sources, (8) model artifact transfer, (9) source dependency cleanup, (10) kagglehub limitations for notebooks. Provides: dataset/model transfer patterns, source attachment guidance, tool selection, and limitation checks.
---

# Datasets, Models, and Sources

## Overview

Use this skill for Kaggle datasets, models, source attachments, and kagglehub workflows. Separate transfer/download tasks from notebook lifecycle tasks: kagglehub is useful for data and model artifacts, but Kaggle CLI remains the notebook push/pull/status/delete tool.

## Tool Selection

| Need | Prefer |
|---|---|
| Create/edit/push/delete notebook | Kaggle CLI or Python API |
| Check notebook status/logs/files | Kaggle CLI or Python API |
| Download notebook outputs | Kaggle CLI or `kagglehub.notebook_output_download` |
| Download/load/upload datasets | kagglehub dataset functions or Kaggle CLI |
| Download/upload models | kagglehub model functions |
| Download competition data | kagglehub `competition_download` or Kaggle CLI |
| Manage metadata/source arrays | `kernel-metadata.json` plus Kaggle CLI push |

## kagglehub Capabilities

kagglehub supports `dataset_download`, `dataset_load`, `dataset_upload`, `model_download`, `model_upload`, `competition_download`, and `notebook_output_download`. It does not create, edit, push, delete, or administer Kaggle notebooks, and it does not manage `kernel-metadata.json` or notebook run status. Route those operations to `notebook-lifecycle` and `kernel-metadata`.

## Source Attachments

Use `dataset_sources`, `competition_sources`, `kernel_sources`, and `model_sources` in `kernel-metadata.json` for Kaggle-hosted notebook dependencies. Prefer explicit Kaggle resource identifiers and remove unused sources to reduce ambiguity, mount clutter, and rule-compliance risk.

## Dataset and Model Hygiene

- Confirm licenses and competition rules before using external datasets or pretrained models.
- Avoid uploading secrets, private labels, cached tokens, or unredacted logs as dataset/model artifacts.
- Version artifacts intentionally so notebook runs can be reproduced.
- Document expected mounted paths under `/kaggle/input` and output paths under `/kaggle/working`.
- Validate checksums or file counts for large downloads when reproducibility matters.

## Common Patterns

For competition notebooks, attach competition data through metadata and write submissions to `/kaggle/working`. For reusable training outputs, download notebook outputs or upload model artifacts with kagglehub after checking license/rule constraints. For local experimentation, use kagglehub downloads to populate local cache while keeping notebook code path-compatible with `/kaggle/input`.

## Safety and Limitations

Require confirmation before overwriting uploaded dataset/model versions or making private assets public. Do not claim kagglehub can push notebooks, change kernel metadata, inspect run logs, or delete kernels. Use Kaggle Secrets guidance for sensitive credentials rather than packaging them into datasets, models, or notebooks.

## Sources

- kagglehub repository: https://github.com/Kaggle/kagglehub
- Kaggle kernels CLI: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels.md
- Kaggle API docs: https://www.kaggle.com/docs/api
