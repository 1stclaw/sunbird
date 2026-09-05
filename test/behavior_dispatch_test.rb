# frozen_string_literal: true

require_relative "test_helper"

class BehaviorDispatchTest < Minitest::Test
  include SunbirdTestSupport

  def test_unknown_behavior_kind_raises_argument_error
    prototypes = prototype_catalog(goblin_behavior: :unknown)
    level = level_with(
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :strange,
          prototype: :goblin,
          x: 3,
          y: 2
        )
      ],
      entries: [default_entry(x: 1, y: 2)],
      default_entry: :start
    )
    simulation = Sunbird::Simulation.new(level: level, prototypes: prototypes)
    hero_id = simulation.spawn_character(character_key: :hero, prototype: :player)

    error = assert_raises(ArgumentError) do
      Sunbird::TurnPlanner.new.build(
        input: Sunbird::Input::Snapshot.empty,
        level: level,
        world: simulation.world_view,
        controlled_id: hero_id
      )
    end

    assert_match "unknown behavior", error.message
  end
end
