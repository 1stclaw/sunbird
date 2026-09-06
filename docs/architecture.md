# Sunbird v0.4 Development Architecture

This document describes the architecture on `v0.4-next` after the common-foundation cleanup. It is intentionally different from the frozen v0.3d model.

## Design objective

v0.4 removes transitional compatibility abstractions and establishes a small runtime vocabulary that can support both the primary JRPG-oriented line and the later `v0.4-solo` action-RPG line.

The main lifetime split is:

```text
persistent                    authored                     runtime
──────────────────            ──────────────────           ──────────────────
Session                       Level                        Simulation
└── Characters                ├── Terrain                  ├── World
    └── Character             ├── Spawns                   ├── bindings
                              ├── Entries                  ├── Executor
Party (optional)              └── Relations                └── step number
```

## World

`World` is the canonical mutable runtime container.

It owns:

- integer EntityIds;
- component tables;
- runtime relations;
- a read-only `World::View`.

It does not own persistent Character state.

The old v0.4 experimental `AreaState` name has been removed rather than kept as a compatibility alias. v0.3d already preserves the historical API.

## Components

Component schemas are independent of World storage and live under `Component`:

```text
Component::PrototypeRef
Component::Position
Component::Health
Component::Renderable
Component::Behavior
Component::Collision
Component::Facing
Component::Interactable
Component::Combatant
```

This prevents component type names from changing when the storage container is renamed or reorganized.

## Prototype and EntityId

`Prototype` is an authored reusable component recipe.

```text
Prototype :goblin
├── Health
├── Renderable
├── Behavior
├── Collision
└── Combatant
```

A runtime entity is identified only by an integer EntityId.

```text
Prototype
   |
   | instantiate
   v
World EntityId
```

The earlier authored `Entity` name was removed because it conflicted with common ECS/game-engine terminology, where an entity normally means a runtime object/identity.

`Prototype::Catalog` and `Prototype::Loader` replace the old Entity catalog/loader.

## Level

A Level is immutable authored structure:

```text
Level
├── Terrain
├── Spawn
├── Entry
└── Relation
```

A `Spawn` contains:

```text
key
prototype
x
y
```

An `Entry` contains:

```text
key
x
y
facing
```

Entries are authored reference points for persistent characters entering the Level. The player is no longer represented by a static Level spawn.

Relations can reference either spawn keys or entry keys. Simulation resolves them when both endpoints have runtime EntityIds. This allows a relation such as a goblin targeting `:start` to resolve after the persistent player Character is spawned into that entry.

## Session and Character

Session is the persistent game-lifetime root.

The current persistent RPG value is intentionally flat:

```text
Character
├── hp
├── max_hp
├── mp
├── max_mp
└── attack
```

This replaces the temporary hierarchy:

```text
ActorState
├── Vitals
└── Stats
```

The hierarchy can be reintroduced later if real systems justify separate stat/vital objects.

Session owns Characters by stable key:

```text
:hero -> Character
:mage -> Character
```

`Party` remains optional gameplay policy and only references stable Character keys.

## Simulation bindings

Simulation owns the mapping between persistent Character keys and runtime EntityIds.

```text
:hero <-> EntityId 7
```

The relationship exists in one place: `Simulation::Bindings`.

There is no `ActorRef` component and no separate `ActorBindings` object owned by Exploration.

Bindings never live in Session because EntityIds are local to a running Simulation.

## Simulation

Simulation owns the currently running Level state:

```text
Simulation
├── Level
├── World
├── Bindings
├── Executor
└── step_number
```

It does **not** own the turn planner.

Its primary mutation API is:

```text
Simulation#step(commands:) -> StepResult
```

`StepResult` contains:

```text
number
persistent effects
```

This removes the v0.3-compatible convention where `step` returned the step number while yielding effects through a block.

## Commands::Buffer

`Simulation::Commands::Buffer` is deliberately retained.

```text
Commands::Buffer
├── Move
├── Attack
└── Defeat
```

The Buffer remains the explicit batch boundary between command production and execution. This is useful for later scheduling, inspection, recording, validation, Rust porting, or command batching even though the current implementation wraps a frozen Ruby Array.

The v0.4 cleanup therefore does **not** replace it with a plain array.

## Executor

`Simulation::Executor` replaces `Simulation::Resolver`.

Executor:

- receives a Commands::Buffer;
- checks command legality that belongs to runtime execution;
- mutates World;
- emits persistent Effect values when a command targets a bound Character.

Current examples:

```text
Attack local goblin
  -> mutate Component::Health in World

Attack bound player entity
  -> Effect::DamageCharacter(:hero, amount)
```

The term Executor better matches the current behavior: attack damage is already supplied by the command producer, so this object is not yet a general gameplay-rules resolver.

## TurnPlanner

The current turn-oriented command producer is `TurnPlanner`.

It is outside Simulation ownership because it contains gameplay policy:

- controlled movement from abstract input;
- idle/wander/chase behavior;
- pathfinding decisions;
- adjacent NPC attack intent.

This makes the shared runtime usable by a later solo branch with a different control/scheduling policy.

The chase path now reads `Component::Combatant#attack` instead of hardcoding damage `1`, so exploration and BattleMode use the same authored attack value.

## Modes

Modes reference Simulation directly rather than delegating runtime access through a parent mode.

```text
Exploration
├── Simulation
├── Session
├── TurnPlanner
└── Dialogue catalog

Dialogue
└── Simulation

Battle
├── Simulation
├── Session
├── player Character key
└── enemy EntityId
```

The ModeStack still owns push/pop transitions. A pushed mode does not need an object-level pointer back to the previous mode merely to access Level/World/step state.

## Rendering

Projection consumes canonical runtime terminology:

```text
Level + World::View
        |
        v
Render::Projector
        |
        v
Render::Scene
├── Tile
└── Entity(entity_id, ...)
```

Kitty remains the active runtime renderer. ASCII and the current selector are left in place during this refactor because renderer replacement is independent from state/runtime cleanup.

## Shared versus branch-specific

Shared v0.4 substrate:

```text
Session
Character
Level
Prototype
World
EntityId
Components
Simulation
Bindings
Commands::Buffer
Executor
Effects
Render::Scene
Host/Input foundations
```

Primary JRPG line:

```text
Party
TurnPlanner
Exploration
Dialogue
Battle
```

Future `v0.4-solo` line can reuse the shared substrate while replacing the turn/mode policy with direct action/realtime systems.

## Deliberately deferred

- general Intent -> Rules -> Effects architecture;
- realtime/fixed-step scheduling;
- weapons/projectiles;
- inventory/equipment;
- save serialization;
- persistent map changes;
- Raylib;
- Lua;
- generic ECS System/Manager abstractions.
