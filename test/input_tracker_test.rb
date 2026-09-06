# frozen_string_literal: true

require_relative "test_helper"

class InputTrackerTest < Minitest::Test
  def test_press_is_edge_and_held_state_persists_across_ticks
    tracker = Sunbird::Input::Tracker.new
    press = Sunbird::Input::Action.new(
      kind: :move_east,
      state: :pressed
    )

    first = tracker.snapshot([press])
    second = tracker.snapshot

    assert first.pressed?(:move_east)
    assert first.held?(:move_east)
    refute second.pressed?(:move_east)
    assert second.held?(:move_east)
  end

  def test_release_clears_held_state
    tracker = Sunbird::Input::Tracker.new
    tracker.snapshot([
      Sunbird::Input::Action.new(kind: :move_east, state: :pressed)
    ])

    released = tracker.snapshot([
      Sunbird::Input::Action.new(kind: :move_east, state: :released)
    ])

    assert released.released?(:move_east)
    refute released.held?(:move_east)
    refute tracker.snapshot.held?(:move_east)
  end

  def test_repeat_keeps_key_held_without_creating_a_press_edge
    tracker = Sunbird::Input::Tracker.new

    repeated = tracker.snapshot([
      Sunbird::Input::Action.new(kind: :move_east, state: :repeat)
    ])

    assert repeated.held?(:move_east)
    refute repeated.pressed?(:move_east)
  end
end
