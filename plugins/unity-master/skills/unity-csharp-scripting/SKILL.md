---
name: unity-csharp-scripting
description: C# scripting in Unity for gameplay, behavior, and engine integration. PROACTIVELY activate for: (1) writing Unity C# scripts, (2) MonoBehaviour lifecycle (Awake/OnEnable/Start/Update/FixedUpdate/LateUpdate), (3) coroutines and async/await in Unity, (4) delegates, events, Action/Func patterns, (5) ScriptableObject creation and serialization, (6) GetComponent / TryGetComponent and component caching, (7) physics scripting (Rigidbody, raycast, collision/trigger callbacks), (8) animation scripting (Animator parameters, state machines, IK), (9) NavMesh and NavMeshAgent scripting, (10) input handling (Input System package), (11) custom serialization and SerializeField. Provides: lifecycle reference, coroutine vs async patterns, ScriptableObject templates, Rigidbody/collision recipes, NavMesh examples, and Input System setup.
---

# Unity C# Scripting Patterns

## Overview

Core C# scripting reference for Unity development. Covers MonoBehaviour lifecycle, physics and collision APIs, animation scripting, audio, navigation, common design patterns, serialization, and ECS/DOTS coding patterns.

## MonoBehaviour Lifecycle

### Execution Order

```
Awake() -> OnEnable() -> Start() -> FixedUpdate() -> Update() -> LateUpdate() -> OnDisable() -> OnDestroy()
```

| Method | When Called | Use For |
|--------|-----------|---------|
| `Awake()` | Once, when object instantiates (before Start) | Self-initialization, caching references |
| `OnEnable()` | Each time object becomes active | Subscribe to events, reset state |
| `Start()` | Once, before first Update (after all Awake) | Cross-object initialization |
| `FixedUpdate()` | Fixed timestep (default 0.02s) | Physics, Rigidbody movement |
| `Update()` | Every frame | Input, non-physics logic |
| `LateUpdate()` | After all Update calls | Camera follow, post-movement adjustments |
| `OnDisable()` | When object deactivates | Unsubscribe events, save state |
| `OnDestroy()` | When object is destroyed | Final cleanup, resource release |

### Key Rules
- Awake runs even on disabled components (but not disabled GameObjects)
- Never rely on Awake/Start order between scripts -- use `[DefaultExecutionOrder(N)]` or Script Execution Order settings
- Use `OnValidate()` for editor-time validation of serialized fields

## Coroutines and Async

### Coroutines

```csharp
IEnumerator SpawnWaves(int count, float delay)
{
    for (int i = 0; i < count; i++)
    {
        SpawnEnemy();
        yield return new WaitForSeconds(delay);
    }
}
// Start: Coroutine handle = StartCoroutine(SpawnWaves(5, 1f));
// Stop: StopCoroutine(handle); or StopAllCoroutines();
```

| Yield Instruction | Behavior |
|-------------------|----------|
| `yield return null` | Wait one frame |
| `yield return new WaitForSeconds(t)` | Wait t seconds (affected by timeScale) |
| `yield return new WaitForSecondsRealtime(t)` | Unscaled time |
| `yield return new WaitForFixedUpdate()` | Wait for next FixedUpdate |
| `yield return new WaitForEndOfFrame()` | After rendering |
| `yield return new WaitUntil(() => condition)` | Wait until predicate is true |
| `yield return StartCoroutine(other)` | Wait for nested coroutine |

### Async/Await (Unity 6+ / UniTask)

For Unity 2023+/Unity 6, `Awaitable` is built-in. For older versions, use UniTask.

```csharp
async Awaitable LoadLevelAsync(string sceneName)
{
    await Awaitable.WaitForSecondsAsync(1f);
    var op = SceneManager.LoadSceneAsync(sceneName);
    while (!op.isDone)
    {
        progressBar.value = op.progress;
        await Awaitable.NextFrameAsync();
    }
}
```

## Events and Delegates

### Event Pattern (Recommended)

```csharp
// Publisher
public class Health : MonoBehaviour
{
    public event System.Action<float> OnDamaged;  // event keyword prevents external invocation
    public event System.Action OnDeath;

    public void TakeDamage(float amount)
    {
        currentHealth -= amount;
        OnDamaged?.Invoke(amount);
        if (currentHealth <= 0) OnDeath?.Invoke();
    }
}

// Subscriber
void OnEnable() => health.OnDamaged += HandleDamage;
void OnDisable() => health.OnDamaged -= HandleDamage;
void HandleDamage(float amount) => /* react */;
```

### ScriptableObject Event Channels

Decouple systems without direct references. Create `GameEvent` as a ScriptableObject asset, invoke from publishers, and listen from subscribers via `GameEventListener` MonoBehaviours. See `references/design-patterns.md` for full implementation.

## Physics API Quick Reference

### Rigidbody Movement (3D)

