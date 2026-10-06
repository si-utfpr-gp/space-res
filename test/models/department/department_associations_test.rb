require "test_helper"

class DepartmentAssociationsTest < ActiveSupport::TestCase
  subject { create(:department) }

  should have_many(:users).dependent(:restrict_with_error)

  context "department with users" do
    setup do
      @department = create(:department)
      create(:user, department: @department)
    end

    should "not be destroyed" do
      assert_not @department.destroy
      assert Department.exists?(@department.id)
      assert_includes @department.errors[:base], "Não é possível excluir o registro pois existem usuários dependentes"
    end
  end

  context "department without users" do
    should "be destroyed" do
      department = create(:department)

      assert department.destroy
      assert_not Department.exists?(department.id)
    end
  end
end
