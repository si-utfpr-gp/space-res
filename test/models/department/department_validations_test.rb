require "test_helper"

class DepartmentValidationsTest < ActiveSupport::TestCase
  subject { @department }
  setup do
    @department = create(:department, name: "Departamento de Educação")
  end

  should validate_presence_of(:name).with_message("Informe o nome do departamento.")
  should validate_uniqueness_of(:name).case_insensitive.with_message("Já existe um departamento cadastrado com este nome.")

  test "rejects a name with only spaces" do
    department = build(:department, name: "   ")

    assert_not department.valid?
    assert_includes department.errors[:name], "Informe o nome do departamento."
  end

  test "rejects a taken name in upper case with accents" do
    assert_name_taken build(:department, name: "DEPARTAMENTO DE EDUCAÇÃO")
  end

  test "rejects a taken name without accents and cedilla" do
    assert_name_taken build(:department, name: "Departamento de Educacao")
  end

  test "rejects a taken name written without spaces" do
    assert_name_taken build(:department, name: "departamentodeeducacao")
  end

  test "rejects a taken name with punctuation" do
    assert_name_taken build(:department, name: "Departamento-de-Educação.")
  end

  test "lets a department change the letter case and accents of its own name" do
    assert @department.update(name: "DEPARTAMENTO DE EDUCACAO")
  end

  test "rejects renaming a department to the name of another department" do
    department = create(:department, name: "Departamento de Extensão")

    assert_not department.update(name: "departamento de educacao")
    assert_includes department.errors[:name], "Já existe um departamento cadastrado com este nome."
  end

  private

    def assert_name_taken(department)
      assert_not department.valid?
      assert_includes department.errors[:name], "Já existe um departamento cadastrado com este nome."
    end
end
