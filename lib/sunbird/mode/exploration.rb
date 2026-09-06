# frozen_string_literal: true

module Sunbird
  module Mode
    class Exploration
      attr_reader :simulation, :session, :dialogues, :planner

      def initialize(simulation:, session:, dialogues:, planner: TurnPlanner.new)
        @simulation = simulation
        @session = session
        @dialogues = dialogues
        @planner = planner
      end

      def advance(input:)
        return :quit if input.pressed?(:quit)
        return :quit if input.pressed?(:cancel)

        if input.pressed?(:interact)
          return interaction_transition || :idle
        end

        commands = planner.build(
          input: input,
          level: level,
          world: world_view,
          controlled_id: controlled_entity_id
        )
        result = simulation.step(commands: commands)
        session.apply_effects(result.effects)
        :advanced
      end

      def level = simulation.level
      def world_view = simulation.world_view
      def step_number = simulation.step_number

      def controlled_entity_id
        simulation.entity_id_for_character(session.party.leader)
      end

      def entity_id_for_party_member(member)
        simulation.entity_id_for_character(member)
      rescue KeyError
        nil
      end

      def status_text
        leader = session.party.leader
        character = session.character(leader)

        "#{leader.to_s.capitalize} "           "HP #{character.hp}/#{character.max_hp} "           "MP #{character.mp}/#{character.max_mp} | "           "WASD/arrows move. Enter/Space interact. "           "Q or Esc quit. Step #{step_number}"
      end

      private

      def interaction_transition
        target_id = adjacent_target_id
        return unless target_id

        interactable = world_view.component(target_id, :interactable)
        return dialogue_transition(interactable) if interactable

        combatant = world_view.component(target_id, :combatant)
        return battle_transition(target_id) if combatant

        nil
      end

      def dialogue_transition(interactable)
        Push.new(
          mode: Dialogue.new(
            simulation: simulation,
            lines: dialogues.fetch(interactable.dialogue_key)
          )
        )
      end

      def battle_transition(target_id)
        Push.new(
          mode: Battle.new(
            simulation: simulation,
            session: session,
            player_key: session.party.leader,
            enemy_id: target_id
          )
        )
      end

      def adjacent_target_id
        origin = world_view.component(controlled_entity_id, :position)
        facing = world_view.component(controlled_entity_id, :facing)
        return unless origin && facing

        offset = Direction.delta(facing.direction)
        return unless offset

        target_x = origin.x + offset[0]
        target_y = origin.y + offset[1]

        world_view.entity_ids.find do |entity_id|
          next if entity_id == controlled_entity_id

          position = world_view.component(entity_id, :position)
          position && position.x == target_x && position.y == target_y
        end
      end
    end
  end
end
