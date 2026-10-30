require "test_helper"

class DepartmentConstraintsTest < ActiveSupport::TestCase
  test "database rejects a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:department, name: nil).save!(validate: false)
    end
  end

  test "database rejects a repeated name" do
    create(:department, name: "Biblioteca")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:department, name: "Biblioteca").save!(validate: false)
    end
  end
end
