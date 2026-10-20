require "test_helper"

class CampusNormalizeTest < ActiveSupport::TestCase
  test "squishes the name" do
    assert_equal "Pato Branco", build(:campus, name: "  Pato   Branco ").name
  end

  test "keeps the letter case and accents typed" do
    assert_equal "CAMPO Mourão", create(:campus, name: "CAMPO Mourão").reload.name
  end
end
