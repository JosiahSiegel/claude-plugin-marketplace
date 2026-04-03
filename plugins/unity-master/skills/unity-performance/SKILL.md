---
name: unity-performance
description: |
  This skill should be used when the user asks about "Unity performance",
  "slow game", "stuttering", "frame rate drop", "FPS drop",
  "Unity Profiler", "Frame Debugger", "draw calls", "batching",
  "object pooling", "garbage collection", "GC spike", "memory leak",
  "LOD", "occlusion culling", "texture compression", "build size",
  "mobile optimization", "WebGL performance", "ECS performance",
  "DOTS optimization", "Burst Compiler", "Jobs system performance",
  "Addressables memory", "asset loading", "scene loading optimization",
  "GPU instancing", "SRP Batcher", "lightmap baking time",
  or needs help profiling and optimizing Unity games.
---

# Unity Performance Optimization

## Overview

Systematic approach to profiling and optimizing Unity games. Covers profiling tools, CPU/GPU optimization, memory management, rendering optimization, and platform-specific considerations.

## Profiling Tools

| Tool | What It Shows | When to Use |
|------|--------------|-------------|
| **Unity Profiler** | CPU, GPU, memory, audio, physics per frame | First stop for any perf issue |
| **Frame Debugger** | Draw call breakdown, shader/material state | Rendering bottlenecks |
| **Memory Profiler** | Heap snapshots, texture/mesh memory | Memory leaks, bloat |
| **Profile Analyzer** | Compare captures, statistical analysis | Before/after optimization |
| **Physics Debugger** | Collider visualization, contact points | Physics performance |

### Profiler Workflow

1. Build with Development Build + Autoconnect Profiler enabled
2. Profile on target device (not in Editor -- Editor overhead distorts results)
3. Identify the bottleneck category: CPU-bound, GPU-bound, or memory pressure
4. Drill into the specific system causing the issue
5. Optimize, re-profile, and compare

### Reading the Profiler

```
If frame time > 16.6ms (60 FPS target):
  CPU timeline > GPU timeline -> CPU-bound
  GPU timeline > CPU timeline -> GPU-bound
  GC.Alloc column shows per-frame allocations -> GC pressure
```

Look for spikes (single bad frames) vs. sustained high times (baseline too heavy).

## CPU Optimization

### Reduce Per-Frame Allocations (GC)

| Anti-Pattern | Fix |
|-------------|-----|
| `string + string` in Update | Use `StringBuilder` or cache |
| `new List<T>()` every frame | Allocate once, `Clear()` and reuse |
| LINQ in hot paths | Replace with manual loops |
| `GetComponent<T>()` per frame | Cache in Awake/Start |
| `GameObject.Find()` per frame | Cache reference or use events |
| `foreach` on non-generic collections | Use `for` loop or generic collections |
| `SendMessage()` / `BroadcastMessage()` | Use direct calls, events, or interfaces |
| Boxing value types | Use generic collections, avoid `object` casts |

### Object Pooling

```csharp
public class ObjectPool<T> where T : Component
{
    readonly Queue<T> _pool = new();
    readonly T _prefab;
    readonly Transform _parent;

    public ObjectPool(T prefab, int preWarm, Transform parent = null)
    {
        _prefab = prefab;
        _parent = parent;
        for (int i = 0; i < preWarm; i++)
            _pool.Enqueue(CreateInstance());
    }

    public T Get(Vector3 position, Quaternion rotation)
    {
        var obj = _pool.Count > 0 ? _pool.Dequeue() : CreateInstance();
        obj.transform.SetPositionAndRotation(position, rotation);
        obj.gameObject.SetActive(true);
        return obj;
    }

    public void Return(T obj)
    {
        obj.gameObject.SetActive(false);
        _pool.Enqueue(obj);
    }

    T CreateInstance()
    {
        var obj = Object.Instantiate(_prefab, _parent);
        obj.gameObject.SetActive(false);
        return obj;
    }
}
```

Pool bullets, particles, enemies, UI elements -- anything instantiated/destroyed frequently. Unity 2021+ also has `UnityEngine.Pool.ObjectPool<T>` built-in.

### Update Optimization

| Technique | Description |
|-----------|-------------|
| Stagger updates | Don't update all AI every frame; use tick groups |
| Distance-based LOD | Reduce update frequency for distant objects |
| Event-driven | Replace polling with events where possible |
| Disable unused scripts | `enabled = false` on off-screen components |
| Use `InvokeRepeating` | For periodic checks (cheaper than coroutine yielding) |

