# frozen_string_literal: true

require_relative "test_helper"

class PathfinderTest < Minitest::Test
  def test_finds_step_around_blocked_terrain
    level = Sunbird::Level.new(
      name: :test,
      terrain: Sunbird::Level::Terrain.new(width: 5, height: 5),
      spawns: [],
      relations: []
    )
    world = Sunbird::World.new
    source = world.spawn(
      position: Sunbird::Component::Position.new(x: 1, y: 2),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )
    world.spawn(
      position: Sunbird::Component::Position.new(x: 2, y: 2),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )
    target = world.spawn(
      position: Sunbird::Component::Position.new(x: 3, y: 2),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )

    step = Sunbird::Simulation::Pathfinder.new.next_step(
      level: level, world: world,
      source_id: source, target_id: target
    )

    assert_includes [[0, -1], [0, 1]], step
  end

  def test_returns_nil_when_source_is_already_adjacent
    level = Sunbird::Level.new(
      name: :test,
      terrain: Sunbird::Level::Terrain.new(width: 5, height: 5),
      spawns: [],
      relations: []
    )
    world = Sunbird::World.new
    source = world.spawn(
      position: Sunbird::Component::Position.new(x: 1, y: 1),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )
    target = world.spawn(
      position: Sunbird::Component::Position.new(x: 2, y: 1),
      collision: Sunbird::Component::Collision.new(blocks_movement: true)
    )

    assert_nil Sunbird::Simulation::Pathfinder.new.next_step(
      level: level, world: world,
      source_id: source, target_id: target
    )
  end
end
