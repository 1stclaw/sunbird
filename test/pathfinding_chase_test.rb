# frozen_string_literal: true

require_relative "test_helper"

class PathfindingChaseTest < Minitest::Test
  include SunbirdTestSupport

  def test_chaser_routes_around_blocking_entity
    level = level_with(
      width: 8,
      height: 6,
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :hunter,
          prototype: :goblin,
          x: 1,
          y: 2
        ),
        Sunbird::Level::Spawn.new(
          key: :blocker,
          prototype: :villager,
          x: 2,
          y: 2
        )
      ],
      entries: [default_entry(x: 5, y: 2)],
      default_entry: :start,
      relations: [
        Sunbird::Level::Relation.new(
          kind: :targets,
          source: :hunter,
          target: :start
        )
      ]
    )
    simulation = Sunbird::Simulation.new(level: level, prototypes: prototype_catalog)
    hero_id = simulation.spawn_character(character_key: :hero, prototype: :player)
    hunter_id = simulation.entity_id_for_spawn(:hunter)

    commands = Sunbird::TurnPlanner.new.build(
      input: Sunbird::Input::Snapshot.empty,
      level: level,
      world: simulation.world_view,
      controlled_id: hero_id
    )
    simulation.step(commands: commands)

    position = simulation.world_view.component(hunter_id, :position)
    refute_equal [2, 2], [position.x, position.y]
    assert_equal 1, (position.x - 1).abs + (position.y - 2).abs
  end
end
