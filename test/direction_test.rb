# frozen_string_literal: true

require_relative "test_helper"

class DirectionTest < Minitest::Test
  def test_cardinal_directions_share_one_delta_definition
    assert_equal [0, -1], Sunbird::Direction.delta(:north)
    assert_equal [1, 0], Sunbird::Direction.delta(:east)
    assert_equal [0, 1], Sunbird::Direction.delta(:south)
    assert_equal [-1, 0], Sunbird::Direction.delta(:west)
  end

  def test_delta_can_be_resolved_back_to_direction
    assert_equal :north, Sunbird::Direction.for_delta(0, -1)
    assert_equal :east, Sunbird::Direction.for_delta(1, 0)
    assert_nil Sunbird::Direction.for_delta(1, 1)
  end
end
