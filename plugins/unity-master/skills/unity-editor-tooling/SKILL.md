---
name: unity-editor-tooling
description: |
  This skill should be used when the user asks about "custom inspector",
  "EditorWindow", "PropertyDrawer", "editor scripting", "Unity Editor tool",
  "ScriptedImporter", "custom asset importer", "build pipeline",
  "build script", "platform switching", "CI/CD Unity", "GameCI",
  "GitHub Actions Unity", "Unity Build Automation", "Assembly Definition",
  "asmdef", "Package Manager", "custom package", "UPM",
  "Unity Test Framework", "Play Mode test", "Edit Mode test",
  "NUnit Unity", ".gitignore Unity", "YAML merge", "smart merge",
  "Terrain", "ProBuilder", "version control Unity",
  or needs help with editor extensions, build automation, testing, or tooling.
---

# Unity Editor Scripting and Tooling

## Overview

Reference for extending the Unity Editor, automating builds, testing, version control configuration, and package development. Covers custom inspectors, editor windows, build pipeline scripting, CI/CD, and the Unity Test Framework.

## Custom Inspectors

### Basic Custom Editor

```csharp
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(EnemySpawner))]
public class EnemySpawnerEditor : Editor
{
    SerializedProperty spawnPoints;
    SerializedProperty enemyPrefab;
    SerializedProperty spawnInterval;

    void OnEnable()
    {
        spawnPoints = serializedObject.FindProperty("_spawnPoints");
        enemyPrefab = serializedObject.FindProperty("_enemyPrefab");
        spawnInterval = serializedObject.FindProperty("_spawnInterval");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(enemyPrefab);
        EditorGUILayout.Slider(spawnInterval, 0.1f, 10f, new GUIContent("Spawn Interval"));

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Spawn Points", EditorStyles.boldLabel);
        EditorGUILayout.PropertyField(spawnPoints, true);

        if (GUILayout.Button("Add Spawn Point at Origin"))
        {
            spawnPoints.InsertArrayElementAtIndex(spawnPoints.arraySize);
            var newElement = spawnPoints.GetArrayElementAtIndex(spawnPoints.arraySize - 1);
            newElement.vector3Value = Vector3.zero;
        }

        serializedObject.ApplyModifiedProperties();
    }

    void OnSceneGUI()
    {
        var spawner = (EnemySpawner)target;
        // Draw handles in scene view for each spawn point
        for (int i = 0; i < spawner.SpawnPointCount; i++)
        {
            Vector3 point = spawner.GetSpawnPoint(i);
            Vector3 newPoint = Handles.PositionHandle(point, Quaternion.identity);
            if (point != newPoint)
            {
                Undo.RecordObject(spawner, "Move Spawn Point");
                spawner.SetSpawnPoint(i, newPoint);
            }
        }
    }
}
#endif
```

**Key rules:**
- Always wrap editor code in `#if UNITY_EDITOR` or place in `Editor/` folders
- Use `SerializedProperty` for undo/redo support and multi-object editing
- Call `serializedObject.Update()` before and `ApplyModifiedProperties()` after changes
- Use `Undo.RecordObject()` before direct modifications

### PropertyDrawer

```csharp
[CustomPropertyDrawer(typeof(MinMaxRange))]
public class MinMaxRangeDrawer : PropertyDrawer
{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        EditorGUI.BeginProperty(position, label, property);
        var min = property.FindPropertyRelative("min");
        var max = property.FindPropertyRelative("max");
        float minVal = min.floatValue;
        float maxVal = max.floatValue;

        position = EditorGUI.PrefixLabel(position, label);
        EditorGUI.MinMaxSlider(position, ref minVal, ref maxVal, 0f, 100f);
        min.floatValue = minVal;
        max.floatValue = maxVal;
        EditorGUI.EndProperty();
    }
}
```

Use PropertyDrawers for reusable field-level customization. Use CustomEditors for component-level customization.

## EditorWindow

```csharp
public class LevelEditorWindow : EditorWindow
{
    [MenuItem("Tools/Level Editor")]
    static void ShowWindow() => GetWindow<LevelEditorWindow>("Level Editor");

    Vector2 scrollPos;
    string searchFilter = "";

    void OnGUI()
    {
        EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
        searchFilter = EditorGUILayout.TextField(searchFilter, EditorStyles.toolbarSearchField);
        if (GUILayout.Button("Refresh", EditorStyles.toolbarButton, GUILayout.Width(60)))
            RefreshData();
        EditorGUILayout.EndHorizontal();

        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
        // Draw content
        EditorGUILayout.EndScrollView();
    }

    void OnSelectionChange() => Repaint(); // React to selection changes
}
```

Use `EditorWindow` for standalone tools. Use `[MenuItem]` for menu bar integration. Override `OnSelectionChange`, `OnHierarchyChange`, `OnProjectChange` for reactive updates.

## ScriptedImporter

```csharp
[ScriptedImporter(1, "leveldata")]
public class LevelDataImporter : ScriptedImporter
{
    public override void OnImportAsset(AssetImportContext ctx)
    {
        string json = File.ReadAllText(ctx.assetPath);
        var levelData = ScriptableObject.CreateInstance<LevelData>();
        JsonUtility.FromJsonOverwrite(json, levelData);
        ctx.AddObjectToAsset("main", levelData);
        ctx.SetMainObject(levelData);
    }
}
```

