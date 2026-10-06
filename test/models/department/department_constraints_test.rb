require "test_helper"

class DepartmentConstraintsTest < ActiveSupport::TestCase
  test "does not accept a duplicated name" do
    department = create(:department)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:department, name: department.name).save(validate: false)
    end
  end

  test "does not accept a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:department, name: nil).save(validate: false)
    end
  end
end
