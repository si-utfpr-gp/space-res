require "test_helper"

class DepartmentNormalizeTest < ActiveSupport::TestCase
  setup do
    @department = build(:department, name: "  Departamento   Acadêmico de Engenharia  ")
  end

  test "should squish name" do
    @department.save
    assert_equal "Departamento Acadêmico de Engenharia", @department.name
  end
end