Register custom file extensions. Unity re-imports automatically when the source file changes.

## Build Pipeline

### Build Script

```csharp
public static class BuildScript
{
    [MenuItem("Build/Build Windows")]
    public static void BuildWindows()
    {
        var options = new BuildPlayerOptions
        {
            scenes = EditorBuildSettings.scenes
                .Where(s => s.enabled)
                .Select(s => s.path).ToArray(),
            locationPathName = "Builds/Windows/Game.exe",
            target = BuildTarget.StandaloneWindows64,
            options = BuildOptions.None
        };

        var report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result != BuildResult.Succeeded)
            throw new Exception($"Build failed: {report.summary.totalErrors} errors");
    }
}
```

### CI/CD with GameCI (GitHub Actions)

```yaml
name: Unity Build
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        targetPlatform: [StandaloneWindows64, StandaloneLinux64, WebGL]
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - uses: game-ci/unity-builder@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
          UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
          UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          buildMethod: BuildScript.Build${{ matrix.targetPlatform }}

      - uses: actions/upload-artifact@v4
        with:
          name: build-${{ matrix.targetPlatform }}
          path: build/${{ matrix.targetPlatform }}
```

Activate a Unity license first using `game-ci/unity-activate`. Use Unity Build Automation (Cloud Build) as an alternative if CI runners lack capacity.

## Assembly Definitions

```
Project/
├── Scripts/
│   ├── Core/             Core.asmdef          (no references)
│   ├── Gameplay/          Gameplay.asmdef      (references: Core)
│   ├── UI/                UI.asmdef            (references: Core, Gameplay)
│   ├── Networking/        Networking.asmdef     (references: Core)
│   ├── Editor/            Editor.asmdef        (references: Core; Editor-only platform)
│   └── Tests/
│       ├── EditMode/      Tests.EditMode.asmdef (references: Core; Test assemblies)
│       └── PlayMode/      Tests.PlayMode.asmdef (references: Core, Gameplay)
```

**Benefits:** Incremental compilation (only recompile changed assemblies), enforced dependency boundaries, required for testability.

**Rules:**
- Set Editor-only assemblies to Editor platform only
- Test assemblies must reference `UnityEngine.TestRunner` and `UnityEditor.TestRunner`
- Use Assembly Definition References for cross-assembly access

## Unity Test Framework

### Edit Mode Test

```csharp
[TestFixture]
public class InventoryTests
{
    [Test]
    public void AddItem_IncreasesCount()
    {
        var inventory = new Inventory(maxSlots: 10);
        inventory.Add(new Item("Sword", 1));
        Assert.AreEqual(1, inventory.Count);
    }

    [Test]
    public void AddItem_WhenFull_ReturnsFalse()
    {
        var inventory = new Inventory(maxSlots: 1);
        inventory.Add(new Item("Sword", 1));
        Assert.IsFalse(inventory.Add(new Item("Shield", 1)));
    }
}
```

### Play Mode Test

```csharp
[UnityTest]
public IEnumerator Player_TakesDamage_HealthDecreases()
{
    var player = new GameObject().AddComponent<PlayerHealth>();
    player.Initialize(100);
    player.TakeDamage(30);
    yield return null; // Wait one frame
    Assert.AreEqual(70, player.CurrentHealth);
}
```

Run tests via Window > General > Test Runner. Edit Mode tests run instantly. Play Mode tests enter play mode and can test MonoBehaviour logic, coroutines, and physics.

## Version Control

### Unity .gitignore (Essential Entries)

```
/[Ll]ibrary/
/[Tt]emp/
/[Oo]bj/
/[Bb]uild/
/[Bb]uilds/
/[Ll]ogs/
/[Uu]ser[Ss]ettings/
/[Mm]emoryCaptures/
/[Rr]ecordings/
*.csproj
*.sln
*.suo
*.user
*.pidb
*.booproj
*.unityproj
```

### Project Settings for Version Control

1. Edit > Project Settings > Editor > Asset Serialization: Force Text
2. Edit > Project Settings > Editor > Version Control Mode: Visible Meta Files
3. Use Unity Smart Merge: configure `.gitattributes` with `*.unity merge=unityyamlmerge`
4. Install UnityYAMLMerge (ships with Unity) and configure git to use it

## Custom Packages (UPM)

```
com.company.my-package/
├── package.json
├── Runtime/
│   ├── com.company.my-package.asmdef
│   └── MyScript.cs
├── Editor/
│   ├── com.company.my-package.editor.asmdef
│   └── MyEditorScript.cs
├── Tests/
│   ├── Runtime/
│   └── Editor/
├── Documentation~/
├── CHANGELOG.md
└── README.md
```

Install local packages via `manifest.json`: `"com.company.my-package": "file:../../Packages/my-package"` or via git URL.

## Additional Resources

### Reference Files
- **`references/editor-recipes.md`** -- Advanced editor patterns: Gizmos, Handles, SceneView overlays, custom menus, asset post-processors, build hooks (IPreprocessBuildWithReport), serialization callbacks, Terrain and ProBuilder scripting, multi-scene editing workflows
