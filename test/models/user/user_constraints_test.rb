require "test_helper"

class UserConstraintsTest < ActiveSupport::TestCase
  test "accepts a user without department" do
    assert build(:user, department: nil).save(validate: false)
  end

  test "does not accept a nonexistent department" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      build(:user, department_id: Department.maximum(:id).to_i + 1).save(validate: false)
    end
  end
end
