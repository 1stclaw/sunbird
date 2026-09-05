# frozen_string_literal: true

module Sunbird
  class World
    def initialize
      @next_entity_id = 0
      @component_tables = {}
      @relations = Relations.new
    end

    def spawn(**components)
      entity_id = @next_entity_id
      @next_entity_id += 1

      components.each do |name, component|
        set_component(entity_id, name, component)
      end

      entity_id
    end

    def entity?(entity_id)
      entity_id.is_a?(Integer) &&
        entity_id >= 0 &&
        entity_id < @next_entity_id
    end

    def entity_ids
      (0...@next_entity_id).to_a.freeze
    end

    def component(entity_id, name)
      validate_entity!(entity_id)
      @component_tables[name]&.[](entity_id)
    end

    def set_component(entity_id, name, component)
      validate_entity!(entity_id)
      table_for(name)[entity_id] = component
    end

    def remove_component(entity_id, name)
      validate_entity!(entity_id)
      @component_tables[name]&.delete(entity_id)
    end

    def add_relation(kind:, source_id:, target_id:)
      validate_entity!(source_id)
      validate_entity!(target_id)

      @relations.add(kind: kind, source_id: source_id, target_id: target_id)
    end

    def relation_targets(kind:, source_id:)
      validate_entity!(source_id)
      @relations.targets(kind: kind, source_id: source_id)
    end

    def view
      View.new(self)
    end

    private

    def table_for(name)
      @component_tables[name] ||= ComponentTable.new
    end

    def validate_entity!(entity_id)
      return if entity?(entity_id)

      raise ArgumentError, "unknown entity_id: #{entity_id.inspect}"
    end
  end
end
