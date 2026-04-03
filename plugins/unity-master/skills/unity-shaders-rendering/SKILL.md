---
name: unity-shaders-rendering
description: |
  This skill should be used when the user asks about "shader", "Shader Graph",
  "HLSL", "ShaderLab", "custom shader", "material", "URP shader",
  "HDRP shader", "Built-in shader", "render pipeline", "URP", "HDRP",
  "Scriptable Render Pipeline", "SRP", "lighting", "baked lighting",
  "realtime lighting", "lightmap", "Global Illumination", "GI",
  "reflection probe", "light probe", "VFX Graph", "particle system",
  "visual effect", "post-processing", "bloom", "SSAO", "fog",
  "dissolve effect", "outline shader", "toon shading", "water shader",
  "transparency", "render feature", "render pass",
  or needs help with rendering, visual effects, or shader development in Unity.
---

# Unity Shaders and Rendering

## Overview

Reference for Unity's rendering systems, shader development, lighting configuration, and visual effects. Covers all three render pipelines, Shader Graph, hand-written shaders, and VFX Graph.

## Render Pipeline Comparison

| Feature | Built-in RP | URP | HDRP |
|---------|------------|-----|------|
| Target | Legacy projects | Mobile, VR, wide range | High-end PC/console |
| Shader language | Surface shaders + HLSL | HLSL (no surface shaders) | HLSL |
| Shader Graph | Yes | Yes | Yes |
| SRP Batcher | No | Yes | Yes |
| Render Features | No | Yes (ScriptableRendererFeature) | Custom Pass |
| Post-processing | Post Processing Stack v2 | Volume system (built-in) | Volume system (built-in) |
| Ray tracing | No | No (probe-based) | Yes (DXR) |
| Performance | Moderate | Optimized for scale | Highest fidelity |

**Recommendation:** Use URP for new projects unless targeting high-end visuals exclusively (HDRP). Built-in RP is legacy -- migrate when possible.

## Shader Graph

### Getting Started

1. Right-click in Project: Create > Shader Graph > URP > Lit Shader Graph
2. Double-click to open Shader Graph editor
3. Build node network connecting to Master Stack outputs
4. Create a Material using the shader, assign to renderers

### Master Stack Outputs (URP Lit)

| Output | Type | Purpose |
|--------|------|---------|
| Base Color | Color (RGB) | Albedo/diffuse color |
| Normal | Vector3 | Tangent-space normal map |
| Metallic | Float (0-1) | Metal vs. dielectric |
| Smoothness | Float (0-1) | Roughness inverse |
| Emission | Color (RGB) | Self-illumination |
| Alpha | Float (0-1) | Transparency |
| Alpha Clip Threshold | Float | Cutoff for alpha testing |

### Common Node Patterns

| Effect | Key Nodes |
|--------|-----------|
| **Dissolve** | Noise > Step > Alpha Clip + Edge emission |
| **Scrolling UV** | Time > Multiply > Add to UV |
| **Fresnel glow** | Fresnel Effect > Multiply color > Emission |
| **Triplanar mapping** | Triplanar node (avoids UV stretching) |
| **Color shift** | Lerp between colors using parameter or time |
| **Vertex displacement** | Noise > Multiply > Add to Position |
| **Outline** | Two-pass: inverted hull in custom render feature |

### Shader Graph Sub Graphs

Extract reusable node groups into Sub Graphs (Create > Shader Graph > Sub Graph). Use for shared noise functions, UV transformations, or custom lighting models.

## Hand-Written Shaders (ShaderLab + HLSL)

### URP Shader Structure

```hlsl
Shader "Custom/SimpleUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return tex * _Color;
            }
            ENDHLSL
        }
    }
}
```

**Key differences from Built-in shaders:**
- Use `HLSLPROGRAM`/`ENDHLSL` (not `CGPROGRAM`/`ENDCG`)
- Include URP shader library, not UnityCG.cginc
- Use `TEXTURE2D`/`SAMPLER` macros (not `sampler2D`)
- Wrap properties in `CBUFFER_START(UnityPerMaterial)` for SRP Batcher compatibility

## Lighting

### Light Types

| Type | Use For | Shadow Cost |
|------|---------|-------------|
| Directional | Sun, global illumination | Low (cascaded shadow maps) |
| Point | Torches, lamps | Medium |
| Spot | Flashlights, stage lights | Medium |
| Area (baked only) | Soft window light, panels | High (bake only) |

### Lighting Modes

| Mode | Description | Best For |
|------|-------------|----------|
| Realtime | Computed every frame | Dynamic objects, few lights |
| Baked | Pre-computed into lightmaps | Static environments |
| Mixed | Baked indirect + realtime direct | Best balance |

### Lightmap Baking Tips

- Set lightmap resolution based on scene scale (10-40 texels/unit for indoor)
- Use Light Probes for dynamic objects in baked scenes
- Use Reflection Probes for metallic/reflective surfaces
- Enable GPU Lightmapper for faster bake times
- Mark objects as Contribute GI in the Static flags

## Post-Processing (Volume System)

```
Setup:
1. Add a Volume (Global or Local) to the scene
2. Create a Volume Profile asset
3. Add overrides: Bloom, Color Adjustments, Tonemapping, etc.
4. Camera must have Post Processing enabled (URP Camera settings)
```

| Effect | Performance | Notes |
|--------|-------------|-------|
| Bloom | Low | Use threshold to control intensity |
| Color Adjustments | Very Low | Saturation, contrast, color filter |
| Tonemapping | Very Low | ACES for cinematic look |
| Vignette | Very Low | Frame darkening |
| Ambient Occlusion (SSAO) | Medium | Disable on mobile |
| Depth of Field | High | Use Bokeh only for cinematics |
| Motion Blur | Medium | Can cause motion sickness in VR |

## VFX Graph vs Particle System

| Feature | Particle System (Shuriken) | VFX Graph |
|---------|---------------------------|-----------|
| Execution | CPU | GPU (compute shader) |
| Particle count | Thousands | Millions |
| Complexity | Component-based, simple | Node-based, complex |
| Platform | All | Compute shader capable only |
| Integration | Physics, collision | Limited physics |

Use Particle System for gameplay-integrated effects (physics collisions, small counts). Use VFX Graph for visual spectacles (rain, fire, magic, ambient particles).

## URP Render Features

Extend URP rendering with custom ScriptableRendererFeatures:

```csharp
public class OutlineFeature : ScriptableRendererFeature
{
    OutlinePass _pass;

    public override void Create()
    {
        _pass = new OutlinePass();
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData data)
    {
        renderer.EnqueuePass(_pass);
    }
}
```

Common uses: custom outlines, screen-space effects, render texture generation, stencil-based effects.

## Additional Resources

### Reference Files
- **`references/shader-recipes.md`** -- Complete shader implementations: toon/cel shading, water, dissolve, hologram, force field, procedural skybox, stencil portal, vertex animation, custom lighting models
- **`references/lighting-vfx-detail.md`** -- Advanced lighting setups, GI troubleshooting, VFX Graph cookbook (fire, smoke, electricity, portals), Scriptable Render Pipeline customization, custom render passes
