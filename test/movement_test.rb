# frozen_string_literal: true

require_relative "test_helper"

class MovementTest < Minitest::Test
  def test_blocking_entity_makes_cell_untraversable
    level = Sunbird::Level.new(
      name: :test,
      terrain: Sunbird::Level::Terrain.new(width: 5, height: 5),
      spawns: [],
      relations: []
    )
    world = Sunbird::World.new
    world.spawn(
      position: Sunbird::Component::Position.new(x: 2, y: 2),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )

    movement = Sunbird::Simulation::Movement.new
    refute movement.traversable?(level: level, world: world, x: 2, y: 2)
    assert movement.traversable?(level: level, world: world, x: 3, y: 2)
  end
end