## GPU / Rendering Optimization

### Draw Call Reduction

| Technique | How | Savings |
|-----------|-----|---------|
| **Static Batching** | Mark non-moving objects as Static | Combines meshes at build time |
| **Dynamic Batching** | Automatic for small meshes (<300 verts) | URP/Built-in only |
| **GPU Instancing** | Enable on materials for repeated objects | Trees, grass, rocks |
| **SRP Batcher** | Enabled by default in URP/HDRP | Reduces SetPass calls |
| **Texture Atlasing** | Combine textures into atlas | Fewer material switches |
| **Mesh Combining** | `CombineMeshes()` at runtime | Custom batching |

### LOD (Level of Detail)

```
LOD Group Setup:
  LOD 0 (0-30%):  Full-detail mesh (5000 tris)
  LOD 1 (30-60%): Medium mesh (2000 tris)
  LOD 2 (60-90%): Low mesh (500 tris)
  Culled (90%+):  Not rendered
```

Use LOD for meshes, but also reduce script complexity, particle counts, and physics at distance.

### Occlusion Culling

Bake occlusion data for indoor/complex scenes. Mark large static occluders (walls, floors). Configure cell size based on scene scale. Use the Occlusion Culling window to visualize and test.

### Shader Optimization

| Issue | Solution |
|-------|----------|
| Complex fragment shaders | Reduce texture samples, simplify math |
| Overdraw | Minimize transparent objects, use opaque when possible |
| Too many variants | Strip unused shader variants in build settings |
| Expensive post-processing | Disable effects on mobile, use cheaper alternatives |

## Memory Management

### Common Memory Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Texture bloat | High memory, long loads | Compress textures, reduce max size per platform |
| Unloaded scenes holding refs | Memory climbs over time | Use `Resources.UnloadUnusedAssets()` after scene transitions |
| Addressables not released | Bundles stay in memory | Call `Addressables.Release(handle)` |
| Audio clips uncompressed | Huge memory footprint | Use compressed in memory for music, decompress on load for SFX |
| Mesh read/write enabled | Double memory per mesh | Disable Read/Write if not needed at runtime |

### Texture Compression Per Platform

| Platform | Format | Notes |
|----------|--------|-------|
| PC/Console | BC7 (DXT) | Best quality/size ratio |
| Android | ASTC 6x6 | Universal, scalable quality |
| iOS | ASTC 6x6 | Same as Android |
| WebGL | ETC2 / DXT | Depends on target GPU |

Use "Override for [Platform]" in texture import settings. Set max texture size to the minimum needed (512 for UI icons, 1024 for props, 2048 for hero assets).

## Platform-Specific Considerations

| Platform | Key Constraints |
|----------|----------------|
| **Mobile** | Thermal throttling, limited memory, battery drain, fill-rate limited |
| **WebGL** | No threads (pre-Unity 6), large download size, no compute shaders |
| **Console** | Certification requirements, fixed hardware, memory budgets |
| **VR/XR** | 72-90 FPS minimum, stereo rendering cost, motion sickness from drops |

## Addressables and Asset Loading

Use Addressables for async asset loading to avoid load-time hitches:

```csharp
// Preload during loading screen
var handle = Addressables.LoadAssetAsync<GameObject>("enemy_boss");
await handle;

// Release when done
Addressables.Release(handle);
```

Use Addressable groups to control bundle granularity. Mark infrequently used assets as remote/on-demand. Profile bundle memory with the Addressables Event Viewer.

## Quick Optimization Checklist

- [ ] Profile on target device, not in Editor
- [ ] Zero per-frame GC allocations in gameplay code
- [ ] Object pooling for all frequently spawned objects
- [ ] Static batching enabled for non-moving objects
- [ ] LOD groups on all 3D models visible at varying distances
- [ ] Textures compressed per platform with appropriate max sizes
- [ ] Disable Read/Write on meshes and textures not modified at runtime
- [ ] Audio clips use appropriate compression settings
- [ ] Occlusion culling baked for indoor/complex scenes
- [ ] Shader variants stripped in build settings

## Additional Resources

### Reference Files
- **`references/profiling-deep-dive.md`** -- Advanced Profiler usage, memory profiler snapshots, frame-by-frame analysis, custom profiler markers, automated performance testing, build size analysis, ECS/DOTS performance patterns
