# frozen_string_literal: true

require_relative "test_helper"

class ExecutorSafetyTest < Minitest::Test
  include SunbirdTestSupport

  def test_zero_health_attacker_cannot_execute_later_queued_attack
    world = Sunbird::World.new
    first_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 2, y: 2)
    )
    doomed_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 1, y: 2),
      health: Sunbird::Component::Health.new(current: 1, max: 1)
    )
    victim_id = world.spawn(
      position: Sunbird::Component::Position.new(x: 0, y: 2),
      health: Sunbird::Component::Health.new(current: 5, max: 5)
    )

    commands = Sunbird::Simulation::Commands::Buffer.new([
      Sunbird::Simulation::Commands::Attack.new(
        attacker_id: first_id,
        target_id: doomed_id,
        damage: 1
      ),
      Sunbird::Simulation::Commands::Attack.new(
        attacker_id: doomed_id,
        target_id: victim_id,
        damage: 1
      )
    ])

    Sunbird::Simulation::Executor.new.execute(
      level: level_with(spawns: []),
      world: world,
      commands: commands,
      bindings: Sunbird::Simulation::Bindings.new
    )

    assert_equal 0, world.component(doomed_id, :health).current
    assert_equal 5, world.component(victim_id, :health).current
  end
end
