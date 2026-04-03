# Physics, Animation, and Audio - Detailed Reference

## Physics Setup (3D)

### Rigidbody Configuration

| Property | Default | Guidelines |
|----------|---------|-----------|
| Mass | 1 | Use realistic ratios (player: 70, crate: 20, bullet: 0.01) |
| Drag | 0 | Increase for floating/hovering feel |
| Angular Drag | 0.05 | Increase to prevent endless spinning |
| Interpolate | None | Set to Interpolate for player-controlled objects to smooth rendering |
| Collision Detection | Discrete | Use Continuous for fast-moving objects (bullets) |
| Constraints | None | Freeze rotation axes for characters to prevent tipping |

### Collider Types

| Collider | Performance | Use For |
|----------|-------------|---------|
| Box | Fastest | Crates, walls, doors |
| Sphere | Very Fast | Pickups, triggers, characters (capsule for tall) |
| Capsule | Fast | Characters, humanoids |
| Mesh (Convex) | Moderate | Irregularly shaped props (max 255 tris) |
| Mesh (Non-Convex) | Slow | Static environment only (not on Rigidbody) |
| Terrain | Moderate | Terrain Collider component on Terrain objects |

### Physics Layers and Matrix

Configure collision layers in Edit > Project Settings > Physics:

```
Layer 8:  Player
Layer 9:  Enemy
Layer 10: Projectile
Layer 11: Environment
Layer 12: Trigger
Layer 13: Ragdoll
```

Disable unnecessary collisions in the matrix (e.g., Projectile vs. Projectile, Ragdoll vs. Trigger).

### Joint Types

| Joint | Use For | Key Settings |
|-------|---------|-------------|
| Fixed | Welding objects together | Break force/torque |
| Hinge | Doors, wheels, pendulums | Axis, limits, motor |
| Spring | Suspension, bouncy connections | Spring force, damper |
| Configurable | Complex constraints | Per-axis freedom control |
| Character | Player joints in ragdolls | Swing/twist limits |

### Advanced Raycasting

```csharp
// SphereCast for wider hit detection (e.g., aim assist)
if (Physics.SphereCast(origin, radius, direction, out RaycastHit hit, maxDistance, layerMask))
{
    // hit.point, hit.normal, hit.collider
}

// OverlapSphere for area detection
Collider[] results = new Collider[32]; // Pre-allocate
int count = Physics.OverlapSphereNonAlloc(center, radius, results, layerMask);
for (int i = 0; i < count; i++)
    ProcessTarget(results[i]);

// BoxCast for rectangular sweeps (melee attacks)
if (Physics.BoxCast(center, halfExtents, direction, out RaycastHit hit, orientation, maxDistance))
    ApplyDamage(hit.collider);
```

Always use `NonAlloc` variants in hot paths to avoid GC allocation.

## Physics 2D

2D physics uses separate components: `Rigidbody2D`, `BoxCollider2D`, `CircleCollider2D`, `CapsuleCollider2D`, `CompositeCollider2D`, `PolygonCollider2D`.

### Key Differences from 3D

| Aspect | 3D | 2D |
|--------|----|----|
| Gravity | `Physics.gravity` (Vector3) | `Physics2D.gravity` (Vector2) |
| Rigidbody type | Dynamic/Kinematic/Static | Dynamic/Kinematic/Static |
| Collider shapes | Box, Sphere, Capsule, Mesh | Box, Circle, Capsule, Polygon, Edge, Composite |
| Callbacks | `OnCollisionEnter(Collision)` | `OnCollisionEnter2D(Collision2D)` |
| Raycasting | `Physics.Raycast` | `Physics2D.Raycast` |
| Layers | Same layer system | Same layer system |

### 2D Rigidbody Types

| Type | Use For |
|------|---------|
| Dynamic | Physics-driven movement (enemies, projectiles) |
| Kinematic | Script-driven movement (platforms, players in some designs) |
| Static | Immovable environment (walls, ground) -- no Rigidbody2D needed, just collider |

### 2D-Specific Patterns

