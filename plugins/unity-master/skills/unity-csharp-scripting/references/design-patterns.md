# Unity C# Design Patterns - Complete Reference

## ScriptableObject Singleton

Avoid MonoBehaviour singletons where possible. ScriptableObject-based singletons are testable and survive scene reloads:

```csharp
// Generic SO singleton base
public abstract class SingletonSO<T> : ScriptableObject where T : ScriptableObject
{
    static T _instance;
    public static T Instance
    {
        get
        {
            if (_instance == null)
                _instance = Resources.Load<T>(typeof(T).Name);
            return _instance;
        }
    }
}

// Usage
[CreateAssetMenu(menuName = "Config/Game Settings")]
public class GameSettings : SingletonSO<GameSettings>
{
    public float Gravity = -9.81f;
    public int MaxEnemies = 50;
    public AnimationCurve DifficultyCurve;
}
```

If a MonoBehaviour singleton is truly needed (e.g., AudioManager that plays sounds), use the lazy initialization pattern:

```csharp
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
```

## ScriptableObject Event Channels

Fully decoupled event system using SO assets. Publishers and subscribers reference the same SO asset, requiring no direct script references.

```csharp
// Event with no parameters
[CreateAssetMenu(menuName = "Events/Game Event")]
public class GameEvent : ScriptableObject
{
    readonly List<GameEventListener> _listeners = new();

    public void Raise()
    {
        // Iterate backwards for safe removal during iteration
        for (int i = _listeners.Count - 1; i >= 0; i--)
            _listeners[i].OnEventRaised();
    }

    public void Register(GameEventListener listener) => _listeners.Add(listener);
    public void Unregister(GameEventListener listener) => _listeners.Remove(listener);
}

// Listener component (attach to GameObjects that respond to events)
public class GameEventListener : MonoBehaviour
{
    [SerializeField] GameEvent _event;
    [SerializeField] UnityEvent _response;

    void OnEnable() => _event.Register(this);
    void OnDisable() => _event.Unregister(this);
    public void OnEventRaised() => _response.Invoke();
}

// Typed event for data passing
[CreateAssetMenu(menuName = "Events/Float Event")]
public class FloatEvent : ScriptableObject
{
    readonly List<FloatEventListener> _listeners = new();
    public void Raise(float value)
    {
        for (int i = _listeners.Count - 1; i >= 0; i--)
            _listeners[i].OnEventRaised(value);
    }
    public void Register(FloatEventListener l) => _listeners.Add(l);
    public void Unregister(FloatEventListener l) => _listeners.Remove(l);
}
```

## Command Pattern (Input / Undo)

```csharp
public interface ICommand
{
    void Execute();
    void Undo();
}

public class MoveCommand : ICommand
{
    readonly Transform _target;
    readonly Vector3 _delta;
    Vector3 _previousPosition;

    public MoveCommand(Transform target, Vector3 delta)
    {
        _target = target;
        _delta = delta;
    }

    public void Execute()
    {
        _previousPosition = _target.position;
        _target.position += _delta;
    }

    public void Undo() => _target.position = _previousPosition;
}

public class CommandManager
{
    readonly Stack<ICommand> _undoStack = new();
    readonly Stack<ICommand> _redoStack = new();

    public void Execute(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear();
    }

    public void Undo()
    {
        if (_undoStack.Count == 0) return;
        var cmd = _undoStack.Pop();
        cmd.Undo();
        _redoStack.Push(cmd);
    }

    public void Redo()
    {
        if (_redoStack.Count == 0) return;
        var cmd = _redoStack.Pop();
        cmd.Execute();
        _undoStack.Push(cmd);
    }
}
```

## Class-Based State Machine

```csharp
public interface IState
{
    void Enter();
    void Execute();  // Called each frame
    void Exit();
}

public class StateMachine
{
    IState _currentState;
    readonly Dictionary<System.Type, IState> _states = new();

    public void AddState(IState state) => _states[state.GetType()] = state;

    public void ChangeState<T>() where T : IState
    {
        _currentState?.Exit();
        _currentState = _states[typeof(T)];
        _currentState.Enter();
    }

    public void Update() => _currentState?.Execute();
}

// Example states
public class IdleState : IState
{
    readonly EnemyAI _ai;
    public IdleState(EnemyAI ai) => _ai = ai;

    public void Enter() => _ai.Animator.SetBool("IsIdle", true);
    public void Execute()
    {
        if (_ai.CanSeePlayer())
            _ai.StateMachine.ChangeState<ChaseState>();
    }
    public void Exit() => _ai.Animator.SetBool("IsIdle", false);
}

public class ChaseState : IState
{
    readonly EnemyAI _ai;
    public ChaseState(EnemyAI ai) => _ai = ai;

    public void Enter() => _ai.Agent.SetDestination(_ai.Player.position);
    public void Execute()
    {
        _ai.Agent.SetDestination(_ai.Player.position);
        if (_ai.IsInAttackRange())
            _ai.StateMachine.ChangeState<AttackState>();
        else if (!_ai.CanSeePlayer())
            _ai.StateMachine.ChangeState<IdleState>();
    }
    public void Exit() => _ai.Agent.ResetPath();
}
```

