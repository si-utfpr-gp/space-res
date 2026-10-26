require "test_helper"

class BuildingAssociationsTest < ActiveSupport::TestCase
  subject { build(:building) }

  should belong_to(:campus)

  test "translates the model name" do
    assert_equal "Bloco", Building.model_name.human
    assert_equal "Blocos", Building.model_name.human(count: 2)
  end
end
