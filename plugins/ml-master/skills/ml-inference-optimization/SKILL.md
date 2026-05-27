---
name: ml-inference-optimization
description: |
  This skill should be used when the user asks to optimize, export, serve, compress, or accelerate ML inference. PROACTIVELY activate for: (1) latency, throughput, p95/p99, batching, concurrency, KV cache, memory, or cost issues, (2) quantization INT8/INT4, GPTQ, AWQ, bitsandbytes, pruning, sparsity, distillation, (3) ONNX export, ONNX Runtime, TensorRT, TorchScript, torch.compile, XLA, OpenVINO, Core ML, TFLite, (4) Triton, TorchServe, TF Serving, BentoML, Seldon, KServe configuration, (5) edge deployment, CPU/GPU/TPU/Inferentia serving. Provides: hardware-aware inference optimization and safe benchmarking.
---

# ML Inference Optimization

## Overview

Use this skill for reducing inference latency, increasing throughput, shrinking memory, lowering cost, and deploying optimized models safely. Optimization must be benchmark-driven: define workload, input shapes, concurrency, SLOs, hardware, runtime, numerical tolerance, and quality metrics before changing the model.

## Optimization Workflow

1. Establish a baseline with realistic data, preprocessing, postprocessing, network overhead, warmup, and concurrency.
2. Profile bottlenecks: CPU preprocessing, model compute, memory bandwidth, GPU utilization, serialization, queueing, retrieval, or downstream calls.
3. Apply the least risky optimization first: batching, compilation, precision, runtime tuning, then compression.
4. Revalidate accuracy, calibration, fairness slices, robustness, and numerical stability after every change.
5. Measure p50, p95, p99 latency, throughput, memory, cold start, error rate, and cost per 1,000 predictions.

## Export and Compilation

Export paths should be chosen by deployment target. Compare exported output with framework output on representative inputs. Define tolerances per output type. Include preprocessing and postprocessing in the benchmark; many failures occur outside the core model.

### PyTorch to ONNX Export Blueprint
```python
import torch
import torch.nn as nn

def export_to_onnx(model: nn.Module, dummy_input: torch.Tensor, onnx_path: str):
    model.eval()
    
    # Define input and output names, and dynamic axes for batch size and sequence length
    input_names = ["input_ids"]
    output_names = ["logits"]
    dynamic_axes = {
        "input_ids": {0: "batch_size", 1: "seq_len"},
        "logits": {0: "batch_size"}
    }
    
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=17, # Modern stable opset version
        do_constant_folding=True,
        input_names=input_names,
        output_names=output_names,
        dynamic_axes=dynamic_axes
    )
```

### PyTorch `torch.compile` Optimization Setup
`torch.compile` leverages the Inductor compiler for massive speedups on modern GPUs.
```python
import torch

def compile_model(model: torch.nn.Module, mode: str = "default"):
    # Modes:
    # - "default": Balance compile time and inference speed
    # - "reduce-overhead": Reduce framework overhead (uses CUDA graphs, good for small batch sizes)
    # - "max-autotune": Perform exhaustive kernel tuning (longest compile time, fastest runtime)
    
    optimized_model = torch.compile(
        model, 
        mode=mode, 
        fullgraph=False,
        dynamic=True # Handles variable sequence lengths/batch sizes efficiently
    )
    return optimized_model
```

## Batching and Concurrency

Dynamic batching is often the biggest serving win for GPU endpoints. Tune max batch size and queue delay together: larger batches improve throughput but can harm tail latency. For LLMs, distinguish prefill and decode phases; sequence length, KV cache, and concurrent requests dominate memory. Use continuous batching or specialized LLM serving runtimes when appropriate.

For CPU services, concurrency may improve utilization until memory bandwidth, GIL/runtime constraints, or thread oversubscription dominate. Pin thread counts for BLAS/OpenMP/ONNX Runtime and benchmark rather than accepting defaults.

## Triton Inference Server Configuration

Triton is the industry standard for high-performance multi-framework serving.

### Triton `config.pbtxt` Template
```protobuf
name: "text_classifier"
platform: "onnxruntime_onnx"
max_batch_size: 32

input [
  {
    name: "input_ids"
    data_type: TYPE_INT64
    dims: [ -1 ] # Dynamic sequence length
  }
]

output [
  {
    name: "logits"
    data_type: TYPE_FP32
    dims: [ 5 ] # Number of classes
  }
]

# Enable Dynamic Batching
dynamic_batching {
  max_queue_delay_microseconds: 5000 # Wait up to 5ms for concurrent requests
  preferred_batch_size: [ 8, 16, 32 ]
}

# GPU Instance Groups
instance_group [
  {
    count: 2 # Host 2 model execution instances per GPU
    kind: KIND_GPU
  }
]
```