```csharp
// Ground check for platformers
bool IsGrounded()
{
    return Physics2D.BoxCast(
        collider.bounds.center,
        collider.bounds.size,
        0f,
        Vector2.down,
        0.1f,
        groundLayerMask
    ).collider != null;
}

// One-way platforms
// Use PlatformEffector2D component with "Use One Way" enabled

// Composite Collider for tilemaps
// Add CompositeCollider2D + Rigidbody2D(Static) to tilemap object
// Set TilemapCollider2D "Used By Composite" = true
```

## Animation System

### Animator Controller Structure

```
Animator Controller
├── Layers
│   ├── Base Layer (weight: 1.0)
│   │   ├── States: Idle, Walk, Run, Jump
│   │   ├── Transitions (with conditions)
│   │   └── Blend Tree (Walk/Run based on Speed)
│   └── Upper Body Layer (weight: 0.7, override)
│       ├── States: Idle, Attack, Block
│       └── Avatar Mask: Upper Body only
├── Parameters
│   ├── Speed (Float)
│   ├── IsGrounded (Bool)
│   ├── Jump (Trigger)
│   └── AttackIndex (Int)
└── Sub-State Machines
    └── Combat (groups Attack, Block, Dodge states)
```

### Blend Trees

| Type | Axes | Use For |
|------|------|---------|
| 1D | Speed | Walk/Run blend |
| 2D Simple Directional | X, Y | 4-directional locomotion |
| 2D Freeform Directional | X, Y | 8+ directional locomotion |
| 2D Freeform Cartesian | X, Y | Complex parameter combinations |
| Direct | Multiple | Face blendshape control |

### Transition Settings

| Setting | Default | Recommendation |
|---------|---------|----------------|
| Has Exit Time | true | Disable for responsive gameplay |
| Exit Time | 0.75 | Set to last frame if using exit time |
| Transition Duration | 0.25s | 0.1-0.15s for responsive, 0.2-0.3s for smooth |
| Transition Offset | 0 | Non-zero to start mid-animation |
| Interruption Source | None | Current State for interruptible attacks |

### Animation Events

```csharp
// Called from Animation Event in the clip
public void OnFootstep()
{
    audioSource.PlayOneShot(footstepClips[Random.Range(0, footstepClips.Length)]);
}

public void OnAttackHit()
{
    // Enable hit detection for this frame
    weaponCollider.enabled = true;
}

public void OnAttackEnd()
{
    weaponCollider.enabled = false;
}
```

Animation Events fire at specific frame timestamps. Use for gameplay-critical moments (hit frames, footsteps, spell cast points).

### Inverse Kinematics (IK)

```csharp
void OnAnimatorIK(int layerIndex)
{
    if (lookTarget != null)
    {
        animator.SetLookAtWeight(1f, 0.3f, 0.6f, 1f, 0.5f);
        animator.SetLookAtPosition(lookTarget.position);
    }

    if (rightHandTarget != null)
    {
        animator.SetIKPositionWeight(AvatarIKGoal.RightHand, 1f);
        animator.SetIKRotationWeight(AvatarIKGoal.RightHand, 1f);
        animator.SetIKPosition(AvatarIKGoal.RightHand, rightHandTarget.position);
        animator.SetIKRotation(AvatarIKGoal.RightHand, rightHandTarget.rotation);
    }
}
```

Use IK for: hand placement on weapons/ledges, foot placement on uneven terrain, head look-at targets. For complex rigs, use the Animation Rigging package.

### Root Motion

Enable "Apply Root Motion" on Animator for animation-driven movement. The `OnAnimatorMove()` callback gives full control:

```csharp
void OnAnimatorMove()
{
    // Apply root motion through CharacterController or Rigidbody
    Vector3 deltaPosition = animator.deltaPosition;
    characterController.Move(deltaPosition);
    transform.rotation *= animator.deltaRotation;
}
```

## Audio Architecture

### Audio Hierarchy

```
Scene
├── AudioListener (on Main Camera)
├── Music Manager (DontDestroyOnLoad)
│   ├── AudioSource (Music Track A)
│   └── AudioSource (Music Track B) -- for crossfading
├── Ambient Manager
│   └── AudioSource (ambient loops)
└── SFX (on game objects)
    ├── Player AudioSource
    ├── Enemy AudioSources
    └── Environment AudioSources
```

