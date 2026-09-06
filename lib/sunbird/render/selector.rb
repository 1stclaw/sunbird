# frozen_string_literal: true

module Sunbird
  module Render
    class Selector
      class UnsupportedTerminal < StandardError; end

      REQUIRED_PROTOCOL = :kitty
      ERROR_MESSAGE =
        "Sunbird v#{Sunbird::VERSION} requires Kitty graphics protocol support"

      def self.build(capabilities:, assets: nil)
        unless capabilities.graphics_protocol == REQUIRED_PROTOCOL
          raise UnsupportedTerminal, ERROR_MESSAGE
        end

        Kitty.new(
          assets: assets || AssetCatalog.default
        )
      end
    end
  end
end