## Precision and Quantization

| Method | Best for | Caveats |
|---|---|---|
| fp16/bf16 | GPU/accelerator throughput and memory reduction | Validate numerically sensitive ops |
| INT8 post-training quantization | CNNs, transformers, tabular neural nets with calibration data | Calibration set must represent production |
| Quantization-aware training | Accuracy-sensitive low precision deployments | Adds training complexity |
| INT4/GPTQ/AWQ/bitsandbytes | Large language model memory reduction | Can degrade reasoning, rare tokens, calibration, tool use |
| Weight-only quantization | LLM serving where activations remain higher precision | Speedup depends on kernels/hardware |

Quantization changes model behavior. Re-run task metrics, calibration, slice metrics, and safety checks. For RAG or embedding models, verify retrieval recall and embedding similarity distribution after quantization.

## Pruning, Sparsity, and Distillation

Pruning removes weights, channels, heads, or layers. Unstructured sparsity may not speed inference without hardware/runtime support; structured pruning is more likely to reduce latency. Knowledge distillation trains a smaller student to mimic a larger teacher.

## TensorRT Compilation Recipes (trtexec)

NVIDIA TensorRT compiled engines deliver maximum throughput on GPUs.

### 1. Build FP16 Engine with Dynamic Shapes
```bash
trtexec --onnx=model.onnx \
        --saveEngine=model.engine \
        --fp16 \
        --minShapes=input_ids:1x1 \
        --optShapes=input_ids:16x128 \
        --maxShapes=input_ids:32x512
```

### 2. Build INT8 Engine with Calibration Data
```bash
trtexec --onnx=model.onnx \
        --saveEngine=model_int8.engine \
        --int8 \
        --calib=calibration_profile.cache \
        --minShapes=input_ids:1x1 \
        --optShapes=input_ids:16x128 \
        --maxShapes=input_ids:32x512
```

## Serving Runtimes

| Runtime | Use when |
|---|---|
| Triton Inference Server | Multi-framework GPU/CPU serving, dynamic batching, ensembles, model repository, high throughput |
| TorchServe | PyTorch model serving with handlers and management APIs |
| TensorFlow Serving | TensorFlow SavedModel serving and versioned model management |
| ONNX Runtime Server/custom API | Portable ONNX inference with lightweight service control |
| BentoML | Packaging models as APIs, deployment flexibility, Python-centric workflows |
| Seldon/KServe | Kubernetes-native model serving, canaries, inference graphs, enterprise ops |
| vLLM / TGI | Continuous batching, PagedAttention, KV cache management, tensor parallel LLM serving |

Use model repository versioning and readiness checks. Separate health checks from expensive inference. For GPU serving, avoid loading multiple memory-heavy models per device unless capacity is proven.

## Memory Optimization

For transformers, memory is driven by weights plus KV cache. Reduce memory with quantization, tensor parallelism, smaller max sequence length, paged attention, cache eviction, smaller batch/concurrency, or distilled models. For diffusion and vision models, use attention slicing, VAE tiling, fp16/bf16, memory-efficient attention, and model offload where latency allows.

## Edge Deployment

Edge constraints include binary size, RAM, thermal throttling, offline operation, intermittent updates, privacy, and hardware acceleration. Prefer TFLite/Core ML/OpenVINO/ONNX depending on target. Test on real devices.

## Benchmarking Pitfalls

- Measuring only warm single-request latency while production has concurrent traffic.
- Ignoring tokenization, image decode, retrieval, serialization, or network time.
- Reporting average latency instead of p95/p99.
- Comparing quantized and baseline models on different data.
- Building TensorRT engines for one shape then serving unsupported dynamic shapes.
- Increasing batch size until throughput improves but SLO fails.

## Sources

- NVIDIA Triton Inference Server documentation: https://docs.nvidia.com/deeplearning/triton-inference-server/
- NVIDIA TensorRT documentation: https://docs.nvidia.com/deeplearning/tensorrt/
- ONNX Runtime documentation: https://onnxruntime.ai/docs/
- PyTorch export and compilation docs: https://pytorch.org/docs/stable/
- TensorFlow Lite documentation: https://www.tensorflow.org/lite
- BentoML documentation: https://docs.bentoml.com/