### AudioMixer Setup

```
Master Mixer
├── Music Group
│   └── Volume exposed as "MusicVolume"
├── SFX Group
│   ├── Weapons subgroup
│   ├── Footsteps subgroup
│   └── UI subgroup
└── Ambient Group
    └── Volume exposed as "AmbientVolume"
```

Expose parameters for volume sliders:
```csharp
// Set mixer volume (logarithmic scale)
public void SetMusicVolume(float linearValue)
{
    float dbValue = linearValue > 0.001f ? Mathf.Log10(linearValue) * 20f : -80f;
    audioMixer.SetFloat("MusicVolume", dbValue);
}
```

### Mixer Snapshots

Create snapshots for different game states:
- **Default:** Normal mix
- **Combat:** Lower music, boost SFX
- **Paused:** Duck all, slight reverb
- **Underwater:** Low-pass filter, muffled

```csharp
combatSnapshot.TransitionTo(0.5f); // Blend over 0.5 seconds
```

### Spatial Audio

```csharp
// 3D sound setup
AudioSource source = GetComponent<AudioSource>();
source.spatialBlend = 1f;          // Full 3D
source.rolloffMode = AudioRolloffMode.Custom;
source.maxDistance = 50f;
source.minDistance = 1f;
source.dopplerLevel = 0f;          // Usually disable for games
```

### Audio Clip Import Settings

| Setting | Music | SFX (Short) | SFX (Long) | Voice |
|---------|-------|-------------|------------|-------|
| Load Type | Streaming | Decompress On Load | Compressed In Memory | Compressed In Memory |
| Compression | Vorbis | PCM or ADPCM | Vorbis | Vorbis |
| Sample Rate | 44100 | 22050-44100 | 44100 | 22050 |
| Channels | Stereo | Mono (3D) | Mono (3D) | Mono |

### Music Crossfade

```csharp
public class MusicManager : MonoBehaviour
{
    [SerializeField] AudioSource sourceA, sourceB;
    AudioSource _current;

    public async Awaitable CrossfadeTo(AudioClip newClip, float duration = 1f)
    {
        var next = _current == sourceA ? sourceB : sourceA;
        next.clip = newClip;
        next.volume = 0f;
        next.Play();

        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = elapsed / duration;
            _current.volume = 1f - t;
            next.volume = t;
            await Awaitable.NextFrameAsync();
        }

        _current.Stop();
        _current = next;
    }
}
```

## NavMesh and Pathfinding

### Setup

1. Mark walkable surfaces as Navigation Static
2. Open Navigation window (Window > AI > Navigation)
3. Bake NavMesh with appropriate agent radius/height
4. Add `NavMeshAgent` component to moving entities

### Agent Configuration

| Property | Purpose | Typical Values |
|----------|---------|---------------|
| Speed | Movement speed | 3.5 (walk), 6 (run) |
| Angular Speed | Turn rate | 120-360 deg/s |
| Acceleration | Speed ramp-up | 8-12 |
| Stopping Distance | Stop before target | 0.5-2 units |
| Auto Braking | Slow near destination | true for patrol, false for chase |
| Obstacle Avoidance | Quality level | Medium for most, High for player |
| Area Mask | Walkable areas | Configure per-agent type |

### NavMesh Scripting

```csharp
NavMeshAgent agent = GetComponent<NavMeshAgent>();

// Move to target
agent.SetDestination(targetPosition);

// Check if arrived
bool hasArrived = !agent.pathPending && agent.remainingDistance <= agent.stoppingDistance;

// Off-mesh links (jumping, climbing)
if (agent.isOnOffMeshLink)
{
    // Custom animation/movement over the link
    await AnimateOffMeshLink(agent);
    agent.CompleteOffMeshLink();
}

// Dynamic obstacles
// Use NavMeshObstacle on moving objects that block paths
// Set Carve = true for reliable blocking
```

### NavMesh for 2D

Unity's NavMesh is 3D-only. For 2D pathfinding, use:
- **NavMeshPlus** (community package) -- adapts Unity NavMesh for 2D
- **A* Pathfinding Project** (Aron Granberg) -- popular third-party solution
- Custom A* on a grid -- for tile-based games