## Service Locator

Alternative to singletons that supports testing via interface substitution:

```csharp
public static class ServiceLocator
{
    static readonly Dictionary<System.Type, object> _services = new();

    public static void Register<T>(T service) => _services[typeof(T)] = service;
    public static T Get<T>() => (T)_services[typeof(T)];
    public static bool TryGet<T>(out T service)
    {
        if (_services.TryGetValue(typeof(T), out var obj))
        {
            service = (T)obj;
            return true;
        }
        service = default;
        return false;
    }
    public static void Clear() => _services.Clear();
}

// Registration (e.g., in a bootstrap scene)
ServiceLocator.Register<IAudioService>(new AudioService());
ServiceLocator.Register<ISaveService>(new CloudSaveService());

// Usage
ServiceLocator.Get<IAudioService>().PlaySFX("explosion");
```

## Object Pool (Generic, Production-Ready)

```csharp
public class ComponentPool<T> where T : Component
{
    readonly Queue<T> _available = new();
    readonly HashSet<T> _active = new();
    readonly T _prefab;
    readonly Transform _parent;
    readonly int _maxSize;

    public int ActiveCount => _active.Count;
    public int AvailableCount => _available.Count;

    public ComponentPool(T prefab, int preWarm, int maxSize = 1000, Transform parent = null)
    {
        _prefab = prefab;
        _maxSize = maxSize;
        _parent = parent;

        for (int i = 0; i < preWarm; i++)
            _available.Enqueue(CreateNew());
    }

    public T Get(Vector3 position, Quaternion rotation)
    {
        T item;
        if (_available.Count > 0)
        {
            item = _available.Dequeue();
        }
        else if (_active.Count < _maxSize)
        {
            item = CreateNew();
        }
        else
        {
            Debug.LogWarning($"Pool exhausted for {_prefab.name}");
            return null;
        }

        item.transform.SetPositionAndRotation(position, rotation);
        item.gameObject.SetActive(true);
        _active.Add(item);
        return item;
    }

    public void Return(T item)
    {
        if (!_active.Remove(item)) return;
        item.gameObject.SetActive(false);
        _available.Enqueue(item);
    }

    public void ReturnAll()
    {
        foreach (var item in _active)
        {
            item.gameObject.SetActive(false);
            _available.Enqueue(item);
        }
        _active.Clear();
    }

    T CreateNew()
    {
        var item = Object.Instantiate(_prefab, _parent);
        item.gameObject.SetActive(false);
        return item;
    }
}
```

## ECS/DOTS Patterns

### Component Data

```csharp
// Components are pure data structs
public struct MoveSpeed : IComponentData
{
    public float Value;
}

public struct Health : IComponentData
{
    public float Current;
    public float Max;
}

// Tag components (no data, used for filtering)
public struct EnemyTag : IComponentData { }
```

### System (ISystem - Burst Compatible)

```csharp
[BurstCompile]
public partial struct MoveSystem : ISystem
{
    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        float dt = SystemAPI.Time.DeltaTime;

        foreach (var (transform, speed) in
            SystemAPI.Query<RefRW<LocalTransform>, RefRO<MoveSpeed>>())
        {
            transform.ValueRW.Position += new float3(0, 0, speed.ValueRO.Value * dt);
        }
    }
}
```

### Jobs (Parallel Processing)

```csharp
[BurstCompile]
public partial struct DamageJob : IJobEntity
{
    public float DamageAmount;

    void Execute(ref Health health, in EnemyTag tag)
    {
        health.Current -= DamageAmount;
    }
}

// Schedule from a system
public partial struct DamageSystem : ISystem
{
    public void OnUpdate(ref SystemState state)
    {
        var job = new DamageJob { DamageAmount = 10f };
        job.ScheduleParallel();
    }
}
```

### MonoBehaviour to ECS Migration Checklist

1. Identify data (fields) -> `IComponentData` structs
2. Identify logic (Update methods) -> `ISystem` implementations
3. Convert prefabs -> Entity prefabs (SubScene workflow)
4. Replace `GetComponent` -> `SystemAPI.GetComponent`
5. Replace `Instantiate` -> `EntityManager.Instantiate`
6. Use Burst-compatible types (`float3`, `quaternion`, `NativeArray`)
7. Profile to verify the migration provides actual speedup
