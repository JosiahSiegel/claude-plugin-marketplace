---
name: unity-networking
description: |
  This skill should be used when the user asks about "Unity multiplayer",
  "Netcode for GameObjects", "NGO", "Mirror networking", "Photon PUN",
  "Photon Fusion", "Fish-Net", "RPC", "ClientRpc", "ServerRpc",
  "NetworkVariable", "network synchronization", "lobby system",
  "matchmaking", "dedicated server", "relay server", "server authoritative",
  "client prediction", "lag compensation", "REST API Unity",
  "WebSocket Unity", "Unity Gaming Services", "UGS", "Firebase Unity",
  "PlayFab", "player authentication", "cloud save", "leaderboard",
  or needs networking and backend integration help for Unity games.
---

# Unity Networking and Multiplayer

## Overview

Reference for implementing multiplayer systems and backend services in Unity. Covers the major networking frameworks, authority models, common multiplayer patterns, and Unity Gaming Services integration.

## Networking Framework Comparison

| Framework | Type | Best For | License |
|-----------|------|----------|---------|
| Netcode for GameObjects (NGO) | Client-hosted / Dedicated | Unity-native projects, UGS integration | Free (Unity) |
| Mirror | Client-hosted / Dedicated | Open-source alternative, mature ecosystem | MIT |
| Photon PUN 2 | Cloud-hosted | Quick prototyping, room-based games | Free tier + paid |
| Photon Fusion 2 | Cloud/Self-hosted | Competitive games, tick-based simulation | Free tier + paid |
| Fish-Net | Client-hosted / Dedicated | Performance-critical, Mirror alternative | MIT |

## Netcode for GameObjects (NGO)

### Setup

1. Install via Package Manager: `com.unity.netcode.gameobjects`
2. Add `NetworkManager` to a scene GameObject
3. Select transport (Unity Transport is default)
4. Mark networked prefabs with `NetworkObject` component
5. Register prefabs in NetworkManager's prefab list

### Core Components

| Component | Purpose |
|-----------|---------|
| `NetworkManager` | Manages connections, spawning, scene management |
| `NetworkObject` | Required on all networked GameObjects |
| `NetworkBehaviour` | Base class for networked scripts (replaces MonoBehaviour) |
| `NetworkVariable<T>` | Synchronized variable with ownership/permissions |
| `NetworkTransform` | Automatic position/rotation sync |
| `NetworkAnimator` | Automatic Animator parameter sync |

### RPCs (Remote Procedure Calls)

```csharp
public class PlayerCombat : NetworkBehaviour
{
    NetworkVariable<int> _health = new(100,
        NetworkVariableReadPermission.Everyone,
        NetworkVariableWritePermission.Server);

    [ServerRpc]
    void AttackServerRpc(ulong targetId)
    {
        // Runs on server - validate and apply damage
        if (!IsServer) return;
        var target = NetworkManager.SpawnManager.SpawnedObjects[targetId];
        target.GetComponent<PlayerCombat>().TakeDamage(10);
    }

    [ClientRpc]
    void PlayHitEffectClientRpc(Vector3 position)
    {
        // Runs on all clients - visual feedback only
        Instantiate(hitVFX, position, Quaternion.identity);
    }

    void TakeDamage(int amount)
    {
        _health.Value -= amount;
        PlayHitEffectClientRpc(transform.position);
    }
}
```

| RPC Type | Direction | Use For |
|----------|-----------|---------|
| `[ServerRpc]` | Client -> Server | Player actions, requests |
| `[ClientRpc]` | Server -> All Clients | VFX, sound, UI updates |
| `[ClientRpc(SendTo.Owner)]` | Server -> Owner Client | Owner-specific feedback |

### NetworkVariable Permissions

```csharp
// Server-writable (default) - authoritative state
NetworkVariable<int> score = new(0, writePerm: NetworkVariableWritePermission.Server);

// Owner-writable - client-authoritative (use sparingly)
NetworkVariable<Vector3> cursorPos = new(writePerm: NetworkVariableWritePermission.Owner);
```

