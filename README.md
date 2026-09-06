# Sunbird

Sunbird is an experimental Ruby game-runtime project for testing small, explicit, data-oriented engine architecture.

The latest released line is **v0.3d**. This branch is `v0.4-solo`, the single-character action-RPG experiment built from the common v0.4 runtime foundation. Its gameplay direction is closer to the Heretic/Hexen lineage than to the primary JRPG-oriented Sunbird line.

The solo branch now has a fixed-step timing/input spike: combat remains grid-based and direct in the map, while a 30 Hz engine clock advances the World independently of keyboard activity. Kitty press/repeat/release events provide real held-key state.

The v0.4 work is deliberately renderer-independent. Kitty remains the active presentation backend; Raylib can be introduced later without defining the architecture version.

## v0.4 vocabulary

The current development model uses a smaller set of conventional terms:

```text
Session
  persistent game state
  └── Characters

Level
  immutable authored map/area definition
  ├── Terrain
  ├── Spawns
  ├── Entries
  └── authored Relations

Simulation
  currently running Level
  ├── World
  ├── persistent-character bindings
  ├── Executor
  └── step counter

World
  mutable runtime entities/components/relations
```

Important terminology:

- `Prototype` — authored reusable component recipe.
- `EntityId` — integer runtime identity. It is represented by a Ruby `Integer`, not a wrapper object.
- `Component::*` — runtime component value types.
- `Character` — persistent RPG character state such as HP, MP, and attack.
- `Simulation::Commands::Buffer` — explicit batch of gameplay commands; deliberately retained in v0.4.
- `Simulation::Executor` — validates/applies commands to the World and emits persistent effects.
- `Simulation::StepResult` — explicit result containing the new step number and emitted effects.
- `RealtimeController` — solo command producer that schedules held player movement and NPC behavior on explicit fixed-tick cadences.
- `Input::Tracker` — converts key press/repeat/release events into held and edge-triggered per-tick input state.

## Persistent and runtime identity

A persistent character and its current runtime entity are different things:

```text
Session Character :player
        |
        | Simulation binding
        v
World EntityId 7
```

Session never stores `EntityId` as character identity.

A Level also no longer authors the persistent player as a normal spawn. It provides an entry marker; Simulation instantiates a player `Prototype` there and binds it to the persistent Character.

## Commands and effects

The current transition path is:

```text
RealtimeController / Mode
        |
        v
Simulation::Commands::Buffer
        |
        v
Simulation::Executor
        |
        +--> World mutation
        |
        `--> persistent Effect values
                 |
                 v
              Session
```

For example, a goblin attacking a bound player entity emits `Effect::DamageCharacter`; a player attacking a local goblin directly changes the goblin's World `Health` component.

`Simulation#step` returns a `Simulation::StepResult` rather than returning one value while yielding another:

```ruby
result = simulation.step(commands: commands)
session.apply_effects(result.effects)
result.number
```

## Authored content

Ruby-authored prototype content currently lives under:

```text
content/prototypes/
content/levels/
content/dialogue/
```

A Level spawn references a prototype:

```text
Spawn
  key
  prototype
  x
  y
```

Persistent characters enter through `Level::Entry` rather than a player spawn.

## Solo controls

```text
WASD / arrows  move
Space          attack the adjacent entity you are facing
Enter          interact / advance dialogue
Esc / Q        quit or cancel the active dialogue
```

Space remains edge-triggered, while movement is held-state driven. The World advances at 30 fixed ticks/second even with no input; player grid movement currently repeats at 5 moves/second and NPC behavior at 2 actions/second.

## Rendering

Rendering remains separated from simulation:

```text
Level + World::View
        |
        v
Render::Projector
        |
        v
Render::Scene
        |
        v
Render::Kitty
```

`Render::Scene::Entity` uses the same `entity_id` runtime terminology as World.

The ASCII renderer remains inactive reference code for now; the preserved v0.3a history contains the earlier dual-renderer runtime.

## Requirements

- Ruby 3.2+
- Kitty graphics protocol support for the active runtime path

Install dependencies:

```sh
bundle install
```

Run:

```sh
bundle exec ruby bin/sunbird
```

Run the tests:

```sh
bundle exec ruby -Itest -e \
'Dir["test/*_test.rb"].sort.each { |file| require_relative file }'
```

## Current v0.4 boundary

The common foundation intentionally does **not** yet define:

- continuous movement/geometry;
- attack windup/active/recovery;
- a general Intent -> Rules -> Effects framework;
- inventory/equipment/spells;
- persistent per-level changes;
- save serialization;
- Raylib;
- Lua;
- a generic ECS `System` layer.

The solo branch has now diverged at both gameplay policy and scheduling. The next milestone is richer real-time action timing (attack phases/cooldowns and a first projectile or spell) while keeping integer grid geometry.
