require "test_helper"

class UserOrderedByNameTest < ActiveSupport::TestCase
  test "orders by name" do
    [ "Carla Souza", "Ana Lima", "Bruno Costa" ].each { |name| create(:user, name: name) }

    assert_equal [ "Ana Lima", "Bruno Costa", "Carla Souza" ], User.ordered_by_name.map(&:name)
  end
end
