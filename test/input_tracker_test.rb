# frozen_string_literal: true

require_relative "test_helper"

class InputTrackerTest < Minitest::Test
  def test_press_is_edge_and_held_state_persists
    tracker = Sunbird::Input::Tracker.new
    press = Sunbird::Input::Action.new(
      kind: :move_east,
      state: :pressed
    )

    first = tracker.snapshot([press])
    second = tracker.snapshot

    assert first.pressed?(:move_east)
    assert first.held?(:move_east)
    assert_equal :pressed, first.state(:move_east)
    refute second.pressed?(:move_east)
    assert second.held?(:move_east)
    assert_nil second.state(:move_east)
  end

  def test_release_clears_held_state
    tracker = Sunbird::Input::Tracker.new
    tracker.snapshot([
      Sunbird::Input::Action.new(
        kind: :move_east,
        state: :pressed
      )
    ])

    released = tracker.snapshot([
      Sunbird::Input::Action.new(
        kind: :move_east,
        state: :released
      )
    ])

    assert released.released?(:move_east)
    assert_equal :released, released.state(:move_east)
    refute released.held?(:move_east)
    refute tracker.snapshot.held?(:move_east)
  end

  def test_repeat_keeps_key_held_without_press_edge
    tracker = Sunbird::Input::Tracker.new

    repeated = tracker.snapshot([
      Sunbird::Input::Action.new(
        kind: :move_east,
        state: :repeat
      )
    ])

    assert repeated.held?(:move_east)
    refute repeated.pressed?(:move_east)
    assert_equal :repeat, repeated.state(:move_east)
  end

  def test_unknown_state_is_rejected
    tracker = Sunbird::Input::Tracker.new
    action = Sunbird::Input::Action.new(
      kind: :move_east,
      state: :unknown
    )

    assert_raises(ArgumentError) do
      tracker.snapshot([action])
    end
  end
end
