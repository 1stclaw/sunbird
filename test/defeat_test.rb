# frozen_string_literal: true

require_relative "test_helper"

class DefeatTest < Minitest::Test
  def setup
    @level = Sunbird::Level.new(
      name: :test,
      terrain: Sunbird::Level::Terrain.new(width: 5, height: 5),
      spawns: [],
      relations: []
    )
    @executor = Sunbird::Simulation::Executor.new
    @bindings = Sunbird::Simulation::Bindings.new
  end

  def test_defeat_retires_zero_health_entity
    world = Sunbird::World.new
    entity_id = world.spawn(
      health: Sunbird::Component::Health.new(current: 0, max: 4),
      position: Sunbird::Component::Position.new(x: 2, y: 2),
      renderable: Sunbird::Component::Renderable.new(
        render_key: :goblin, glyph: "G", layer: 10
      ),
      behavior: Sunbird::Component::Behavior.new(kind: :chase),
      collision: Sunbird::Component::Collision.new(blocks_movement: true),
      combatant: Sunbird::Component::Combatant.new(attack: 1)
    )

    execute(world, Sunbird::Simulation::Commands::Defeat.new(entity_id: entity_id))

    assert_nil world.component(entity_id, :renderable)
    assert_nil world.component(entity_id, :behavior)
    assert_nil world.component(entity_id, :collision)
    assert_nil world.component(entity_id, :combatant)
    assert_equal 0, world.component(entity_id, :health).current
    assert world.component(entity_id, :position)
  end

  def test_defeat_does_nothing_while_health_is_positive
    world = Sunbird::World.new
    entity_id = world.spawn(
      health: Sunbird::Component::Health.new(current: 1, max: 4),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )

    execute(world, Sunbird::Simulation::Commands::Defeat.new(entity_id: entity_id))
    assert world.component(entity_id, :collision)
  end

  private

  def execute(world, command)
    @executor.execute(
      world: world,
      level: @level,
      bindings: @bindings,
      commands: Sunbird::Simulation::Commands::Buffer.new([command])
    )
  end
end
