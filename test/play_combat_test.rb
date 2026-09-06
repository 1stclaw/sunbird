# frozen_string_literal: true

require_relative "test_helper"

class PlayCombatTest < Minitest::Test
  include SunbirdTestSupport

  def test_space_attacks_adjacent_combatant_in_world
    mode, simulation, session, goblin_id = build_play

    result = mode.advance(input: action_input(:attack))

    assert_equal :advanced, result
    assert_equal 1, mode.step_number
    assert_equal 2, simulation.world_view.component(goblin_id, :health).current
    assert_equal 9, session.character(:hero).hp
  end

  def test_second_attack_defeats_goblin_before_its_queued_attack_can_land
    mode, simulation, session, goblin_id = build_play

    mode.advance(input: action_input(:attack))
    result = mode.advance(input: action_input(:attack))

    assert_equal :advanced, result
    assert_equal 2, mode.step_number
    assert_equal 0, simulation.world_view.component(goblin_id, :health).current
    assert_equal 9, session.character(:hero).hp
    assert_nil simulation.world_view.component(goblin_id, :renderable)
    assert_nil simulation.world_view.component(goblin_id, :collision)
    assert_nil simulation.world_view.component(goblin_id, :behavior)
    assert_nil simulation.world_view.component(goblin_id, :combatant)
  end

  def test_attack_without_target_still_consumes_a_world_step
    level = level_with(
      spawns: [],
      entries: [default_entry(x: 2, y: 2, facing: :east)],
      default_entry: :start
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    session = test_session
    simulation.spawn_character(character_key: :hero, prototype: :player)
    mode = Sunbird::Mode::Play.new(
      simulation: simulation,
      session: session,
      player_key: :hero,
      dialogues: dialogue_catalog
    )

    result = mode.advance(input: action_input(:attack))

    assert_equal :advanced, result
    assert_equal 1, mode.step_number
  end

  def test_enter_does_not_start_combat
    mode, simulation, _session, goblin_id = build_play

    result = mode.advance(input: action_input(:interact))

    assert_equal :idle, result
    assert_equal 0, mode.step_number
    assert_equal 4, simulation.world_view.component(goblin_id, :health).current
  end

  private

  def build_play
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
      default_entry: :start,
      relations: [
        Sunbird::Level::Relation.new(
          kind: :targets,
          source: :goblin,
          target: :start
        )
      ]
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    session = test_session
    simulation.spawn_character(character_key: :hero, prototype: :player)
    goblin_id = simulation.entity_id_for_spawn(:goblin)
    mode = Sunbird::Mode::Play.new(
      simulation: simulation,
      session: session,
      player_key: :hero,
      dialogues: dialogue_catalog
    )

    [mode, simulation, session, goblin_id]
  end
end
