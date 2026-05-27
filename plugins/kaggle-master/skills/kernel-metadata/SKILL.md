---
name: kernel-metadata
description: |
  Kaggle `kernel-metadata.json` setup and repair. PROACTIVELY activate for: (1) creating kernel-metadata.json, (2) fixing metadata validation errors, (3) setting `id`, `title`, `code_file`, language, or kernel type, (4) configuring private/public, internet, GPU, or accelerator behavior, (5) attaching dataset_sources, competition_sources, kernel_sources, or model_sources, (6) preparing metadata before `kaggle kernels push`, (7) converting script/notebook metadata. Provides: schema checklist, valid fields, source arrays, defaults, and push-readiness review.
---

# Kernel Metadata

## Overview

Use this skill to create, validate, or repair `kernel-metadata.json` for Kaggle notebook/kernel pushes. Keep metadata minimal, explicit, and aligned with the local code file.

## Required and Common Fields

| Field | Purpose |
|---|---|
| `id` | Full kernel id, usually `<owner>/<slug>` |
| `id_no` | Numeric id when available |
| `title` | Human-readable notebook title |
| `code_file` | Local source file to run |
| `language` | `python`, `r`, or `rmarkdown` |
| `kernel_type` | `script` or `notebook` |
| `is_private` | Defaults to `true` |
| `enable_gpu` | Defaults to `false` |
| `enable_internet` | Defaults to `false` |
| `dataset_sources` | Attached dataset references |
| `competition_sources` | Attached competition references |
| `kernel_sources` | Attached notebook/kernel references |
| `model_sources` | Attached model references |

## Validation Procedure

1. Confirm `kernel-metadata.json` is valid JSON.
2. Confirm `id` uses the expected owner/slug and matches the intended Kaggle notebook.
3. Confirm `code_file` exists in the same folder passed to `kaggle kernels push -p <folder>`.
4. Confirm `language` is one of `python`, `r`, or `rmarkdown`.
5. Confirm `kernel_type` matches the file and execution mode: `notebook` for `.ipynb`, `script` for scripts.
6. Confirm privacy and internet settings are deliberate. Default private and no internet are safer.
7. Confirm source arrays contain valid public Kaggle references and no local filesystem paths.
8. Load `notebook-lifecycle` before push or pull workflows.

## Source Attachments

Use `dataset_sources`, `competition_sources`, `kernel_sources`, and `model_sources` to attach Kaggle resources. Prefer exact owner/slug references where available. For competition notebooks, ensure the competition source is attached and rules allow all data/model sources used.

## `id` and Browser URL Construction

The `id` field identifies the Kaggle notebook/kernel using the documented suffix format `owner/kernel-slug`. When `id` is present and valid, agents may derive the human browser URL:

```text
https://www.kaggle.com/code/<owner>/<kernel-slug>
```

Validate before deriving: `id` contains exactly one `/`, both owner and slug are non-empty, `id` is not a full URL, and the slug comes from the actual `id` rather than a generated title guess. If `id_no` is also present, treat it as a stable numeric identifier for API operations where supported, but do not use `id_no` alone to construct the browser URL.

The derived URL is a practical browser path based on the documented identifier suffix, not a separately documented CLI return value. Private notebooks may require sign-in or permissions, and renames or slug changes can make older derived URLs stale.

## Accelerators and Metadata

`enable_gpu` is a legacy/simple boolean for GPU enablement, while CLI push can specify accelerator IDs with `--accelerator <ID>`. Valid accelerator IDs include `NvidiaTeslaP100`, `NvidiaTeslaT4`, `NvidiaTeslaT4Highmem`, `NvidiaTeslaA100`, `NvidiaL4`, `NvidiaL4X1`, `NvidiaH100`, `NvidiaRtxPro6000`, `TpuV38`, `Tpu1VmV38`, `TpuV5E8`, and `TpuV6E8`. Warn before high-end accelerators or long timeouts because they can consume quotas.

## Safe Defaults

Keep `is_private: true` unless the user explicitly requests public visibility. Keep `enable_internet: false` for competition notebooks unless rules and reproducibility needs allow internet. Avoid embedding secrets in metadata or notebook source; recommend Kaggle Secrets for sensitive values.

## Unsupported Metadata Fields

Kaggle `kernel-metadata.json` does not support secrets or arbitrary environment variables. Do not add fake fields such as `secrets`, `environment`, or `env`. For internet/GPU tunnel workloads, verify supported fields instead:

```json
{
  "enable_gpu": true,
  "enable_internet": true
}
```

Secrets must not be modeled as metadata. If a CLI-pushed committed run needs auth-free connectivity, redesign the workflow to avoid secrets.

## Repair Patterns

- Missing `code_file`: identify the intended `.ipynb`, `.py`, `.R`, or `.Rmd` file and set the field explicitly.
- Wrong language: infer from extension only after confirming with the user when ambiguous.
- Broken source arrays: remove local paths and replace with Kaggle dataset, competition, kernel, or model references.
- Visibility changes: require explicit confirmation before changing private to public.

## Sources

- Kaggle kernel metadata docs: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels_metadata.md
- Kaggle kernels CLI: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels.md
