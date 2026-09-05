# frozen_string_literal: true

module Sunbird
  class World
    Relation = Data.define(:kind, :source_id, :target_id)

    class Relations
      def initialize
        @relations = []
      end

      def add(kind:, source_id:, target_id:)
        relation = Relation.new(
          kind: kind,
          source_id: source_id,
          target_id: target_id
        )

        @relations << relation unless @relations.include?(relation)
        relation
      end

      def targets(kind:, source_id:)
        @relations.filter_map do |relation|
          next unless relation.kind == kind
          next unless relation.source_id == source_id

          relation.target_id
        end.freeze
      end
    end
  end
end
