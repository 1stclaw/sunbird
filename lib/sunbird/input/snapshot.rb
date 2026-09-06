# frozen_string_literal: true

module Sunbird
  module Input
    class Snapshot
      def self.from(actions)
        Tracker.new.snapshot(actions)
      end

      def self.empty
        new(
          held: {},
          pressed: {},
          released: {},
          states: {}
        )
      end

      def initialize(held:, pressed:, released:, states: {})
        @held = held.dup.freeze
        @pressed = pressed.dup.freeze
        @released = released.dup.freeze
        @states = states.dup.freeze
      end

      # Preserves the old per-snapshot state lookup while adding explicit
      # held/edge queries.
      def state(kind)
        @states[kind]
      end

      def held?(kind)
        @held.key?(kind)
      end

      def pressed?(kind)
        @pressed.key?(kind)
      end

      def released?(kind)
        @released.key?(kind)
      end
    end
  end
end
