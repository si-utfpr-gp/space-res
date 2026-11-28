require "test_helper"

class CampusOrderedByNameTest < ActiveSupport::TestCase
  test "orders by name" do
    [ "Pato Branco", "Guarapuava", "Toledo" ].each { |name| create(:campus, name: name) }

    assert_equal [ "Guarapuava", "Pato Branco", "Toledo" ], Campus.ordered_by_name.map(&:name)
  end
end
