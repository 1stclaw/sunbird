# frozen_string_literal: true

require_relative "test_helper"

class BattleModeTest < Minitest::Test
  include SunbirdTestSupport

  def setup
    level = level_with(
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :goblin,
          prototype: :goblin,
          x: 3,
          y: 2
        )
      ],
      entries: [default_entry(x: 2, y: 2, facing: :east)],
      default_entry: :start
    )

    @simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    @session = test_session
    @hero_id = @simulation.spawn_character(
      character_key: :hero,
      prototype: :player
    )
    @enemy_id = @simulation.entity_id_for_spawn(:goblin)
    @battle = Sunbird::Mode::Battle.new(
      simulation: @simulation,
      session: @session,
      player_key: :hero,
      enemy_id: @enemy_id
    )
  end

  def test_attack_uses_persistent_character_attack
    result = @battle.advance(input: action_input(:interact))

    assert_equal :advanced, result
    assert_equal 1, @battle.step_number
    assert_equal 2, enemy_health.current
    assert_equal 9, @session.character(:hero).hp
    assert_nil @battle.world_view.component(@hero_id, :health)
    assert_nil @battle.world_view.component(@hero_id, :combatant)
  end

  def test_winning_turn_pops_without_enemy_retaliation
    @battle.advance(input: action_input(:interact))
    result = @battle.advance(input: action_input(:interact))

    assert_equal :pop, result
    assert_equal 2, @battle.step_number
    assert_equal 0, enemy_health.current
    assert_equal 9, @session.character(:hero).hp
    assert_nil @battle.world_view.component(@enemy_id, :renderable)
    assert_nil @battle.world_view.component(@enemy_id, :collision)
    assert_nil @battle.world_view.component(@enemy_id, :behavior)
    assert_nil @battle.world_view.component(@enemy_id, :combatant)
  end

  def test_damage_persists_after_flee
    @battle.advance(input: action_input(:interact))
    @battle.advance(input: action_input(:cancel))

    assert_equal 9, @session.character(:hero).hp
  end

  def test_cancel_flees_without_new_damage_or_step
    result = @battle.advance(input: action_input(:cancel))

    assert_equal :pop, result
    assert_equal 0, @battle.step_number
    assert_equal 4, enemy_health.current
    assert_equal 10, @session.character(:hero).hp
  end

  def test_status_text_uses_persistent_character
    assert_match "Hero HP 10/10 MP 4/4", @battle.status_text
    assert_match "Goblin HP 4/4", @battle.status_text
  end

  private

  def enemy_health
    @battle.world_view.component(@enemy_id, :health)
  end
end
