# frozen_string_literal: true

require_relative "test_helper"

class SimulationStepTest < Minitest::Test
  include SunbirdTestSupport

  def setup
    level = level_with(
      spawns: [],
      entries: [default_entry(x: 2, y: 2)],
      default_entry: :start
    )
    @simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    @hero_id = @simulation.spawn_character(
      character_key: :hero,
      prototype: :player
    )
  end

  def test_step_returns_explicit_result
    commands = Sunbird::Simulation::Commands::Buffer.new([
      Sunbird::Simulation::Commands::Move.new(
        entity_id: @hero_id,
        dx: 1,
        dy: 0
      )
    ])

    result = @simulation.step(commands: commands)
    position = @simulation.world_view.component(@hero_id, :position)

    assert_instance_of Sunbird::Simulation::StepResult, result
    assert_equal 1, result.number
    assert_empty result.effects
    assert_equal [3, 2], [position.x, position.y]
  end

  def test_step_returns_persistent_effects
    enemy_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 3, y: 2)
    )
    commands = Sunbird::Simulation::Commands::Buffer.new([
      Sunbird::Simulation::Commands::Attack.new(
        attacker_id: enemy_id,
        target_id: @hero_id,
        damage: 1
      )
    ])

    result = @simulation.step(commands: commands)

    assert_equal 1, result.number
    assert_equal 1, result.effects.length
    assert_instance_of Sunbird::Effect::DamageCharacter, result.effects.first
    assert_equal :hero, result.effects.first.character_key
  end

  def test_planning_is_outside_simulation_and_does_not_advance_world
    planner = Sunbird::TurnPlanner.new
    commands = planner.build(
      input: move_input(:move_east),
      level: @simulation.level,
      world: @simulation.world_view,
      controlled_id: @hero_id
    )
    position = @simulation.world_view.component(@hero_id, :position)

    assert_equal 1, commands.size
    assert_equal [2, 2], [position.x, position.y]
    assert_equal 0, @simulation.step_number
    refute_respond_to @simulation, :plan
  end

  def test_world_view_has_no_mutation_api
    refute_respond_to @simulation.world_view, :set_component
  end

  private

  def world
    @simulation.instance_variable_get(:@world)
  end
end
