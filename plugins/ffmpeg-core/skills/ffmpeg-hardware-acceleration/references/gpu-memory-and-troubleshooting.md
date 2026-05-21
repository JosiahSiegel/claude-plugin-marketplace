# GPU Memory Management, Filter Comparison, Docker, and Troubleshooting

## GPU Memory Management

### Critical Concepts

PCIe transfers between CPU and GPU memory are the primary bottleneck. Keeping frames in GPU memory throughout the pipeline is critical for performance.

### Memory Flow Patterns

```text
Pattern 1: Full GPU Pipeline (OPTIMAL)
Input File -> GPU Decode -> GPU Filter -> GPU Encode -> Output File
                    |          |           |
                    v          v           v
                  [GPU Memory - No PCIe Transfer]

Pattern 2: CPU Filter Insertion (SUBOPTIMAL)
Input -> GPU Decode -> hwdownload -> CPU Filter -> hwupload -> GPU Encode -> Output
                           |                           |
                           v                           v
                     [PCIe Transfer]             [PCIe Transfer]

Pattern 3: Software Decode + GPU Encode
Input -> CPU Decode -> hwupload -> GPU Encode -> Output
                          |
                          v
                    [PCIe Transfer]
```

### Command Patterns Comparison

```bash
# OPTIMAL: full GPU pipeline - no CPU-GPU transfers
ffmpeg -y -vsync 0 \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf scale_cuda=1280:720 \
  -c:v h264_nvenc output.mp4

# SUBOPTIMAL: GPU decode, CPU filter, GPU encode - 2 transfers
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello',hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# AVOID: Missing -hwaccel_output_format -> frames copy to CPU after decode
ffmpeg -hwaccel cuda -i input.mp4 \
  -vf scale=1280:720 \
  -c:v h264_nvenc output.mp4
```

**Why `-hwaccel_output_format cuda` matters:** Without it, decoded frames transfer from GPU to CPU via PCIe, get processed, then transfer back to GPU for encoding. This can reduce throughput by up to 50%.

### Memory Monitoring

```bash
# NVIDIA memory and utilization
nvidia-smi dmon -s m

# Watch GPU utilization
watch -n 1 nvidia-smi

# Intel GPU
intel_gpu_top
```

### Best Practices

1. Use `-hwaccel_output_format` to keep decoded frames in GPU memory
2. Use GPU filters when available (scale_cuda, overlay_cuda, pad_cuda)
3. Batch similar operations to minimize filter graph complexity
4. Monitor GPU memory for high-resolution content
5. Use `-vsync 0` to prevent frame duplication overhead

---

## GPU Filter Comparison

### Cross-Platform Filter Availability

| Filter Type | CUDA | Vulkan | OpenCL | VAAPI | QSV |
|-------------|------|--------|--------|-------|-----|
| Scaling | `scale_cuda` | `scale_vulkan` | `scale_opencl` | `scale_vaapi` | `vpp_qsv` |
| Overlay | `overlay_cuda` | `overlay_vulkan` | `overlay_opencl` | - | - |
| Denoising | `bilateral_cuda` | `nlmeans_vulkan` | `nlmeans_opencl` | - | - |
| Deinterlace | `bwdif_cuda` | `bwdif_vulkan` | - | `deinterlace_vaapi` | `vpp_qsv` |
| Chromakey | `chromakey_cuda` | - | `colorkey_opencl` | - | - |
| Tonemapping | - | `libplacebo` | `tonemap_opencl` | `tonemap_vaapi` | - |
| Stabilization | - | - | `deshake_opencl` | - | - |
| Padding | `pad_cuda` | - | `pad_opencl` | - | - |

### Performance Comparison

| API | Platform Support | Filter Variety | Performance |
|-----|------------------|----------------|-------------|
| CUDA | NVIDIA only | Excellent | Best on NVIDIA |
| Vulkan | Cross-platform | Good (growing) | Very good |
| OpenCL | Cross-platform | Good | Good |
| VAAPI | Linux only | Limited | Good on Linux |
| QSV | Intel only | Limited | Good on Intel |

---

## Docker with Hardware Acceleration

### NVIDIA GPU in Docker

```bash
docker run --gpus all --rm \
  -v $(pwd):/data \
  jrottenberg/ffmpeg:nvidia \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i /data/input.mp4 \
  -c:v h264_nvenc /data/output.mp4
```

### Intel QSV in Docker

```bash
docker run --rm \
  --device=/dev/dri:/dev/dri \
  -v $(pwd):/data \
  jrottenberg/ffmpeg:vaapi \
  -hwaccel qsv -i /data/input.mp4 \
  -c:v h264_qsv /data/output.mp4
```

---

## Troubleshooting

### "No NVENC capable devices found"

```bash
nvidia-smi
nvidia-smi --query-gpu=driver_version --format=csv
nvcc --version
```

### "Cannot load libcuda.so"

```bash
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### QSV "Unsupported format"

```bash
ffmpeg -i input.mp4 -vf "format=nv12" -c:v h264_qsv output.mp4
```

### VAAPI permission denied

```bash
sudo usermod -aG video $USER
sudo usermod -aG render $USER
# Re-login or use newgrp
```

### Performance Debugging

```bash
# Benchmark encode speed
ffmpeg -benchmark -i input.mp4 -c:v h264_nvenc -f null -

# Hardware decode stats
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -benchmark -i input.mp4 -f null -

# NVIDIA monitoring
nvidia-smi dmon -s u

# Intel monitoring
intel_gpu_top
```

---

## Best Practices Recap

1. Use full GPU pipelines when possible to avoid CPU-GPU memory transfers
2. Match decode and encode hardware for best performance
3. Use appropriate presets - faster is not always better for quality
4. Enable lookahead and AQ for quality-critical encodes
5. Test on target hardware - quality varies by GPU generation
6. Monitor GPU memory for high-resolution content
7. Consider power efficiency for laptops and servers
8. Update drivers regularly for performance and feature improvements

## Recommended Settings by Use Case

### Live Streaming

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input \
  -c:v h264_nvenc -preset p3 -tune ll -zerolatency 1 -b:v 6M \
  -f flv rtmp://server/live/stream
```

### VOD (Quality)

```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p6 -tune hq \
  -rc vbr -cq 22 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 \
  output.mp4
```

### Batch Processing

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input1.mp4 -c:v h264_nvenc output1.mp4 &
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input2.mp4 -c:v h264_nvenc output2.mp4 &
wait
```
