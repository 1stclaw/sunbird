# frozen_string_literal: true

module Sunbird
  class TurnPlanner
    WANDER_DIRECTIONS = [
      [0, -1].freeze,
      [1, 0].freeze,
      [0, 1].freeze,
      [-1, 0].freeze
    ].freeze

    BEHAVIOR_HANDLERS = {
      idle: :idle_behavior,
      wander: :wander_behavior,
      chase: :chase
    }.freeze

    def initialize(pathfinder: Simulation::Pathfinder.new)
      @pathfinder = pathfinder
    end

    def build(input:, level:, world:, controlled_id:)
      commands = []

      world.entity_ids.each do |entity_id|
        command = if entity_id == controlled_id
          controlled_move(input, controlled_id)
        else
          behavior_command(level, world, entity_id)
        end

        commands << command if command
      end

      Simulation::Commands::Buffer.new(commands)
    end

    private

    def controlled_move(input, entity_id)
      dx = 0
      dy = 0
      dx -= 1 if input.pressed?(:move_west)
      dx += 1 if input.pressed?(:move_east)
      dy -= 1 if input.pressed?(:move_north)
      dy += 1 if input.pressed?(:move_south)
      return if dx.zero? && dy.zero?

      Simulation::Commands::Move.new(entity_id: entity_id, dx: dx, dy: dy)
    end

    def behavior_command(level, world, entity_id)
      behavior = world.component(entity_id, :behavior)
      return unless behavior

      handler = BEHAVIOR_HANDLERS.fetch(behavior.kind) do
        raise ArgumentError, "unknown behavior: #{behavior.kind.inspect}"
      end
      __send__(handler, level, world, entity_id)
    end

    def idle_behavior(_level, _world, _entity_id)
      nil
    end

    def wander_behavior(_level, _world, entity_id)
      dx, dy = WANDER_DIRECTIONS.sample
      Simulation::Commands::Move.new(entity_id: entity_id, dx: dx, dy: dy)
    end

    def chase(level, world, entity_id)
      target_id = world.relation_targets(
        kind: :targets,
        source_id: entity_id
      ).first
      return unless target_id

      if adjacent?(world, entity_id, target_id)
        combatant = world.component(entity_id, :combatant)
        return unless combatant&.attack&.positive?

        return Simulation::Commands::Attack.new(
          attacker_id: entity_id,
          target_id: target_id,
          damage: combatant.attack
        )
      end

      step = @pathfinder.next_step(
        level: level,
        world: world,
        source_id: entity_id,
        target_id: target_id
      )
      return unless step

      dx, dy = step
      Simulation::Commands::Move.new(entity_id: entity_id, dx: dx, dy: dy)
    end

    def adjacent?(world, source_id, target_id)
      source = world.component(source_id, :position)
      target = world.component(target_id, :position)
      return false unless source && target

      (source.x - target.x).abs + (source.y - target.y).abs == 1
    end
  end
end
