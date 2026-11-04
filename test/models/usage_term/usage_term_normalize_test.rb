require "test_helper"

class UsageTermNormalizeTest < ActiveSupport::TestCase
  test "squishes the title" do
    assert_equal "Termo do Laboratório", build(:usage_term, title: "  Termo   do Laboratório ").title
  end

  test "keeps the letter case and accents typed in the title" do
    assert_equal "TERMO do Laboratório", create(:usage_term, title: "TERMO do Laboratório").reload.title
  end
end
