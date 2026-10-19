require "test_helper"

class CampusValidationsTest < ActiveSupport::TestCase
  test "requires a name" do
    campus = build(:campus, name: "")

    assert_not campus.valid?
    assert_includes campus.errors[:name], "Informe o nome do campus."
  end

  test "rejects a name with only spaces" do
    campus = build(:campus, name: "   ")

    assert_not campus.valid?
    assert_includes campus.errors[:name], "Informe o nome do campus."
  end

  test "rejects a name already taken" do
    create(:campus, name: "Guarapuava")

    assert_name_taken build(:campus, name: "Guarapuava")
  end

  test "rejects a taken name with different letter case" do
    create(:campus, name: "Guarapuava")

    assert_name_taken build(:campus, name: "guarapuava")
  end

  test "rejects a taken name with different case in accented letters" do
    create(:campus, name: "Campo Mourão")

    assert_name_taken build(:campus, name: "CAMPO MOURÃO")
  end

  test "rejects a taken name without accents" do
    create(:campus, name: "Campo Mourão")

    assert_name_taken build(:campus, name: "Campo Mourao")
  end

  test "rejects a taken name without cedilla" do
    create(:campus, name: "Foz do Iguaçu")

    assert_name_taken build(:campus, name: "Foz do Iguacu")
  end

  test "rejects a taken name written without spaces" do
    create(:campus, name: "Campo Mourão")

    assert_name_taken build(:campus, name: "campomourao")
  end

  test "rejects a taken name with punctuation" do
    create(:campus, name: "Campo Mourão")

    assert_name_taken build(:campus, name: "Campo-Mourão.")
  end

  test "rejects a taken name with extra spaces" do
    create(:campus, name: "Pato Branco")

    assert_name_taken build(:campus, name: "  pato   branco ")
  end

  test "accepts a different name" do
    create(:campus, name: "Pato Branco")

    assert build(:campus, name: "Ponta Grossa").valid?
  end

  test "lets a campus change the letter case and accents of its own name" do
    campus = create(:campus, name: "campo mourao")

    assert campus.update(name: "Campo Mourão")
  end

  test "rejects renaming a campus to the name of another campus" do
    create(:campus, name: "Guarapuava")
    campus = create(:campus, name: "Pato Branco")

    assert_not campus.update(name: "GUARAPUAVA")
    assert_includes campus.errors[:name], "Já existe um campus cadastrado com este nome."
  end

  private

    def assert_name_taken(campus)
      assert_not campus.valid?
      assert_includes campus.errors[:name], "Já existe um campus cadastrado com este nome."
    end
end
