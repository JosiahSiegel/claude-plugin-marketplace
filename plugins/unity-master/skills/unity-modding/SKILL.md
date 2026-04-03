---
name: unity-modding
description: |
  This skill should be used when the user asks about "modding support",
  "mod loading", "mod API", "Asset Bundles", "Addressables for mods",
  "Lua scripting Unity", "MoonSharp", "Harmony patching", "IL injection",
  "Steam Workshop integration", "mod manager", "plugin architecture game",
  "user-generated content", "UGC", "custom content loading",
  "runtime asset loading", "mod SDK", "modding framework",
  or needs help designing extensible game architectures for community mods.
---

# Unity Modding Architecture

## Overview

Guide for designing Unity games that support community modding. Covers asset loading systems, scripted mod APIs, mod manager patterns, distribution platforms, and techniques for modding existing games.

## Modding Architecture Tiers

| Tier | What Modders Can Do | Complexity |
|------|---------------------|------------|
| **Data Mods** | Replace textures, sounds, configs (JSON/XML) | Low |
| **Asset Mods** | Add new models, maps, items via Asset Bundles | Medium |
| **Script Mods** | Custom game logic via Lua/scripting API | High |
| **Code Mods** | Patch game assemblies via Harmony/BepInEx | Expert |

Design your game to support at least Tier 1-2 from the start. Tiers 3-4 require deliberate API design.

## Asset Loading for Mods

### Addressables (Recommended)

Addressables provide a unified API for loading assets from local bundles, remote servers, or mod directories.

```csharp
// Load a mod's asset catalog at runtime
public async Awaitable LoadModCatalog(string modPath)
{
    string catalogPath = Path.Combine(modPath, "catalog.json");
    var locator = await Addressables.LoadContentCatalogAsync(catalogPath);
    Debug.Log($"Loaded mod catalog with {locator.Keys.Count()} assets");
}

// Load an asset by address (works for both base game and mods)
var prefab = await Addressables.LoadAssetAsync<GameObject>("enemies/goblin");
Instantiate(prefab);
```

**Mod workflow:**
1. Modders use a Unity project with Addressables configured
2. Build Addressable groups into Asset Bundles
3. Ship the catalog.json + .bundle files
4. Game loads catalogs at runtime from the mod directory

### Asset Bundles (Legacy but Simpler)

```csharp
public async Awaitable<AssetBundle> LoadModBundle(string path)
{
    var request = AssetBundle.LoadFromFileAsync(path);
    await request;
    return request.assetBundle;
}

// Load specific asset from bundle
var bundle = await LoadModBundle("mods/weapons/swords.bundle");
var swordPrefab = bundle.LoadAsset<GameObject>("BroadSword");
```

**Key rules:**
- Never load the same bundle twice (track loaded bundles)
- Unload bundles when mods are disabled: `bundle.Unload(true)`
- Use `AssetBundle.LoadFromFileAsync` for local files (not `LoadFromMemory`)

### Hot-Reloadable Data Mods

For simple data mods (JSON configs, CSV tables):

```csharp
public T LoadModConfig<T>(string modPath, string fileName)
{
    string filePath = Path.Combine(modPath, fileName);
    if (!File.Exists(filePath)) return default;
    string json = File.ReadAllText(filePath);
    return JsonUtility.FromJson<T>(json);
}
```

Use `FileSystemWatcher` to detect changes and hot-reload during development.

## Lua Scripting with MoonSharp

MoonSharp is a Lua interpreter written in C# that runs on all Unity platforms.

### Setup

Install via NuGet or download the DLL. Register safe API surfaces for modders:

