---
name: notebook-lifecycle
description: |
  Kaggle notebook/kernel lifecycle operations. PROACTIVELY activate for: (1) creating Kaggle notebooks or kernels, (2) `kaggle kernels init`, (3) pushing or running notebooks with `kaggle kernels push`, (4) pulling notebooks with metadata, (5) checking kernel status, files, logs, or outputs, (6) downloading output artifacts with file patterns, (7) deleting kernels, (8) Python API kernel operations, (9) auth for notebook CLI workflows. Provides: safe CLI/Python lifecycle commands, run monitoring, output retrieval, destructive-action guardrails.
---

# Notebook Lifecycle

## Overview

Use this skill for local-to-Kaggle notebook administration: initialize, push, pull, run, inspect status/logs/files, download outputs, and delete kernels. Treat Kaggle Notebooks and Kaggle kernels as the same operational surface for CLI/API purposes.

## Quick Reference

| Task | Kaggle CLI |
|---|---|
| List kernels | `kaggle kernels list` |
| Initialize folder | `kaggle kernels init -p <folder>` |
| Push/update/run | `kaggle kernels push -p <folder> [-t <timeout>] [--accelerator <ID>]` |
| Pull source + metadata | `kaggle kernels pull <owner/slug> -p <folder> -m` |
| Status | `kaggle kernels status <owner/slug>` |
| Files | `kaggle kernels files <owner/slug>` |
| Outputs | `kaggle kernels output <owner/slug> -p <folder> -o [--file-pattern <REGEX>]` |
| Logs | `kaggle kernels logs <owner/slug>` |
| Delete | `kaggle kernels delete <owner/slug> --yes` |

## Authentication

Verify authentication before lifecycle commands. Supported public mechanisms include `kaggle auth login`, `KAGGLE_API_TOKEN`, `~/.kaggle/kaggle.json`, and `~/.kaggle/access_token`. Do not print token contents in responses or logs. When troubleshooting auth, check file presence and permissions without exposing secrets.

## Standard Workflow

1. Initialize or inspect the local folder.
2. Validate `kernel-metadata.json` before push; load `kernel-metadata` for schema repair.
3. Confirm source file referenced by `code_file` exists and matches `kernel_type`/`language`.
4. Choose a conservative timeout and accelerator. Warn before quota-consuming GPU/TPU runs.
5. Push with `kaggle kernels push -p <folder>` and optional `-t` or `--accelerator`.
6. Poll `kaggle kernels status <owner/slug>` until complete or failed.
7. Use `logs`, `files`, and `output` to diagnose or retrieve artifacts.

## Pull and Synchronization

Use `kaggle kernels pull <owner/slug> -p <folder> -m` when the user needs both source and metadata. Treat pulls into non-empty folders as overwrite-sensitive: ask before replacing local work, or advise using a fresh folder. After pulling, compare metadata and code before pushing changes back.

## Output Retrieval

Use `kaggle kernels output <owner/slug> -p <folder> -o` to download all outputs. Add `--file-pattern <REGEX>` to limit large output sets, for example submission files or model artifacts. Verify expected files exist before competition submission.

For long-running service or tunnel notebooks, do not rely only on logs for externally needed connection details. Logs may be blank during keepalive cells. Write discovered values such as a public tunnel URL to `/kaggle/working/ollama_base_url.txt`, then retrieve them with:

```bash
kaggle kernels output <owner>/<kernel-slug> -p ./outputs -o --file-pattern "ollama_base_url.txt"
```

## Deriving a Notebook Browser URL After Push

After a successful `kaggle kernels push`, the Kaggle CLI does not provide a documented, stable contract that stdout includes a notebook URL. For e2e administration, derive the browser URL from `kernel-metadata.json` when its `id` field uses the documented identifier format `owner/kernel-slug`:

```text
https://www.kaggle.com/code/<owner>/<kernel-slug>
```

Before the first successful push, call this the expected URL. After a successful push and status check, call it the notebook URL:

```bash
kaggle kernels push -p <notebook-folder>
kaggle kernels status <owner/kernel-slug>
```

Do not rely on parsing `kaggle kernels push` output for a URL; CLI text may change. Do not rely on undocumented CSV columns from list commands for URL construction. Private notebooks may require sign-in or appropriate permissions, and slug changes after renames can make older derived URLs stale.

## Python API Equivalents

Use `KaggleApi().authenticate()` before API calls. Relevant methods include `kernels_push`, `kernels_status`, `kernels_pull`, `kernels_output`, `kernels_list`, `kernels_logs`, and `kernels_delete`. Prefer CLI examples for users unless they explicitly ask for Python automation.

## Safety Gates

Require explicit confirmation before `kaggle kernels delete <owner/slug> --yes`; deletion is permanent. Also require confirmation before public visibility changes, overwriting local folders, pushing code that may contain secrets, or long accelerator-backed runs. If secrets appear in notebook source or metadata, stop and recommend moving them to Kaggle Secrets rather than pushing.

## Public API Limitations

Do not claim public API support for notebook scheduling, secrets management, collaborator administration, cell-level editing of hosted notebooks, Docker image selection, or quota management. Suggest Kaggle UI workflows only when appropriate.

## Sources

- Kaggle kernels CLI: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels.md
- Kaggle notebooks docs: https://www.kaggle.com/docs/notebooks
- Kaggle API docs: https://www.kaggle.com/docs/api
