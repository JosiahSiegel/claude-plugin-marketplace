---
name: kaggle-environment
description: |
  Kaggle runtime environment, paths, accelerators, and reproducibility. PROACTIVELY activate for: (1) `/kaggle/input` path errors, (2) `/kaggle/working` output placement, (3) local vs Kaggle notebook behavior, (4) GPU/TPU/accelerator selection, (5) internet enablement, (6) package/version pinning, (7) memory cleanup and timeout issues, (8) DEBUG flags for fast runs, (9) Kaggle Secrets usage guidance, (10) quota-consuming runtime settings. Provides: path conventions, runtime checklist, accelerator IDs, reproducibility patterns, and resource safeguards.
---

# Kaggle Environment

## Overview

Use this skill for Kaggle hosted runtime behavior: filesystem paths, accelerators, internet access, dependency drift, output locations, reproducibility, and resource limits. Distinguish local development assumptions from Kaggle execution assumptions.

## Path Conventions

| Path | Use |
|---|---|
| `/kaggle/input` | Read-only mounted datasets, competition data, models, and notebook sources |
| `/kaggle/working` | Writable working directory; save submissions and artifacts here |
| Local project folder | Source and metadata folder used by CLI push/pull |

Never write final outputs only under `/kaggle/input`; it is read-only. For submissions or artifacts, write to `/kaggle/working/<file>` and verify the file appears in notebook outputs.

## Accelerator IDs

`kaggle kernels push -p <folder> --accelerator <ID>` can request accelerators. Valid IDs include `NvidiaTeslaP100`, `NvidiaTeslaT4`, `NvidiaTeslaT4Highmem`, `NvidiaTeslaA100`, `NvidiaL4`, `NvidiaL4X1`, `NvidiaH100`, `NvidiaRtxPro6000`, `TpuV38`, `Tpu1VmV38`, `TpuV5E8`, and `TpuV6E8`. Choose the smallest appropriate accelerator first, and warn that high-end GPUs/TPUs plus long timeouts can consume quotas.

## Runtime Checklist

- Set seeds for the language runtime, libraries, and splitters.
- Keep a `DEBUG` flag for small samples and short epochs.
- Pin versions for dependencies that affect results.
- Assert input paths exist before long training starts.
- Save checkpoints, submissions, and logs to `/kaggle/working`.
- Clean memory between folds or model stages when using large arrays or GPU tensors.
- Disable internet for competition final runs unless allowed and necessary.

## Internet and Secrets

`enable_internet` defaults to `false` in metadata. Enable only when the workflow and competition rules allow it. For sensitive values, advise Kaggle Secrets through the Kaggle UI. Do not embed tokens in notebooks, metadata, command history, or uploaded artifacts. Do not claim public API support for secrets administration.

### CLI-Pushed Committed Runs

Do not assume `UserSecretsClient().get_secret()` works in Kaggle CLI-pushed committed or batch runs. It can return HTTP 400 even when the secret exists and is attached in the Kaggle UI. `kernel-metadata.json` has no supported `secrets`, `environment`, or environment-variable field; do not invent one.

When a workflow can avoid secrets, prefer a zero-auth design. For temporary public tunnels from Kaggle, Cloudflare TryCloudflare quick tunnels avoid ngrok tokens:

```bash
cloudflared tunnel --url http://127.0.0.1:11434
```

Validate services from inside Kaggle against localhost, not the public tunnel hostname. Cloudflare tunnel hostnames may not resolve from Kaggle's network:

```bash
curl -fsS http://127.0.0.1:11434
```

Write discovered public URLs to `/kaggle/working/<name>.txt` so external tooling can retrieve them with `kaggle kernels output` even when `kaggle kernels logs` is blank during keepalive cells.

## Apt Reliability

Kaggle base images may include third-party PPA sources that intermittently fail DNS resolution and break `apt-get update`. Before installing packages, consider disabling PPA source files and using retries with short timeouts:

```bash
sudo mkdir -p /etc/apt/sources.list.d/disabled
sudo find /etc/apt/sources.list.d -type f -name "*.list" -print -exec sudo mv {} /etc/apt/sources.list.d/disabled/ \;
sudo apt-get update \
  -o Acquire::Retries=5 \
  -o Acquire::http::Timeout=20 \
  -o Acquire::https::Timeout=20
```

Keep package installation minimal because notebook startup networking can be intermittent.

## Local vs Kaggle Differences

When code works locally but fails on Kaggle, check mounted source names, case sensitivity, missing package versions, write paths, internet availability, accelerator availability, and memory. Add path-detection wrappers only when they keep execution deterministic; avoid hidden environment-specific branches that alter modeling logic.

## Unsupported Public API Areas

Do not claim public API support for Docker image selection, quota management, scheduler administration, collaborator administration, or cell-level editing. Provide UI-based caveats when those tasks are outside public CLI/API scope.

## Sources

- Kaggle notebooks docs: https://www.kaggle.com/docs/notebooks
- Kaggle kernels CLI: https://github.com/Kaggle/kaggle-api/blob/main/docs/kernels.md