```csharp
public class ModScriptEngine
{
    Script _lua;

    public void Initialize()
    {
        _lua = new Script();

        // Register safe game API
        _lua.Globals["SpawnEntity"] = (Func<string, float, float, float, bool>)SpawnEntity;
        _lua.Globals["GetPlayerHealth"] = (Func<float>)(() => player.Health);
        _lua.Globals["ShowMessage"] = (Action<string>)ShowMessage;
        _lua.Globals["RegisterEvent"] = (Action<string, DynValue>)RegisterEvent;
    }

    public void LoadMod(string luaFilePath)
    {
        string code = File.ReadAllText(luaFilePath);
        _lua.DoString(code);
    }

    bool SpawnEntity(string id, float x, float y, float z)
    {
        // Validate and spawn - never trust mod input
        if (!entityRegistry.Contains(id)) return false;
        var pos = new Vector3(x, y, z);
        if (!IsValidSpawnPosition(pos)) return false;
        entityRegistry.Spawn(id, pos);
        return true;
    }
}
```

### Modder-Side Lua

```lua
-- my_mod/init.lua
RegisterEvent("OnPlayerEnterZone", function(zoneName)
    if zoneName == "boss_arena" then
        SpawnEntity("dragon_boss", 0, 5, 0)
        ShowMessage("A dragon appears!")
    end
end)
```

### Security Considerations

| Risk | Mitigation |
|------|-----------|
| File system access | Do NOT expose System.IO to Lua |
| Infinite loops | Set instruction count limits: `script.Options.InstructionLimit = 100000` |
| Memory abuse | Limit table sizes, monitor allocation |
| Network access | Never expose HTTP/socket APIs |
| Reflection abuse | MoonSharp sandboxes by default, but validate registered types |

## Mod Manager Pattern

### Architecture

```
Game
├── ModManager (singleton)
│   ├── DiscoverMods(modsFolder)     // Scan for mod manifests
│   ├── ValidateMod(manifest)        // Version compat, dependencies
│   ├── LoadMod(modId)               // Load assets + scripts
│   ├── UnloadMod(modId)             // Clean teardown
│   └── GetLoadOrder()               // Dependency-sorted order
├── ModManifest (ScriptableObject / JSON)
│   ├── id, name, version, author
│   ├── dependencies[]
│   ├── gameVersionMin / gameVersionMax
│   └── entryPoint (script path)
└── ModSandbox
    ├── Lua scripting environment
    └── Restricted API surface
```

### Mod Manifest Format

```json
{
    "id": "com.author.mymod",
    "name": "My Awesome Mod",
    "version": "1.2.0",
    "author": "ModAuthor",
    "description": "Adds new enemies and weapons",
    "gameVersionMin": "1.0.0",
    "gameVersionMax": "2.0.0",
    "dependencies": ["com.author.corelib@1.0.0"],
    "entryPoint": "scripts/init.lua",
    "assets": "bundles/"
}
```

## Steam Workshop Integration

Use Steamworks.NET or Facepunch.Steamworks for Steam Workshop integration:

1. **Upload:** Modder packages mod folder, calls `SteamUGC.CreateItem` + `SteamUGC.SubmitItemUpdate`
2. **Subscribe:** Players subscribe in Steam Workshop UI
3. **Download:** Game queries `SteamUGC.GetSubscribedItems()` at startup
4. **Load:** Read from `SteamUGC.GetItemInstallInfo` path into ModManager

## Harmony Patching (Modding Existing Games)

Harmony is used by modders (via BepInEx/MelonLoader) to patch compiled game code at runtime.

```csharp
[HarmonyPatch(typeof(PlayerHealth), "TakeDamage")]
class DamageModifier
{
    // Prefix: runs before original method
    static bool Prefix(ref float damage)
    {
        damage *= 0.5f; // Halve all damage
        return true;    // true = continue to original
    }

    // Postfix: runs after original method
    static void Postfix(PlayerHealth __instance)
    {
        Debug.Log($"Health after damage: {__instance.CurrentHealth}");
    }
}
```

If designing a game intended to be modded via Harmony, avoid aggressive code obfuscation and keep method signatures stable across updates.

## Additional Resources

### Reference Files
- **`references/mod-framework-detail.md`** -- Complete mod manager implementation, dependency resolution algorithm, mod load ordering, versioned API patterns, hot-reload systems, mod testing frameworks, BepInEx/MelonLoader setup guide
