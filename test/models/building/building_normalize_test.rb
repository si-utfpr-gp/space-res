require "test_helper"

class BuildingNormalizeTest < ActiveSupport::TestCase
  test "squishes the name" do
    assert_equal "Bloco R", build(:building, name: "  Bloco   R ").name
  end

  test "keeps the letter case and accents typed" do
    assert_equal "BLOCO Química", create(:building, name: "BLOCO Química").reload.name
  end
end
