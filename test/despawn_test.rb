# frozen_string_literal: true

require_relative "test_helper"

class DespawnTest < Minitest::Test
  include SunbirdTestSupport

  def test_executor_can_despawn_unbound_local_entity
    level = level_with(
      spawns: [
        Sunbird::Level::Spawn.new(
          key: :temporary,
          prototype: :goblin,
          x: 3,
          y: 2
        )
      ]
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    entity_id = simulation.entity_id_for_spawn(:temporary)

    result = simulation.step(
      commands: Sunbird::Simulation::Commands::Buffer.new(
        [Sunbird::Simulation::Commands::Despawn.new(entity_id: entity_id)]
      )
    )

    refute simulation.world_view.entity?(entity_id)
    refute_includes simulation.world_view.entity_ids, entity_id
    assert_empty result.effects
  end

  def test_executor_refuses_to_despawn_bound_character_entity
    level = level_with(
      spawns: [],
      entries: [default_entry],
      default_entry: :start
    )
    simulation = Sunbird::Simulation.new(
      level: level,
      prototypes: prototype_catalog
    )
    hero_id = simulation.spawn_character(
      character_key: :hero,
      prototype: :player
    )

    error = assert_raises(ArgumentError) do
      simulation.step(
        commands: Sunbird::Simulation::Commands::Buffer.new(
          [Sunbird::Simulation::Commands::Despawn.new(entity_id: hero_id)]
        )
      )
    end

    assert_match "bound character", error.message
    assert simulation.world_view.entity?(hero_id)
    assert_equal hero_id, simulation.entity_id_for_character(:hero)
  end
end