| Task | Method | Where |
|------|--------|-------|
| Continuous force | `rb.AddForce(dir * force)` | FixedUpdate |
| Instant impulse | `rb.AddForce(dir * force, ForceMode.Impulse)` | FixedUpdate |
| Direct velocity | `rb.linearVelocity = dir * speed` | FixedUpdate |
| Kinematic move | `rb.MovePosition(target)` | FixedUpdate |
| Rotation | `rb.MoveRotation(targetRot)` | FixedUpdate |

Note: In Unity 6, `Rigidbody.velocity` is renamed to `Rigidbody.linearVelocity`.

### Raycasting

```csharp
if (Physics.Raycast(origin, direction, out RaycastHit hit, maxDistance, layerMask))
{
    Debug.Log($"Hit {hit.collider.name} at {hit.point}");
}
// Use Physics.RaycastAll or Physics.RaycastNonAlloc for multiple hits
// 2D: Physics2D.Raycast, Physics2D.OverlapCircle, etc.
```

### Collision vs Trigger

| Callback | Requires | Use For |
|----------|----------|---------|
| `OnCollisionEnter/Stay/Exit` | Both have colliders, at least one Rigidbody, isTrigger=false | Physical impacts |
| `OnTriggerEnter/Stay/Exit` | One collider has isTrigger=true, at least one Rigidbody | Zones, pickups, detection |

Always use `CompareTag("Enemy")` instead of `other.tag == "Enemy"` (avoids GC allocation).

## Animation Scripting

```csharp
[RequireComponent(typeof(Animator))]
public class CharacterAnimation : MonoBehaviour
{
    static readonly int SpeedHash = Animator.StringToHash("Speed");
    static readonly int JumpTrigger = Animator.StringToHash("Jump");
    Animator _anim;

    void Awake() => _anim = GetComponent<Animator>();
    void Update()
    {
        _anim.SetFloat(SpeedHash, moveSpeed);
        if (jumped) _anim.SetTrigger(JumpTrigger);
    }
}
```

Cache `Animator.StringToHash` results as static readonly fields to avoid per-frame hashing. Use Animation Events for gameplay-timed callbacks (footsteps, hit frames). For IK, implement `OnAnimatorIK(int layerIndex)` with `SetIKPosition/Rotation/Weight`.

## Audio Quick Reference

```csharp
[RequireComponent(typeof(AudioSource))]
public class SFXPlayer : MonoBehaviour
{
    [SerializeField] AudioClip[] clips;
    AudioSource _source;
    void Awake() => _source = GetComponent<AudioSource>();
    public void PlayRandom() => _source.PlayOneShot(clips[Random.Range(0, clips.Length)]);
}
```

Use `AudioSource.PlayOneShot()` for overlapping SFX. Use `AudioMixer` with exposed parameters for volume control. Use snapshots for state transitions (combat vs. exploration).

## Serialization

| Type | Serialized | Notes |
|------|-----------|-------|
| `public` fields | Yes | Visible in Inspector |
| `[SerializeField] private` | Yes | Preferred -- maintains encapsulation |
| `[HideInInspector] public` | Yes, hidden | Serialized but not shown |
| `[NonSerialized] public` | No | Opt-out of serialization |
| Properties | No | Never serialized by Unity |
| Dictionaries | No | Use serialized list + rebuild, or Odin/SerializedDictionary |
| Interfaces | No | Use abstract ScriptableObject or SerializeReference |

Use `[SerializeReference]` for polymorphic serialization of interfaces and abstract types.

## Common Design Patterns

| Pattern | When to Use | Approach |
|---------|------------|----------|
| Singleton | Global managers (Audio, GameState) | ScriptableObject-based or lazy MonoBehaviour |
| Observer | Decoupled communication | C# events or SO event channels |
| Command | Input/undo systems | Command interface + history stack |
| State Machine | AI, player states | Enum + switch, or class-based states |
| Object Pool | Bullets, particles, enemies | Queue<T> with pre-instantiation |
| Service Locator | Testable global access | Static registry with interface keys |

For detailed implementations and code examples, see `references/design-patterns.md`.

## ECS/DOTS Quick Reference

| Concept | Role |
|---------|------|
| Entity | Lightweight ID (no MonoBehaviour) |
| IComponentData | Pure data struct on entities |
| SystemBase / ISystem | Logic operating on component queries |
| EntityQuery | Filter entities by component sets |
| Jobs (IJobEntity) | Multithreaded systems |
| Burst Compiler | SIMD-optimized native code |

For ECS architecture patterns and migration guidance, see `references/design-patterns.md`.

## Additional Resources

### Reference Files
- **`references/design-patterns.md`** -- Full implementations of singleton, observer, command, state machine, object pool, service locator, and ECS patterns
- **`references/physics-animation-audio.md`** -- Detailed physics setup (2D and 3D), advanced animation (blend trees, IK, root motion, Animation Rigging), and audio architecture
