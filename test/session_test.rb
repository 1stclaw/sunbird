# frozen_string_literal: true

require_relative "test_helper"

class SessionTest < Minitest::Test
  include SunbirdTestSupport

  def test_session_owns_persistent_characters
    session = test_session

    assert_equal [:hero, :mage], session.party.members
    assert_equal [:hero, :mage], session.character_keys
    assert_equal 10, session.character(:hero).hp
    assert_equal 4, session.character(:hero).mp
    assert_equal 2, session.character(:hero).attack
  end

  def test_session_can_exist_without_party_policy
    character = Sunbird::Character.new(
      hp: 10, max_hp: 10,
      mp: 0, max_mp: 0,
      attack: 2
    )

    session = Sunbird::Session.new(
      characters: { player: character }
    )

    assert_nil session.party
    assert_equal character, session.character(:player)
  end

  def test_damage_and_healing_replace_character
    session = test_session
    original = session.character(:hero)

    damaged = session.damage_character(:hero, 3)
    refute_same original, session.character(:hero)
    assert_equal 7, damaged.hp

    healed = session.heal_character(:hero, 99)
    assert_equal 10, healed.hp
  end

  def test_mp_spending_and_restoration
    session = test_session

    assert session.spend_mp(:hero, 3)
    assert_equal 1, session.character(:hero).mp

    refute session.spend_mp(:hero, 2)
    assert_equal 1, session.character(:hero).mp

    session.restore_mp(:hero, 99)
    assert_equal 4, session.character(:hero).mp
  end

  def test_party_members_require_characters
    party = Sunbird::Party.new(
      members: [:hero, :mage],
      leader: :hero
    )
    hero = Sunbird::Character.new(
      hp: 10, max_hp: 10,
      mp: 4, max_mp: 4,
      attack: 2
    )

    error = assert_raises(ArgumentError) do
      Sunbird::Session.new(
        party: party,
        characters: { hero: hero }
      )
    end

    assert_match "missing characters", error.message
  end

  def test_effect_batch_is_validated_before_mutation
    session = test_session
    effects = [
      Sunbird::Effect::DamageCharacter.new(
        character_key: :hero,
        amount: 2
      ),
      Sunbird::Effect::DamageCharacter.new(
        character_key: :unknown,
        amount: 1
      )
    ]

    assert_raises(KeyError) { session.apply_effects(effects) }
    assert_equal 10, session.character(:hero).hp
  end
end
