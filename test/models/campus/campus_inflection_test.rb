require "test_helper"

class CampusInflectionTest < ActiveSupport::TestCase
  test "pluralizes campus as campi" do
    assert_equal "campi", "campus".pluralize
    assert_equal "campus", "campi".singularize
  end

  test "uses the campi table" do
    assert_equal "campi", Campus.table_name
  end

  test "translates the model name" do
    assert_equal "Campus", Campus.model_name.human
    assert_equal "Campi", Campus.model_name.human(count: 2)
  end
end
