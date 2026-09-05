# frozen_string_literal: true

require_relative "test_helper"

class ExplorationBattleTest < Minitest::Test
  include SunbirdTestSupport

  def test_interacting_with_adjacent_combatant_pushes_battle
    level = level_with(
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :goblin,
          prototype: :goblin,
          x: 3,
          y: 2
        )
      ],
      entries: [default_entry(x: 2, y: 2, facing: :east)],
      default_entry: :start
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    session = test_session
    simulation.spawn_character(
      character_key: :hero,
      prototype: :player
    )
    mode = Sunbird::Mode::Exploration.new(
      simulation: simulation,
      session: session,
      dialogues: dialogue_catalog
    )

    before = mode.step_number
    result = mode.advance(input: action_input(:interact))

    assert_instance_of Sunbird::Mode::Push, result
    assert_instance_of Sunbird::Mode::Battle, result.mode
    assert_equal before, mode.step_number
  end
end
