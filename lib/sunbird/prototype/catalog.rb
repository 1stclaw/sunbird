# frozen_string_literal: true

module Sunbird
  class Prototype
    class Catalog
      def initialize(prototypes)
        @prototypes = prototypes.to_h do |prototype|
          [prototype.name, prototype]
        end.freeze
      end

      def fetch(name)
        @prototypes.fetch(name)
      end

      def include?(name)
        @prototypes.key?(name)
      end

      def names
        @prototypes.keys.freeze
      end
    end

    module Definitions
    end
  end
end
