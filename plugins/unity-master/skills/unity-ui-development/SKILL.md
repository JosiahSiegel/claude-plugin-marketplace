---
name: unity-ui-development
description: |
  This skill should be used when the user asks about "Unity UI", "UGUI",
  "Canvas", "RectTransform", "UI Toolkit", "USS", "UXML", "VisualElement",
  "EventSystem", "Button click", "scroll view", "dropdown", "inventory UI",
  "health bar", "HUD", "menu system", "TextMeshPro", "anchors",
  "responsive UI", "UI layout", "runtime UI", "world space canvas",
  "UI binding", "UI Builder", or needs help building Unity user interfaces.
---

# Unity UI Development

## Overview

Unity provides two UI systems: UGUI (the established GameObject-based system) and UI Toolkit (the newer retained-mode system inspired by web technologies). This skill covers both systems, when to use each, and implementation patterns.

## Choosing a UI System

| Factor | UGUI | UI Toolkit |
|--------|------|------------|
| Runtime UI | Mature, full-featured | Supported (Unity 2023+) |
| Editor UI | Not supported | Primary system for editor |
| World-space UI | Excellent (World Space Canvas) | Limited |
| Animation/Tweening | DOTween, Animator, LeanTween | USS transitions, C# manipulation |
| Styling | Per-element, manual | USS stylesheets (CSS-like) |
| Performance | Draw call heavy with many canvases | Retained mode, lighter draw calls |
| Learning curve | Lower for Unity devs | Higher (web-like paradigm) |
| VR/AR | Well-supported | Limited world-space support |

**Recommendation:** Use UGUI for world-space UI, VR/AR, and projects needing maximum asset store compatibility. Use UI Toolkit for editor extensions, complex data-driven UIs (lists, trees), and projects on Unity 2023+.

## UGUI (Canvas-Based UI)

### Canvas Setup

| Render Mode | Use For | Notes |
|-------------|---------|-------|
| Screen Space - Overlay | HUD, menus | Always on top, no camera needed |
| Screen Space - Camera | Post-processing on UI | Assign render camera |
| World Space | In-game signs, health bars | Set event camera for interaction |

**Performance rule:** Separate static and dynamic UI into different Canvases. A Canvas rebuilds ALL children when any child changes.

### RectTransform Anchoring

```
Anchor presets control how elements resize with parent:
- Stretch-Stretch: Element fills parent (full-screen backgrounds)
- Center-Center: Fixed size at center (popup dialogs)
- Bottom-Left: Fixed corner position (minimap)
- Top-Stretch: Stretches horizontally, fixed at top (nav bar)
```

Set anchors via the RectTransform anchor preset widget (hold Alt+Shift to also set pivot and position). Use `anchorMin`, `anchorMax`, `offsetMin`, `offsetMax` in code.

### Layout Components

| Component | Purpose |
|-----------|---------|
| `HorizontalLayoutGroup` | Arrange children left-to-right |
| `VerticalLayoutGroup` | Arrange children top-to-bottom |
| `GridLayoutGroup` | Grid arrangement (inventory slots) |
| `LayoutElement` | Override min/preferred/flexible size |
| `ContentSizeFitter` | Auto-resize to content |
| `AspectRatioFitter` | Maintain aspect ratio |

Disable `Layout.childForceExpandWidth/Height` to prevent unwanted stretching.

### Event Handling

```csharp
using UnityEngine.UI;
using TMPro;

[SerializeField] Button startButton;
[SerializeField] TMP_InputField nameField;
[SerializeField] Slider volumeSlider;

void OnEnable()
{
    startButton.onClick.AddListener(OnStartClicked);
    nameField.onEndEdit.AddListener(OnNameChanged);
    volumeSlider.onValueChanged.AddListener(OnVolumeChanged);
}

void OnDisable()
{
    startButton.onClick.RemoveListener(OnStartClicked);
    nameField.onEndEdit.RemoveListener(OnNameChanged);
    volumeSlider.onValueChanged.RemoveListener(OnVolumeChanged);
}
```

Always `RemoveListener` in `OnDisable` to prevent leaks and ghost references.

### TextMeshPro

