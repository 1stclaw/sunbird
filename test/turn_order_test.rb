# frozen_string_literal: true

require_relative "test_helper"

class TurnOrderTest < Minitest::Test
  include SunbirdTestSupport

  def test_controlled_command_is_buffered_before_npc_commands
    world = Sunbird::World.new
    goblin_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 1, y: 2),
      behavior: Sunbird::Component::Behavior.new(kind: :chase),
      combatant: Sunbird::Component::Combatant.new(attack: 1)
    )
    hero_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 2, y: 2)
    )
    world.add_relation(
      kind: :targets,
      source_id: goblin_id,
      target_id: hero_id
    )

    level = level_with(spawns: [])
    commands = Sunbird::TurnPlanner.new.build(
      input: move_input(:move_east),
      level: level,
      world: world.view,
      controlled_id: hero_id
    ).to_a

    assert_instance_of Sunbird::Simulation::Commands::Move, commands.fetch(0)
    assert_equal hero_id, commands.fetch(0).entity_id
    assert_instance_of Sunbird::Simulation::Commands::Attack, commands.fetch(1)
    assert_equal goblin_id, commands.fetch(1).attacker_id
  end

  def test_player_first_execution_can_invalidate_preplanned_adjacent_attack
    level = level_with(
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :hunter,
          prototype: :goblin,
          x: 1,
          y: 2
        )
      ],
      entries: [default_entry(x: 2, y: 2)],
      default_entry: :start,
      relations: [
        Sunbird::Level::Relation.new(
          kind: :targets,
          source: :hunter,
          target: :start
        )
      ]
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    hero_id = simulation.spawn_character(
      character_key: :hero,
      prototype: :player
    )

    commands = Sunbird::TurnPlanner.new.build(
      input: move_input(:move_east),
      level: level,
      world: simulation.world_view,
      controlled_id: hero_id
    )
    result = simulation.step(commands: commands)

    assert_empty result.effects
    position = simulation.world_view.component(hero_id, :position)
    assert_equal [3, 2], [position.x, position.y]
  end
end
