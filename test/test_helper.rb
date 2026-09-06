# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(
  File.expand_path("../lib", __dir__)
)

require "sunbird"

module SunbirdTestPaths
  PROTOTYPE_PATH = File.expand_path(
    "../content/prototypes/actors.rb",
    __dir__
  )

  LEVEL_PATH = File.expand_path(
    "../content/levels/test_field.rb",
    __dir__
  )

  DIALOGUE_PATH = File.expand_path(
    "../content/dialogue/test_field.rb",
    __dir__
  )
end

module SunbirdTestSupport
  def prototype_catalog(goblin_behavior: :chase)
    player = Sunbird::Prototype.new(
      name: :player,
      components: {
        collision: Sunbird::Component::Collision.new(
          blocks_movement: true
        )
      }.freeze
    )

    goblin = Sunbird::Prototype.new(
      name: :goblin,
      components: {
        health: Sunbird::Component::Health.new(
          current: 4,
          max: 4
        ),
        behavior: Sunbird::Component::Behavior.new(
          kind: goblin_behavior
        ),
        collision: Sunbird::Component::Collision.new(
          blocks_movement: true
        ),
        combatant: Sunbird::Component::Combatant.new(
          attack: 1
        )
      }.freeze
    )

    villager = Sunbird::Prototype.new(
      name: :villager,
      components: {
        collision: Sunbird::Component::Collision.new(
          blocks_movement: true
        ),
        interactable: Sunbird::Component::Interactable.new(
          dialogue_key: :village_greeting
        )
      }.freeze
    )

    Sunbird::Prototype::Catalog.new([player, goblin, villager])
  end

  def dialogue_catalog
    Sunbird::Dialogue::Catalog.new(
      village_greeting: [
        "First line.",
        "Second line."
      ]
    )
  end

  def test_session
    Sunbird::Session.new(
      characters: {
        hero: Sunbird::Character.new(
          hp: 10,
          max_hp: 10,
          mp: 4,
          max_mp: 4,
          attack: 2
        ),
        mage: Sunbird::Character.new(
          hp: 8,
          max_hp: 8,
          mp: 8,
          max_mp: 8,
          attack: 1
        )
      }
    )
  end

  def level_with(
    width: 7,
    height: 7,
    spawns:,
    relations: [],
    entries: [],
    default_entry: nil
  )
    Sunbird::Level.new(
      name: :test,
      terrain: Sunbird::Level::Terrain.new(
        width: width,
        height: height
      ),
      spawns: spawns,
      entries: entries,
      relations: relations,
      default_entry: default_entry
    )
  end

  def default_entry(x: 2, y: 2, key: :start, facing: :south)
    Sunbird::Level::Entry.new(
      key: key,
      x: x,
      y: y,
      facing: facing
    )
  end

  def action_input(kind)
    Sunbird::Input::Snapshot.from(
      [
        Sunbird::Input::Action.new(
          kind: kind,
          state: :pressed
        )
      ]
    )
  end

  def move_input(kind)
    action_input(kind)
  end

  def spawn_character(
    simulation,
    session,
    character_key: :hero,
    prototype: :player,
    entry: simulation.level.default_entry
  )
    simulation.spawn_character(
      character_key: character_key,
      prototype: prototype,
      entry: entry
    )
  end

  def advance_simulation(
    simulation,
    input,
    controlled_id:,
    planner: Sunbird::TurnPlanner.new
  )
    commands = planner.build(
      input: input,
      level: simulation.level,
      world: simulation.world_view,
      controlled_id: controlled_id
    )
    simulation.step(commands: commands)
  end

  def entity_id_for(simulation, prototype_name)
    simulation.world_view.entity_ids.find do |entity_id|
      ref = simulation.world_view.component(
        entity_id,
        :prototype_ref
      )
      ref&.name == prototype_name
    end
  end
end
