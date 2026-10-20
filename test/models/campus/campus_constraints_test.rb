require "test_helper"

class CampusConstraintsTest < ActiveSupport::TestCase
  test "database rejects a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:campus, name: nil).save!(validate: false)
    end
  end

  test "database rejects a repeated name" do
    create(:campus, name: "Guarapuava")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:campus, name: "Guarapuava").save!(validate: false)
    end
  end
end
