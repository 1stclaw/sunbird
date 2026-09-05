# Sunbird

Sunbird is an experimental Ruby game-runtime project for testing small, explicit, data-oriented engine architecture.

The latest released line is **v0.3d**. Development on `v0.4-next` is a structural cleanup intended to become the common runtime foundation for two later gameplay directions:

- the primary party/JRPG-oriented Sunbird line;
- a `v0.4-solo` line for a single-character action-RPG direction closer to the Heretic/Hexen lineage.

The v0.4 work is deliberately renderer-independent. Kitty remains the active presentation backend; Raylib can be introduced later without defining the architecture version.

## v0.4 vocabulary

The current development model uses a smaller set of conventional terms:

```text
Session
  persistent game state
  ├── Characters
  └── Party (optional gameplay policy)

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
- `TurnPlanner` — current JRPG/turn-oriented command producer. It is no longer owned by Simulation.

## Persistent and runtime identity

A persistent character and its current runtime entity are different things:

```text
Session Character :hero
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
TurnPlanner / Mode
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

- the `v0.4-solo` realtime/play-loop policy;
- a general Intent -> Rules -> Effects framework;
- inventory/equipment/spells;
- persistent per-level changes;
- save serialization;
- Raylib;
- Lua;
- a generic ECS `System` layer.

The next branch split should happen only after this lower state/runtime model is accepted.
