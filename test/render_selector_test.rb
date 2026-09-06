# frozen_string_literal: true

require_relative "test_helper"

class RenderSelectorTest < Minitest::Test
  def test_builds_kitty_renderer_when_capability_is_present
    renderer = Sunbird::Render::Selector.build(
      capabilities: Sunbird::Host::Capabilities.new(
        graphics_protocol: :kitty,
        keyboard_protocol: :legacy
      )
    )

    assert_instance_of Sunbird::Render::Kitty, renderer
  end

  def test_rejects_terminal_without_kitty_graphics
    error = assert_raises(
      Sunbird::Render::Selector::UnsupportedTerminal
    ) do
      Sunbird::Render::Selector.build(
        capabilities: Sunbird::Host::Capabilities.new(
          graphics_protocol: nil,
          keyboard_protocol: :legacy
        )
      )
    end

    assert_equal(
      "Sunbird v#{Sunbird::VERSION} requires Kitty graphics protocol support",
      error.message
    )
  end
end
