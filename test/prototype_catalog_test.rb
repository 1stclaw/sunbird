# frozen_string_literal: true

require_relative "test_helper"

class PrototypeCatalogTest < Minitest::Test
  def test_duplicate_prototype_names_are_rejected
    first = Sunbird::Prototype.new(name: :goblin, components: {}.freeze)
    second = Sunbird::Prototype.new(name: :goblin, components: {}.freeze)

    error = assert_raises(ArgumentError) do
      Sunbird::Prototype::Catalog.new([first, second])
    end

    assert_match "duplicate prototype", error.message
  end
end
