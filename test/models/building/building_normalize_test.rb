require "test_helper"

class BuildingNormalizeTest < ActiveSupport::TestCase
  setup do
    @building = build(:building, name: "  Bloco   A  ")
  end

  test "should squish name" do
    @building.save
    assert_equal "Bloco A", @building.name
  end
end
