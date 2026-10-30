require "test_helper"

class DepartmentNormalizeTest < ActiveSupport::TestCase
  test "squishes the name" do
    assert_equal "Departamento de Educação", build(:department, name: "  Departamento   de Educação ").name
  end

  test "keeps the letter case and accents typed" do
    assert_equal "DEPARTAMENTO de Educação", create(:department, name: "DEPARTAMENTO de Educação").reload.name
  end
end
