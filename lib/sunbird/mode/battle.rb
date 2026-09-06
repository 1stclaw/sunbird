# frozen_string_literal: true

module Sunbird
  module Mode
    class Battle
      attr_reader :simulation, :session, :player_key, :enemy_id

      def initialize(simulation:, session:, player_key:, enemy_id:)
        @simulation = simulation
        @session = session
        @player_key = player_key.to_sym
        @enemy_id = enemy_id
        validate_player!
        validate_enemy!
      end

      def advance(input:)
        return :quit if input.pressed?(:quit)
        return :pop if input.pressed?(:cancel)
        return :quit if player_defeated?
        return :pop if enemy_defeated?
        return :waiting unless input.pressed?(:interact)

        result = simulation.step(
          commands: Simulation::Commands::Buffer.new(turn_commands)
        )
        session.apply_effects(result.effects)

        return :quit if player_defeated?
        return :pop if enemy_defeated?
        :advanced
      end

      def level = simulation.level
      def world_view = simulation.world_view
      def step_number = simulation.step_number

      def status_text
        player = player_character
        "#{player_key.to_s.capitalize} "           "HP #{player.hp}/#{player.max_hp} "           "MP #{player.mp}/#{player.max_mp} | "           "#{display_name(enemy_id)} HP #{enemy_health_text} | "           "Enter/Space attack | Esc flee"
      end

      private

      def player_character = session.character(player_key)
      def player_id = simulation.entity_id_for_character(player_key)

      def turn_commands
        player_damage = player_character.attack
        enemy = enemy_health
        commands = [
          Simulation::Commands::Attack.new(
            attacker_id: player_id,
            target_id: enemy_id,
            damage: player_damage
          )
        ]

        if player_damage >= enemy.current
          commands << Simulation::Commands::Defeat.new(entity_id: enemy_id)
        else
          commands << Simulation::Commands::Attack.new(
            attacker_id: enemy_id,
            target_id: player_id,
            damage: local_combatant(enemy_id).attack
          )
        end
        commands
      end

      def enemy_health = world_view.component(enemy_id, :health)
      def local_combatant(entity_id) = world_view.component(entity_id, :combatant)
      def player_defeated? = player_character.hp.zero?
      def enemy_defeated? = enemy_health&.current&.zero?

      def enemy_health_text
        value = enemy_health
        value ? "#{value.current}/#{value.max}" : "?/?"
      end

      def display_name(entity_id)
        ref = world_view.component(entity_id, :prototype_ref)
        (ref&.name || :unknown).to_s.capitalize
      end

      def validate_player!
        player_character
        player_id
      rescue KeyError
        raise ArgumentError, "unbound persistent character: #{player_key.inspect}"
      end

      def validate_enemy!
        unless enemy_health && local_combatant(enemy_id)
          raise ArgumentError, "battle enemy is not a local combatant: #{enemy_id.inspect}"
        end
      end
    end
  end
end