Always use TextMeshPro (`TMP_Text`, `TextMeshProUGUI`) over legacy `Text`. Import TMP Essentials when prompted. Use rich text tags: `<color=#FF0000>`, `<b>`, `<size=24>`, `<sprite=0>` for inline icons.

## UI Toolkit (USS/UXML)

### Architecture

```
UI Toolkit Stack:
  UXML  -- Structure (like HTML)
  USS   -- Styling (like CSS)
  C#    -- Logic (like JavaScript)
```

### UXML Structure

```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:VisualElement class="container">
        <ui:Label text="Player Stats" class="title" />
        <ui:ProgressBar name="health-bar" title="HP" high-value="100" />
        <ui:Button name="attack-btn" text="Attack" class="action-btn" />
        <ui:ListView name="inventory-list" />
    </ui:VisualElement>
</ui:UXML>
```

### USS Styling

```css
.container {
    flex-direction: column;
    padding: 10px;
    background-color: rgba(0, 0, 0, 0.8);
    border-radius: 8px;
}

.title {
    font-size: 24px;
    color: white;
    -unity-font-style: bold;
    margin-bottom: 10px;
}

.action-btn {
    height: 40px;
    background-color: #4CAF50;
    color: white;
    border-radius: 4px;
    transition-duration: 0.2s;
}

.action-btn:hover {
    background-color: #66BB6A;
    scale: 1.05 1.05;
}
```

Key USS differences from CSS: use `-unity-` prefix for Unity-specific properties. Flexbox is the layout model (default `flex-direction: column`). Use `transition-duration`, `transition-property` for animations.

### C# Integration

```csharp
[RequireComponent(typeof(UIDocument))]
public class StatsUI : MonoBehaviour
{
    void OnEnable()
    {
        var root = GetComponent<UIDocument>().rootVisualElement;
        var healthBar = root.Q<ProgressBar>("health-bar");
        var attackBtn = root.Q<Button>("attack-btn");
        var inventory = root.Q<ListView>("inventory-list");

        attackBtn.RegisterCallback<ClickEvent>(OnAttack);
        healthBar.value = player.Health;

        // ListView binding
        inventory.makeItem = () => new Label();
        inventory.bindItem = (element, index) =>
            ((Label)element).text = items[index].Name;
        inventory.itemsSource = items;
    }
}
```

Query elements with `Q<T>("name")` or `Q<T>(className: "class")`. Register callbacks with `RegisterCallback<EventType>`. Always query from `rootVisualElement`.

### Data Binding (Unity 2023.2+)

```csharp
// Runtime data binding with [CreateProperty] and INotifyBindablePropertyChanged
public class PlayerData : INotifyBindablePropertyChanged
{
    public event EventHandler<BindablePropertyChangedEventArgs> propertyChanged;
    private int _health;

    [CreateProperty]
    public int Health
    {
        get => _health;
        set { _health = value; Notify(); }
    }
    void Notify([CallerMemberName] string prop = "")
        => propertyChanged?.Invoke(this, new BindablePropertyChangedEventArgs(prop));
}
```

Bind in UXML with `binding-path="Health"` or in C# with `element.SetBinding("value", new DataBinding { dataSourcePath = ... })`.

## Common UI Patterns

| Pattern | UGUI Approach | UI Toolkit Approach |
|---------|---------------|---------------------|
| Popup dialog | Enable/disable child panel | Add/remove from visual tree |
| Scroll list | ScrollRect + VerticalLayoutGroup | ListView (virtualized) |
| Drag-and-drop | IBeginDragHandler, IDragHandler, IEndDragHandler | PointerManipulator |
| Tab system | Toggle group + panels | RadioButtonGroup + display toggling |
| Tooltip | Follow cursor panel | Manipulator + VisualElement positioning |
| Screen fade | CanvasGroup.alpha tween | USS opacity transition |

## Additional Resources

### Reference Files
- **`references/ugui-patterns.md`** -- Advanced UGUI patterns: scroll optimization, dynamic layouts, world-space interaction, localization, safe area handling, screen adaptation
- **`references/ui-toolkit-advanced.md`** -- Custom controls, ListView/TreeView mastery, custom manipulators, editor UI integration, theming, responsive layouts
