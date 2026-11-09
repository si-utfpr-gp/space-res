require "test_helper"

class DepartmentAssociationsTest < ActiveSupport::TestCase
  subject { create(:department) }

  should have_many(:users).dependent(:restrict_with_error)

  test "refuses to delete a department that has users and explains why" do
    department = create(:department)
    create(:user, department: department)

    assert_not department.destroy
    assert Department.exists?(department.id)
    assert_equal [ "Não é possível excluir o departamento porque ele tem usuários vinculados." ],
                 department.errors.full_messages
  end

  test "deletes a department without users" do
    department = create(:department)

    assert department.destroy
    assert_not Department.exists?(department.id)
  end
end
