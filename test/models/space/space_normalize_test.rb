require "test_helper"

class SpaceNormalizeTest < ActiveSupport::TestCase
  test "squishes the name" do
    assert_equal "Sala 101", build(:space, name: "  Sala   101 ").name
  end

  test "squishes the unavailability reason and turns a blank one into nothing" do
    assert_equal "Sala em reforma", build(:space, unavailability_reason: "  Sala   em reforma ").unavailability_reason
    assert_nil build(:space, unavailability_reason: "   ").unavailability_reason
  end

  test "keeps the letter case and accents typed" do
    assert_equal "LABORATÓRIO de Química", create(:space, name: "LABORATÓRIO de Química").reload.name
  end
end
