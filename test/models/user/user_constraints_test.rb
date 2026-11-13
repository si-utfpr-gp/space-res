require "test_helper"

class UserConstraintsTest < ActiveSupport::TestCase
  test "database rejects a department that does not exist" do
    user = create(:user)

    assert_raises(ActiveRecord::InvalidForeignKey) do
      user.update_column(:department_id, 0)
    end
  end

  test "database rejects deleting a department that has users" do
    department = create(:department)
    create(:user, department: department)

    assert_raises(ActiveRecord::InvalidForeignKey) do
      department.delete
    end
  end
end