Use `OnValueChanged` callback for UI reactions:
```csharp
_health.OnValueChanged += (oldVal, newVal) => healthBar.value = newVal;
```

## Authority Models

| Model | Description | When to Use |
|-------|-------------|-------------|
| Server-Authoritative | Server validates all actions, clients are thin | Competitive, anti-cheat critical |
| Client-Authoritative | Clients own their state, server relays | Cooperative, trust-based |
| Client Prediction + Server Reconciliation | Client predicts locally, server corrects | FPS, fast-paced action |
| Relay / Listen Server | One player hosts, others connect via relay | Casual, small lobbies |

### Server-Authoritative Flow

```
Client: Press "Attack" -> Send ServerRpc(targetId)
Server: Validate range/cooldown -> Apply damage -> Update NetworkVariable
Server: Send ClientRpc for VFX
All Clients: Play hit effect
```

Never trust client data. Validate positions, cooldowns, ammunition, and line-of-sight on the server.

## Common Multiplayer Patterns

### Lobby System

```
1. Player authenticates (UGS Auth / custom)
2. Player creates or joins lobby (UGS Lobby / custom)
3. Lobby fills -> host starts game
4. Relay allocation for NAT traversal (UGS Relay)
5. All players connect to relay
6. NetworkManager starts host/client
```

### Spawn and Despawn

```csharp
// Server-side spawning
var instance = Instantiate(prefab, spawnPoint, Quaternion.identity);
instance.GetComponent<NetworkObject>().SpawnWithOwnership(clientId);

// Server-side despawning
networkObject.Despawn(); // Removes from all clients
```

### Scene Management

Use `NetworkManager.SceneManager.LoadScene("GameScene", LoadSceneMode.Single)` for synchronized scene loading. Only the server/host should call this.

## REST API and WebSocket Integration

### REST API (UnityWebRequest)

```csharp
async Awaitable<T> GetAsync<T>(string url)
{
    using var request = UnityWebRequest.Get(url);
    request.SetRequestHeader("Authorization", $"Bearer {token}");
    await request.SendWebRequest();
    if (request.result != UnityWebRequest.Result.Success)
        throw new Exception(request.error);
    return JsonUtility.FromJson<T>(request.downloadHandler.text);
}
```

Use `JsonUtility` for simple types or Newtonsoft.Json (`com.unity.nuget.newtonsoft-json`) for complex serialization. Always use `using` with UnityWebRequest to prevent memory leaks.

### WebSocket (NativeWebSocket / WebSocketSharp)

For real-time non-game communication (chat, notifications), use a WebSocket library. NativeWebSocket works across platforms including WebGL.

## Unity Gaming Services (UGS)

| Service | Package | Purpose |
|---------|---------|---------|
| Authentication | `com.unity.services.authentication` | Anonymous/platform sign-in |
| Lobby | `com.unity.services.lobby` | Room creation, matchmaking |
| Relay | `com.unity.services.relay` | NAT traversal for P2P |
| Cloud Save | `com.unity.services.cloudsave` | Server-side player data |
| Leaderboards | `com.unity.services.leaderboards` | Ranked scoreboards |
| Economy | `com.unity.services.economy` | Virtual currencies, purchases |
| Analytics | `com.unity.services.analytics` | Player behavior tracking |
| Matchmaker | `com.unity.services.matchmaker` | Skill-based matchmaking |

Initialize UGS before using any service:
```csharp
await UnityServices.InitializeAsync();
await AuthenticationService.Instance.SignInAnonymouslyAsync();
```

## Firebase and PlayFab

Use Firebase for indie/mobile projects needing Realtime Database, Cloud Functions, and FCM push notifications. Use PlayFab for LiveOps-heavy games needing player segmentation, A/B testing, and automated rule processing. Both provide Unity SDKs via their respective download pages.

## Additional Resources

### Reference Files
- **`references/netcode-advanced.md`** -- Client prediction and reconciliation implementation, interest management, network LOD, bandwidth optimization, custom serialization, transport layer configuration
- **`references/backend-services.md`** -- Detailed UGS setup walkthroughs, Firebase/PlayFab integration patterns, REST API architecture, authentication flows, leaderboard and economy implementation
