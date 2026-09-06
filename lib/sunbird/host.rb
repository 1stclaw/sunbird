# frozen_string_literal: true

module Sunbird
  module Host
    Capabilities = Data.define(
      :graphics_protocol,
      :keyboard_protocol
    )

    KeyEvent = Data.define(
      :key,
      :state
    )
  end
end
