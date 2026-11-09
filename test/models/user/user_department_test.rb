require "test_helper"

class UserDepartmentTest < ActiveSupport::TestCase
  subject { build(:user) }

  should belong_to(:department).optional

  test "accepts a user without a department" do
    assert build(:user, department: nil).valid?
  end

  test "accepts an existing department" do
    assert build(:user, department: create(:department)).valid?
  end

  test "rejects a department that does not exist" do
    user = build(:user, department_id: 0)

    assert_not user.valid?
    assert_equal [ "Selecione um departamento cadastrado." ], user.errors[:department]
  end

  test "does not look up the department again when it did not change" do
    user = create(:user, :with_department)
    user.reload

    assert_no_queries_match(/FROM "departments"/) { user.update!(name: "Outro Nome") }
  end
end
