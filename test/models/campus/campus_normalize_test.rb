require "test_helper"

class CampusNormalizeTest < ActiveSupport::TestCase
  setup do
    @campus = build(:campus, name: "  Câmpus   Guarapuava  ")
  end

  test "should squish name" do
    @campus.save
    assert_equal "Câmpus Guarapuava", @campus.name
  end
end
