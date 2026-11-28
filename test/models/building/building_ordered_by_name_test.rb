require "test_helper"

class BuildingOrderedByNameTest < ActiveSupport::TestCase
  test "orders the buildings of a campus by name" do
    campus = create(:campus)
    [ "Bloco R", "Bloco B", "Bloco C" ].each { |name| create(:building, campus: campus, name: name) }
    create(:building, name: "Bloco A")

    assert_equal [ "Bloco B", "Bloco C", "Bloco R" ], campus.buildings.ordered_by_name.map(&:name)
  end
end
