# frozen_string_literal: true

require_relative "test_helper"

class PrototypeLoadingTest < Minitest::Test
  include SunbirdTestPaths

  def test_loader_returns_prototype_catalog
    prototypes = Sunbird::Prototype::Loader.load(PROTOTYPE_PATH)

    assert_instance_of Sunbird::Prototype::Catalog, prototypes
    assert prototypes.include?(:player)
    assert prototypes.include?(:goblin)
    assert prototypes.include?(:villager)
  end
end
