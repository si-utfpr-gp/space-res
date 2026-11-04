require "test_helper"

class UsageTermConstraintsTest < ActiveSupport::TestCase
  test "database rejects a null title" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:usage_term, title: nil).save!(validate: false)
    end
  end

  test "database rejects a title repeated in another letter case" do
    create(:usage_term, title: "Termo do Laboratório")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:usage_term, title: "termo do laboratório").save!(validate: false)
    end
  end
end
